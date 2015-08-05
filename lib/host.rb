require 'shellwords'

require 'common'
require 'ssh'

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
      @workdir = opts[:workdir] ? opts[:workdir].dup.freeze : "/tmp/workdir/" + EXECUTOR_NAME
    end

    def self.localhost
      @localhost if @localhost

      @localhost ||= case RUBY_PLATFORM
      when /linux/
        LocalLinuxLikeHost.new(nil)
      else
        raise "don't know a suitable host for your platform"
      end
    end

    private def properties
      @properties
    end

    def [](key)
      properties[key]
    end

    def workdir(**opts)
      unless @workdir_exists
        @workdir_exists = mkdir(@workdir, :raw => true)
      end
      if ! opts[:absolute] || ["/", "\\"].include?(@workdir[0])
        return @workdir
      else
        return @workdir_abs ||= File.absolute_path(@workdir, pwd)
      end
    end

    # @return pwd of raw commands executed on the host
    private def pwd
      raise '#{__method__} method not implemented'
    end

    # @ param [String] path the path to convert to an absolute path
    # @return expanded path with workdir as basedir; IO might not be done so
    #   workdir may not exist after the call; if absolute, path is returned
    #   intact
    def absolute_path(path, **opts)
      if ["/", "\\"].include? path[0]
        return path
      elsif opts[:raw]
        return File.absolute_path(path, pwd)
      else
        ws_abs_path = ["/", "\\"].include?(@workdir[0]) ? @workdir : workdir(absolute: true)
        return File.absolute_path(path, ws_abs_path)
      end
    end

    def roles
      @properties[:roles] ||= {}
    end

    def has_role?(role)
      roles.include? role
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

    def clean_up
      if @workdir_exists
        @workdir_exists = ! delete(@workdir, :r => true, :raw => true)
      end
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
      return mkdir("cucushift_lock_#{key}", :raw => true, :parents => false)
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

    def shell_escape(str)
      # basically single quote replacing occurances of `'` with `'\''`
      # return "'" << str.gsub("'") {|m| %q{'\''}} << "'"

      # escape nesting reads better with backslashes
      Shellwords.escape(str)
    end

    # @return pwd of raw commands executed on the host
    private def pwd
      res = exec_raw('pwd', quiet: true)
      unless res[:exitstatus] == 0
        logger.error(res[:stdout])
        logger.error(res[:stderr])
        raise "could not get pwd, see log"
      end

      return res[:stdout].strip
    end

    # @param [String] file check this file for existence
    def file_exist?(file, opts={})
      exec("ls -d #{shell_escape(file)}", **opts)[:success]
    end

    # @param [String, nil, :admin] user execute command as that OS user
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
        raise "username cannot be empty" if user.empty?
        cmd = "sudo -u #{user} bash -c #{shell_escape(commands_to_string("cd '#{workdir}'", commands))}"
        return exec_raw(cmd, **opts)
      end
    end

    # @return false if dir exists and raise if cannot be created
    def mkdir(remote_dir, opts={})
      parents = opts[:parents] || ! opts.has_key?(:parents) ? " -p" : ""
      if opts[:raw]
        res = exec_raw("mkdir#{parents} '#{remote_dir}'", **opts)
      else
        res = exec("mkdir#{parents} '#{remote_dir}'", **opts)
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
        bad_files = ["/", "../", "./", "..", ".", "", nil, false]
        if bad_files.include? file
          raise "should not remove file named '#{file}'"
        end

        r = "-r"
      else
        r = ""
      end
      file = shell_escape file
      if opts[:home] && ! file.start_with?('/','\\')
        # relative to host local user home directory
        # relies strongly on bad_files checking above
        file = '~/' + file
      end
      if opts[:raw]
        exec_raw("rm #{r} -f -- #{file}", opts)
        opts[:quiet] = true
        res = exec_raw("ls -d -- #{file}", opts)
      else
        exec("rm #{r} -f -- #{file}", opts)
        opts[:quiet] = true
        res = exec("ls -d -- #{file}", opts)
      end

      return ! res[:success]
    end

    # wait until one file in the list is found and returns its name
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
      hostname ||= self.hostname
      super

      # figure out workdir
      # write everything to WORKSPACE on jenkins, otherwise use `~/workdir`
      # on localhost, usage of relative workspace path may cause trouble
      basepath = ENV["WORKSPACE"] ? ENV["WORKSPACE"]+"/workdir/" : "~/workdir/"
      basepath = File.expand_path(basepath)

      @workdir = opts[:workdir] ? opts[:workdir] : EXECUTOR_NAME
      @workdir = File.absolute_path(@workdir, basepath).freeze
    end

    def file_exist?(file, opts={})
      # intentionally use @workdir to avoid creating dir unnecessarily
      file = File.absolute_path(file, @workdir) unless opts[:raw]
      return File.exist?(file)
    end

    # Do not use unless absolutey sure what you are doing; we should usually
    #   sit inside workdir
    def chdir(dir=nil)
      Dir.chdir(dir || workdir)
    end

    def exec_raw(*cmds, **opts)
      if opts.delete(:single) || cmds.size == 1
        return exec_foreground(*cmds, **opts)
      else
        return exec_foreground(*commands_to_string(cmds), **opts)
      end
    end

    # TODO: implement delete, mkdir, touch in ruby

    def clean_up
      chdir(HOME)
      super
    end

    def hostname
      HOSTNAME
    end
  end

  class SSHAccessibleHost < LinuxLikeHost
    # @return [boolean] if there is currently an active connection to the host
    private def connected?(verify: false)
      @ssh && @ssh.active?(verify: verify)
    end

    # processes ssh specific opts from the initialization options
    private def ssh_opts(opts)
      ssh_opts = {}
      properties.each { |prop, val|
        if prop.to_s.start_with? 'ssh_'
          ssh_opts[prop.to_s.gsub(/^ssh_/,'').to_sym] = val
        elsif prop == :user
          ssh_opts[:user] = val
        end
      }
      ssh_opts.merge! opts

      return ssh_opts
    end

    private def ssh(opts={})
      return @ssh if connected?(verify: true)
      return @ssh = SSH.new(hostname, ssh_opts(opts))
    end

    # @note execute commands without special setup
    def exec_raw(*commands, **opts)
      ssh(opts).exec(commands_to_string(commands),opts)
    end

    private def close
      @ssh.close if @ssh
    end

    def clean_up
      return unless connected?
      super
      close
    end
  end
end
