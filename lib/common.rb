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
      def expand_private_path(path, public_safe: false)
        if Host.localhost.file_exist?(path)
          # absolute path or relative to workdir
          return Host.localhost.absolute_path(path)
        elsif File.exist?(PRIVATE_DIR + "/" + path)
          return PRIVATE_DIR + "/" + path
        elsif public_safe && File.exist?(CucuShift::HOME + "/" + path)
          return CucuShift::HOME + "/" + path
        elsif File.exist?(File.expand_path("~/#{path}"))
          return File.expand_path("~/#{path}")
        else
          raise "cannot lookup private path: #{path}"
        end
      end

      # @return the desired base docker image tag prefix based on
      #   PRODUCT_DOCKER_REPO env variable
      def product_docker_repo
        if ENV["PRODUCT_DOCKER_REPO"] &&
            !ENV["PRODUCT_DOCKER_REPO"].empty?
          ENV["PRODUCT_DOCKER_REPO"]
        else
          conf[:product_docker_repo]
        end
      end

      def project_docker_repo
        conf[:project_docker_repo]
      end

      # the 'oc describe xxx' output is key-value formatted with ':' as the
      #  separator.
      def parse_oc_describe(oc_output)
        result = {}
        ### the following has become un-reliable per bugs https://bugzilla.redhat.com/show_bug.cgi?id=1268954 & https://bugzilla.redhat.com/show_bug.cgi?id=1268933
        ## for now, we disable the parsing part and just use regexp to capture properties that is of interest
        
        # multi_line_key = nil
        # multi_line = false
        # oc_output.each_line do |line|
        #   if multi_line
        #     if line.size == 0
        #       # multline value ended reset it for the next prop
        #       multi_line = false
        #       multi_line_key = nil
        #     else
        #       result[multi_line_key] += line + "\n"
        #     end
        #   else
        #     name, sep, val = line.partition(':')
        #     if val == "\n"
        #       # multiline output
        #       multi_line_key = name
        #       result[name] = ""
        #       multi_line = true
        #     else
        #       result[name] = val.strip()
        #     end
        #   end
        # end
        # more parsing for commonly used properties
        pods_regexp = /Pods Status:\s+(\d+)\s+Running\s+\/\s+(\d+)\s+Waiting\s+\/\s+(\d+)\s+Succeeded\s+\/\s+(\d+)\s+Failed/
        replicas_regexp = /Replicas:\s+(\d+)\s+current\s+\/\s+(\d+)\s+desired/
        labels_regexp = /Labels:\s+(.+)/
        selectors_regexp = /Selector:\s+(.+)/
        images_regexp = /Images(s):\s+(.+)/
        status_regexp = /\s+Status:\s+(.+)/


        pods_status = pods_regexp.match(oc_output)
        replicas_status = replicas_regexp.match(oc_output)
        overall_status = status_regexp.match(oc_output)
        selectors_status = selectors_regexp.match(oc_output)
        images_status = images_regexp.match(oc_output)

        if pods_status
          result[:pods_status] = {:running => pods_status[1], :waiting => pods_status[2],
            :succeeded=>pods_status[3], :failed => pods_status[4]}
        end
        if replicas_status
          result[:replicas_status] = {:current => replicas_status[1], :desired => replicas_status[2]}
        end
        result[:images] = images_status[1] if images_status
        result[:overall_status] = overall_status[1] if overall_status
        result[:selectors] = selectors_status[1] if selectors_status

        return result
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

      # hack to have host.rb autoloaded when it is used through Helper outside
      # Cucumber (at the same time avoiding circular dependencies). That avoids
      # need for the external script to know that host.rb is required.
      CucuShift.autoload :Host, "host"
    end # module Helper

    module UserObjectHelper
      # execute cli command as user or admin
      # @param as [CucuShift::User, CucuShift::ClusterAdmin, :admin] the user
      #   to run cli with
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
            return env.admin.cli_exec(key, **opts)
          else
            raise "user not specified and we don't have admin in this environment, what on earth do you expect?"
          end
        elsif user.respond_to?(:env) && user.respond_to?(:cli_exec)
          raise "user #{user} and self.env '#{env}' do not match, likely a logical issue in test scenario" if user.env != env
          user.cli_exec(key, **opts)
        else
          raise "unknown user specification for the operation: '#{user.inspect}'"
        end
      end

      def webconsole_exec(as:, action:, **opts)
        user = as
        ## todo: some invalid check
        user.webconsole_exec(action, **opts)
      end

    end # module UserObjectHelper

    # some ugly hack that we need to be more reliable
    module Hacks
      # we'll try calling this one after common pry calls as well by affected
      #   thread users (to make sure we didn't miss some pry call)
      def fix_require_lock
        if defined?(Pry) &&
           Kernel::RUBYGEMS_ACTIVATION_MONITOR.instance_variable_get(:@mon_owner) == Thread.current
          Kernel.puts("ERROR: Detected stale RUBYGEMS_ACTIVATION_MONITOR lock, see: https://bugzilla.redhat.com/show_bug.cgi?id=1257578")
          Kernel::RUBYGEMS_ACTIVATION_MONITOR.mon_exit
        end
      rescue => e
        Kernel.puts("ERROR: Ruby private API changed? cannot execute fix_require_lock: #{e.inspect}")

      end 
    end

    module Setup
      def self.handle_signals
        # Cucumber traps SIGINT anf SIGTERM to allow graceful shutdown,
        #   i.e. interrupting scenario and letting After and at_exit execute.
        #   This is safer than immediate exit. To exit quick, hit Ctrl+C twice.
        #Signal.trap('SIGINT') { Process.exit!(255) }
        #Signal.trap('SIGTERM') { Process.exit!(255) }
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
