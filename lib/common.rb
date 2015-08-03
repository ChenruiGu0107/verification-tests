require 'open3'

require 'cucushift'
require 'manager'
require 'base_helper'

module CucuShift
  module Common
    module Helper
      include BaseHelper

      def manager
        CucuShift::Manager.instance
      end

      def conf
        manager.conf
      end

      def logger
        manager.logger
      end

      def localhost
        Host.localhost
      end

      # find an absolute file, relative to private, home or workdir;
      #   relative to main repo it is not allowed to avoid leaks if possible
      def expand_private_path(path)
        if Host.localhost.file_exist?(path)
          # absolute path or relative to workdir
          return Host.localhost.absolute_path(path)
        elsif File.exist?(PRIVATE_DIR + "/" + path)
          return PRIVATE_DIR + "/" + path
        elsif File.exist?(File.expand_path("~/#{path}"))
          return File.expand_path("~/#{path}")
        else
          raise "cannot lookup private path: #{path}"
        end
      end

      ## @param res [CucuShift::ResultHash] the result to verify
      ## @note will log and raise error unless result is successful
      #def result_should_be_success(res)
      #  unless res[:success]
      #    logger.error(res[:response])
      #    raise "result unsuccessful, see log"
      #  end
      #end
      #
      ## @param res [CucuShift::ResultHash] the result to examine
      ## @note will log and raise error unless result is failure
      #def result_should_be_failure(res)
      #  if res[:success]
      #    logger.error(res[:response])
      #    raise "result successful but should have been failure, see log"
      #  end
      #end
    end

    module UserObjectHelper
      # execute cli command as user or admin
      # @param as [CucuShift::User, :admin] the user to run cli with
      # @param key [Symbol] the command key to execute
      # @param opts [Hash] the command options
      # @return [CucuShift::ResultHash]
      # @note usually invoked by managed objects like projects, routes, etc.
      #   that could have same operations executed by admin or user; this method
      #   simplifies such calls; requires `#env` method defined
      def cli_exec(as:, key:, **opts)
        user = as

        if user == :admin
          if env.admin?
            return env.admin_cli_executor.exec(key, **opts)
          else
            raise "user not specified and we don't have admin in this environment, what on earth do you expect?"
          end
        elsif user.kind_of? CucuShift::User
          raise "user #{user} and self.env '#{env}' do not match, likely a logical issue in test scenario" if user.env != env
          user.cli_exec(key, **opts)
        else
          raise "unknown user specification for the operation: '#{user.inspect}'"
        end
      end
    end

    #module UserObjectClassHelper
      # execute cli command as user or admin
      # @param as [CucuShift::User, CucuShift::Environment] the user to run cli
      #   with or environment when admin command is desired
      # @param key [Symbol] the command key to execute
      # @param opts [Hash] the command options
      # @return [CucuShift::ResultHash]
      # @note usually invoked by managed classes like projects, routes, etc.
      #   that could have same operations executed by admin or user; this method
      #   simplifies such calls;
    #  def cli_exec(as:, key:, **opts)
    #    as

    #    if as.kind_of? Environment
    #      if as.admin?
    #        return as.admin_cli_executor.exec(key, **opts)
    #      else
    #        raise "we don't have admin in this environment, what on earth do you expect?"
    #      end
    #    elsif as.kind_of? CucuShift::User
    #      as.cli_exec(key, **opts)
    #    else
    #      raise "unknown user specification for the operation: '#{as.inspect}'"
    #    end
    #  end
    #end

    module Setup
      def self.handle_signals
        # Exit the process immediately when SIGINT/SIGTERM caught,
        # since cucumber traps these signals.
        Signal.trap('SIGINT') { Process.exit!(255) }
        Signal.trap('SIGTERM') { Process.exit!(255) }
      end

      def self.set_cucushift_home
        # CucuShift.const_set(:HOME, File.expand_path(__FILE__ + "../../.."))
        CucuShift::HOME.freeze
        ENV["CUCUSHIFT_HOME"] = CucuShift::HOME
      end
    end

    # @note some platform neutral shell commands execution methods;
    #       to be included into Host classes
    module LocalShell
      # use the opt hash to introduce parameters you want to set
      # the if no :timeout is sepecified, it will default to 600 seconds
      def exec_foreground(*cmd, **opts)
        # TODO: user read_nonblock and implement proper timeout
        # see: https://gist.github.com/lpar/1032297

        cmd.flatten!
        cmdstr = cmd.size == 1 ? cmd.first : "#{cmd}"
        # environment hash is first param according to docs
        cmd.unshift(opts[:env]) if opts[:env]

        res = opts[:result] || {}
        res[:command] = cmdstr
        instruction = "\`#{cmdstr}\`"
        logger.info(instruction)
        res[:instruction] = instruction
        exit_status = nil
        logger.info("Shell Commands:\n" + cmdstr)
        if opts[:timeout]
          timeout_value = opts[:timeout].to_i
        else
          timeout_value = 3600
        end
        Timeout::timeout(timeout_value) {
          if opts[:stderr] == opts[:stdout]
            stdout, exit_status = Open3.capture2e(*cmd, stdin_data: opts[:stdin])
            stdout = opts[:stdout] << stdout if opts[:stdout]
            res[:stdout] = res[:stderr] = stdout
          else
            stdout, stderr, exit_status = Open3.capture3(*cmd, stdin_data: opts[:stdin])
            stdout = opts[:stdout] << stdout if opts[:stdout]
            stderr = opts[:stderr] << stdout if opts[:stderr]
            res[:stdout] = stdout
            res[:stderr] = stderr
          end

          #stdin, stdout_and_stderr, wait_thr = Open3.popen2e(env=env, cmd)
          ## should we avoid programs hanging waiting on input  or
          ## make sure we catch instances where a program requests an input?
          ## stdin.close
          #result[:response] = stdout_and_stderr.read
          #result[:exitstatus] = wait_thr.value.exitstatus
        }
        res[:exitstatus] = exit_status
        res[:success] = exit_status == 0
        res[:response] = res[:stdout]
        unless opts[:quiet]
          logger.print(res[:stdout], false)
          logger.print(res[:stderr], false) if res[:stderr] != res[:stdout]
        end
        logger.info("Exit Status: #{res[:exitstatus]}")
        return res
      end


      #def self.exec_background(cmd, opts={})
      #  env = opts[:env]
      #  env ||= {}
      #  result = {}
      #  Common::Helper.logger.info("Shell Command: #{cmd}")
      #  # env.merge!({CUCUSHIFT_KILL_COOKIE = "2h3_dJSasdsfd2BD"})
      #  pid = Process.spawn(env, cmd, :pgroup => true)
      #  result[:pid] = pid
      #  Common::Helper.manager.pgids << pid
      #
      #  result[:instruction] = cmd
      #  return result
      #end
    end
  end
end
