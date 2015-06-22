#!/usr/bin/env ruby
require 'net/ssh'
require 'fileutils'

module CucuShift
  class SSH
    include Common::Helper

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

    # @param [String] host the hostname to establish ssh connection
    # @param [Hash] opts other options
    # @note if no password and no private key are specified, we assume
    #   ssh is pre-configured to gain access
    def initialize(host, opts={})
      @host = host
      raise "ssh host is mandatory" unless host && !host.empty?

      @user = opts[:user] # can be nil for default username
      conn_opts = {}
      if opts[:private_key]
        logger.debug("SSH Authenticating with publickey method")
        # TODO: make private key lookup more powerful and flexible
        private_key = expand_private_key(opts[:private_key])
        conn_opts[:keys] = [private_key]
        conn_opts[:auth_methods] = ["publickey"]
      elsif opts[:password]
        logger.debug("SSH Authenticating with password method")
        conn_opts[:password] = opts[:password]
        conn_opts[:auth_methods] = ["password"]
      else
        ## lets hope ssh is already pre-configured
        #logger.error("Please provide password or key for ssh authentication")
        #raise Net::SSH::AuthenticationFailed
      end
      @session = Net::SSH.start(host, @user, **conn_opts)
      @last_accessed = Time.now
    end

    # find key as an absolute file, relative to private, home or workdir;
    #   relative to main repo it is not allowed to avoid leaks if possible
    def expand_private_key(path)
      if Host.localhost.file_exist?(path)
        # absolute path or relative to workdir
        return Host.localhost.absolute_path(path)
      elsif File.exist?(PRIVATE_DIR + "/" + path)
        return PRIVATE_DIR + "/" + path
      elsif File.exist?(File.expand_path("~/#{path}"))
        return File.expand_path("~/#{path}")
      else
        raise "cannot find private key file"
      end
    end

    def close
      @session.close unless closed?
    end

    def closed?
      return ! @session.active?(verify: false)
    end

    def active?(verify: false)
      return @session && ! @session.closed? && (!verify || active_verified?)
    end

    # make sure connection was recently enough actually usable;
    #   otherwise perform a simple connection test
    private def active_verified?
      case
      when @last_accessed.nil?
        raise "ssh session initialization issue, we should never be here"
      when Time.now - @last_accessed < 120 # 2 minutes
        return true
      else
        res = exec("echo")
        if res[:success]
          @last_accessed = Time.now
          return true
        else
          return false
        end
      end
    end

    def session
      # the assumption is that if somebody gets session, he would also call
      # something on it. So if a command or file transfer or something is called
      # then operation on success will prove session alive or will cause
      # session to show up as closed. If that assumption proves wrong, we may
      # need to find another way to update @last_accessed, perhaps only inside
      # methods that really prove session is actually alive.
      @last_accessed = Time.now
      return @session
    end

    # @param [String] local the local filename to upload
    # @param [String] remote the directory, where to upload
    # @param [String] hostname the host where to upload
    # @param [String] username
    # @param [String] password
    #
    def scp_to(local, remote)
      begin
        puts session.exec!("mkdir -p #{remote} || echo ERROR")
        session.scp.upload!(local, remote, :recursive=>true)
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
        session.scp.download!(remote, local, :recursive=>true)
      rescue Net::SCP::Error
        logger.error("SCP failed!")
      end
    end

    def exec(command, opts={})
      # we want to have a handle over the result in case of error occurring
      # so that we catch any intermediate data for better reporting
      res = opts[:result] || {}

      # now actually execute the ssh call
      begin
        exec_raw(command, **opts, result: res)
      rescue => e
        res[:success] = false
        res[:error] = e
        res[:response] = exception_to_string(e)
      end
      if res[:stdout].equal? res[:stderr]
        output = res[:stdout]
      else
        output = "STDOUT:\n#{res[:stdout]}\nSTDERR:\n#{res[:stderr]}"
      end
      if res[:response]
        # i.e. an error was raised durig the call
        res[:response] = "#{output}\n#{res[:response]}"
      else
        res[:response] = output
      end

      unless res.has_key? :success
        res[:success] = res[:exitstatus] == 0 && ! res[:exitsignal]
      end

      return res
    end

    # TODO: use shell service for greater flexibility and interactive commands
    #       http://net-ssh.github.io/ssh/v1/chapter-5.html
    # TODO: allow setting environment variables via channel.env
    def exec_raw(command, opts={})
      res = opts[:result] || {}
      res[:command] = command
      instruction = 'Remote cmd: `' + command + '` @ssh://' +
                    ( @user ? "#{@user}@#{@host}" : @host )
      logger.info(instruction)
      res[:instruction] = instruction
      exit_status = nil
      stdout = res[:stdout] = opts[:stdout] || String.new
      stderr = res[:stderr] = opts[:stderr] || stdout
      exit_signal = nil
      channel = session.open_channel do |channel|
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
      # launch a processing thread unless such is already running
      loop_thread!
      # wait channel to finish; nil or 0 means no timeout (wait forever)
      wait_since = Time.now
      while opts[:timeout].nil? ||
            opts[:timeout] == 0 ||
            Time.now - wait_since < opts[:timeout]
        break unless channel.active?
        sleep 1
      end
      if channel.active?
        # looks like we hit the timeout
        channel.kill
        logger.error("ssh channel timeout @#{@host}: #{command}")
      end
      unless opts[:quiet]
        logger.print(stdout, false)
        logger.print(stderr, false) unless stdout == stderr
      end
      logger.info("Exit Status: #{exit_status}")

      # TODO: should we use mutex to make sure our view of `res` is updated
      #   according to latest @loop_thread updates?
      return res.merge!({ exitstatus: exit_status, exitsignal: exit_signal })
    end

    # launches a new loop/process thread unless we have one already running
    def loop_thread!
      unless @loop_thread && @loop_thread.alive?
        @loop_thread = Thread.new { session.loop }
      end
    end
  end
end
