require 'open3'

require 'cucushift'
require 'manager'

module CucuShift
  module Common
    module Helper
      def manager
        CucuShift::Manager.instance
      end

      def conf
        manager.conf
      end

      def logger
        manager.logger
      end

      def to_bool(param)
        return false unless param
        if param.kind_of? String
          return !!param.downcase.match(/^(true|t|yes|y|on|[0-9]*[1-9][0-9]*)$/i)
        elsif param.respond_to? :empty?
          # true for non empty maps and arrays
          return ! param.empty?
        else
          # lets be more conservative here
          return !!param.to_s.downcase.match(/^(true|yes|on)$/)
        end
      end

      def word_to_num(which)
        if which =~ /first|default/
          return 0
        elsif which =~ /other|another|second/
          return 1
        elsif which =~ /third/
          return 2
        elsif which =~ /fourth/
          return 3
        elsif which =~ /fifth/
          return 4
        end
        raise "can't translate #{which} to a number"
      end

      # @return hash with same content but keys.to_sym
      def hash_symkeys(hash)
        Hash[hash.collect {|k,v| [k.to_sym, v]}]
      end

      def exception_to_string(e)
        str = "#{e}\n    #{e.backtrace.join("\n    ")}"
        e = e.cause
        while e do
          str << "\nCaused by: #{e}\n    #{e.backtrace.join("\n    ")}"
          e = e.cause
        end
        return str
      end
    end

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

    # @note some platform neutral shell commands execution methods
    #       to be included into Host classes
    module LocalShell
      # use the opt hash to introduce parameters you want to set
      # the if no :timeout is sepecified, it will default to 600 seconds
      def exec_raw(*cmds, **opts)
        # TODO: user read_nonblock and implement proper timeout
        # see: https://gist.github.com/lpar/1032297

        cmds.flatten!
        # environment hash is first param according to docs
        cmds.unshift(opts[:env]) if opts[:env]

        res = opts[:result] || {}
        res[:command] = cmd
        instruction = "\`#{cmd}\`"
        logger.info(instruction)
        res[:instruction] = instruction
        exit_status = nil
        logger.info("Shell Command: #{cmd}")
        if opts[:timeout]
          timeout_value = opts[:timeout].to_i
        else
          timeout_value = 3600
        end
        Timeout::timeout(timeout_value) {
          if opts[:stderr] == opts[:stdout]
            stdout, exit_status = Open3.capture2e(stdin_data: opts[:stdin], *cmds)
            stdout = opts[:stdout] << stdout if opts[:stdout]
            res[:stdout] = res[:stderr] = stdout
          else
            stdout, stderr, exit_status = Open3.capture3(stdin_data: opts[:stdin], *cmds)
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
        logger.print(res[:stdout], false)
        logger.print(res[:stderr], false) if res[:stderr] != res[:stdout]
        logger.info("Exit Status: #{res[:exitstatus]}")
        return result
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
