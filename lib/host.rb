require 'common'

module CucuShift
  # @note a generic machine; base for creating actual implementations
  class Host
    include Common::Helper

    attr_reader :hostname

    # @param hostname [String] that test machine can access the machine with
    # @param opts [Hash] any other options relevant to implementation
    def initialize(hostname, opts={})
      @hostname = hostname.dup.freeze
      @properties = opts.dup
      @workdir = opts[:workdir] ? opts[:workdir].dup.freeze : EXECUTOR_NAME
    end

    private def properties
      @properties
    end

    private def workdir
      unless @workdir_exists
        @workdir_exists = mkdir(@workdir, :raw => true)
      end
      @workdir
    end

    # escape characters for use as command arguments
    def shell_escape(str)
      raise '#{__method__} method not implemented'
    end

    def exec(commands, opts={})
      exec_as(nil, commands, opts)
    end

    def exec_admin(commands, opts={})
      exec_as(:admin, commands, opts)
    end

    def exec_as(user, commands, opts={})
      raise '#{__method__} method not implemented'
    end

    # @note exec without any preparations like chdir
    def exec_raw(*commands, **opts)
      raise '#{__method__} method not implemented'
    end

    # @note execute process in the background and inserts clean-up hooks
    def exec_background(*commands, **opts)
      raise '#{__method__} method not implemented'
    end

    # @param spec - interaction specification
    # @param opts [Hash] additional options
    def exec_interactive(spec, opts={})
      exec_interactive_as(nil, spec, opts={})
    end

    def exec_interactive_admin(spec, opts={})
      exec_interactive_as(:admin, spec, opts={})
    end

    def exec_interactive_as(user, spec, opts={})
      raise '#{__method__} method not implemented'
    end

    def copy_to(local_file, remote_file, opts={})
      raise '#{__method__} method not implemented'
    end

    def copy_from(remote_file, local_file, opts={})
      raise '#{__method__} method not implemented'
    end

    # @return false if dir exists and raise if cannot be created
    def mkdir(remote_dir, opts={})
      raise '#{__method__} method not implemented'
    end

    def touch(file, opts={})
      raise '#{__method__} method not implemented'
    end

    # @return false on unsuccessful deletion
    def delete(file, opts={})
      raise '#{__method__} method not implemented'
    end

    # @return file name of first file found
    def wait_for_files(*files, **opts)
      raise '#{__method__} method not implemented'
    end

    def get_local_ip
      return @local_ip if @local_ip
      return properties[:local_ip] if properties[:local_ip]
      return @local_ip = get_local_ip_platform
    end

    def get_local_hostname
      return @local_hostname if @local_hostname
      return properties[:local_hostname] if properties[:local_hostname]
      return @local_hostname = get_local_hostname_platform
    end

    def get_local_hostname_platform
      raise '#{__method__} method not implemented'
    end

    def get_local_ip_platform
      raise '#{__method__} method not implemented'
    end

    def cleanup
      @workdir_exists = ! delete(@workdir, :r => true, :raw => true)
    end

    # @param key [STRING] if you perform multiple unrelated setup operations on host, this param lets framework distinguish between lock directories
    # @note convenience to perform setup on a host
    def setup(key="SETUP")
      raise "provide setup code in a block" unless block_given?

      if setup_lock(key)
        # we have the lock, lets perform setup
        begin
          yield
          setup_lock_clear(key)
        rescue Exception => e
          setup_lock_clear(key, false)
          raise e
        end
      else
        # wait for another cucushift instance to perform broker setup
        unless setup_lock_wait(key)
          raise "setup of broker failed on another runner, see its logs or clear it by removing the directory /root/broker_setup from the devenv"
        end
      end
    end

    # set setup lock on this broker instance
    private def setup_lock(key)
      return mkdir("cucushift_lock_#{key}", :raw => true)
    end

    # clear setup lock for this instance
    private def setup_lock_clear(key, success=true)
      touch("cucushift_lock_#{key}/#{success ? 'DONE' : 'FAIL'}", :raw => true)
      # ret_code, msg = ssh.exec("touch broker_setup/#{success ? 'DONE' : 'FAIL'}")
    end

    # wait until setup lock is cleared or status is fail
    private def setup_lock_wait(key)
      file = wait_for_files("cucushift_lock_#{key}/DONE", "cucushift_lock_#{key}/FAIL", :raw => true)
      return file.include?("DONE")
      #ret_code, msg = ssh.exec('while sleep 1; do [ -f broker_setup/DONE ] && break; [ -f broker_setup/FAIL ] && exit 1; done')
      #return ret_code == 0
    end
  end

  class LinuxLikeHost < Host
    def get_local_hostname_platform
      res = exec_raw('hostname')
      if res[:success]
        return res[:response].strip
      else
        logger.error(res[:response])
        raise "can not get local hostname"
      end
    end

    def get_local_ip_platform
      res = exec("ip route get 10.10.10.10 | sed -rn 's/^.*src (([0-9]+\.?){4})/\\1/p'")
      if res[:success]
        return res[:response].strip
      else
        logger(res[:response])
        raise "cannot get local ip of broker"
      end
    end

    def commands_to_string(*commands)
      return commands.flatten.join("\n")
    end

    # I don't like Shellwords.escape for readability
    def shell_escape(str)
      # basically single quote replacing occurances of `'` with `'\''`
      return "'" << str.gsub("'") {|m| %q{'\''}} << "'"
    end

    # @note executes commands on host in workdir
    def exec_as(user, *commands, **opts)
      case user
      when nil, self[:user]
        # perform blind exec in workdir
        return exec_raw("cd '#{workdir}'", commands, **opts)
      when :admin
        # try to use sudo
        # in the future we may use `properties` for different methods
        # we may also allow choosing shell
        # TODO: are we admins?
        if self[:user] == "root"
          return exec_as(nil, *commands, **opts)
        else
          cmd = "sudo bash -c #{shell_escape(commands_to_string("cd '#{workdir}'", commands))}"
          return exec_raw(cmd, **opts)
        end
      else # try sudo -u
        cmd = "sudo -u #{user} bash -c #{shell_escape(commands_to_string("cd '#{workdir}'", commands))}"
        return exec_raw(cmd, **opts)
      end
    end

    # @return false if dir exists and raise if cannot be created
    def mkdir(remote_dir, opts={})
      if opts[:raw]
        res = exec_raw("mkdir '#{remote_dir}'", opts)
      else
        res = exec("mkdir '#{remote_dir}'", opts)
      end

      return res[:success]
    end

    def touch(file, opts={})
      if opts[:raw]
        exec_raw("touch '#{file}'", opts)
      else
        exec("touch '#{file}'", opts)
      end
    end

    # @return false on unsuccessful deletion
    def delete(file, opts={})
      if opts[:r] || opts[:recursive]
        # make sure we do not cause catastrophic damage
        bad_files = ["/", "../", "./", "..", ".", ""]
        if bad_files.include? file
          raise "should not remove #{file}"
        end

        r = "-r"
      else
        r = ""
      end
      if opts[:raw]
        exec_raw("rm #{r} -f '#{file}'", opts)
        res = exec_raw("ls -d '#{file}'", opts)
      else
        exec("rm #{r} -f '#{file}'", opts)
        res = exec("ls -d '#{file}'", opts)
      end

      return ! res[:success]
    end

    def wait_for_files(*files, **opts)
      conditions = [files].flatten.map { |f|
        "[ -f \"#{f}\" ] && echo FOUND FILE: && break\n"
      }.join

      cmd = "while sleep 1; do
               #{conditions}
             done"
      if opts[:raw]
        res = exec_raw(cmd)
      else
        res = exec(cmd)
      end

      return res[:response][/(?<=FOUND FILE: ).*(?=$)/]
    end
  end

  class LocalLinuxLikeHost < LinuxLikeHost
    include Common::LocalShell

    def initialize(hostname, opts={})
      super
      unless @workdir.start_with? "/"
        # write everything to WORKSPACE on jenkins, otherwise use `~/workdir`
        basepath = ENV["WORKSPACE"] ? ENV["WORKSPACE"] + "/workdir/" : "~/workdir/"
        @workdir = File.expand_path("#{basepath}#{@workdir}").freeze
      end
    end

    # TODO: implement delete, mkdir, touch in ruby

    def hostname
      HOSTNAME
    end
  end

  class SSHAccessibleHost < LinuxLikeHost
    # @return [boolean] if there is currently an active connection to the host
    private def connected?
      @ssh && @ssh.active?
    end

    private def ssh(opts={})
      return @ssh if connected?

      ssh_opts = {}
      properties.each { |prop, val|
        if prop.to_s.start_with? 'ssh_'
          ssh_opts[prop.to_s.gsub(/^ssh_/,'').to_sym] = val
        elsif prop == :user
          ssh_opts[:user] = val
        end
      }
      ssh_opts.merge! opts

      return @ssh = SSH.new(hostname, ssh_opts)
    end

    # @note execute commands without special setup
    def exec_raw(*commands, **opts)
      ssh(opts).exec(commands_to_string(commands),opts)
    end

    private def close
      @ssh.close
    end

    def cleanup
      return unless connected?
      super
      close
    end
  end
end



