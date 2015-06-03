#!/usr/bin/env ruby
require 'net/ssh'
require 'fileutils'

module CucuShift
  class SSH
    include Common::Helper

    attr_reader :session

    # @return [exit_status, output]
    def self.exec(host, cmd, opts={})
      ssh = self.new(host, opts)
      return ssh.exec(cmd)
    rescue => e
      # seems like connection initialization failed
      return { success: false,
               instruction: "ssh #{opts[:user]}@#{host}",
               error: e,
               response: exception_to_string(e)
      }
    ensure
      ssh.close if defined?(ssh) and ssh
    end

    def initialize(host, opts={})
      @host = host
      @user = opts[:user] # can be nil for default username
      if opts[:private_key]
        logger.debug("SSH Authenticating with publickey method")
        private_key = File.expand_path(opts[:private_key])
        @session = Net::SSH.start(host, @user, :keys => [private_key], :auth_methods => ["publickey"])
      elsif opts[:password]
        logger.debug("SSH Authenticating with password method")
        @session = Net::SSH.start(host, @user, :password => opts[:password], :auth_methods => ["password"])
      else
        logger.error("Please provide password or key for ssh authentication")
        raise Net::SSH::AuthenticationFailed
      end
    end

    def close
      @session.close unless closed?
    end

    def closed?
      return @session.closed?
    end

    def active?
      return @session && ! @session.closed? && exec("echo")[:success]
    end

    # @param [String] local the local filename to upload
    # @param [String] remote the directory, where to upload
    # @param [String] hostname the host where to upload
    # @param [String] username
    # @param [String] password
    #
    def scp_to(local, remote)
      begin
        puts @session.exec!("mkdir -p #{remote} || echo ERROR")
        @session.scp.upload!(local, remote, :recursive=>true)
      rescue Net::SCP::Error
        logger.error("SCP failed!")
      end
    end

    # @param [String] remote the absolute path to be copied from
    # @param [String] local directory
    # @param [String] hostname the host where to upload from
    # @param [String] username
    # @param [String] password
    #
    def scp_from(remote, local)
      begin
        FileUtils.mkdir_p local
        @session.scp.download!(remote, local, :recursive=>true)
      rescue Net::SCP::Error
        logger.error("SCP failed!")
      end
    end

    def exec(command, opts={})
      # we want to have a handle over the result in case of error occurring
      # so that we catch any intermediate data for better reporting
      if opts[:result]
        res = opts[:result]
      else
        res = opts[:result] = {}
      end

      # now actually execute the ssh call
      begin
        exec_raw(command, opts)
      rescue => e
        res[:success] = false
        res[:error] = e
        res[:response] = exception_to_string
      end
      if res[:stdout].equal? res[:stderr]
        output = res[:stdout]
      else
        output = "STDOUT:\n#{res[:stdout]}\nSTDERR:\n#{res[:stderr]}"
      end
      if res[:response]
        # i.e. an error was raised durig the call
        res[:response] = "#{output}\n#{res[:response]}"
      end

      unless res.has_key? :success
        res[:success] = res[:exitstatus] == 0 && ! res[:exitsignal]
      end
    end

    # TODO: use shell service for greater flexibility and interactive commands
    #       http://net-ssh.github.io/ssh/v1/chapter-5.html
    def exec_raw(command, opts={})
      res = opts[:result] || {}
      res[:command] = command
      instruction = 'Remote cmd: `#{command}` @ssh://' +
                    @user ? "#{@user}@" : @host
      logger.info(instruction)
      res[:instruction] = instruction
      exit_status = nil
      stdout = res[:stdout] = opts[:stdout] || String.new
      stderr = res[:stderr] = opts[:stderr] || output
      exit_signal = nil
      @session.open_channel do |channel|
        channel.exec(command) do |ch, success|
          unless success
            res[:success] = false
            logger.error("could not execute command in ssh channel")
            abort
          end

          channel.on_data do |ch,data|
            stdout << data
          end

          channel.on_extended_data do |ch,type,data|
            stderr << data
          end

          channel.on_request("exit-status") do |ch,data|
            exit_status = data.read_long
          end

          channel.on_request("exit-signal") do |ch, data|
            exit_signal = data.read_long
          end

          if opts[:stdin]
            channel.send_data opts[:stdin].to_s
          end
          channel.eof!
        end
      end
      # on nil or 0 it would mean no timeout (wait forever)
      Timeout::timeout(opts[:timeout]) {
        @session.loop
      }
      logger.print(output, false)
      logger.info("Exit Status: #{exit_status}")
      return res.merge({ exitstatus: exit_status, exitsignal: exit_signal })
    end
  end
end
