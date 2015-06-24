require 'rules_command_executor'

module CucuShift
  class CliExecutor
    include Common::Helper

    RULES_DIR = File.expand_path(HOME + "/lib/rules/client")

    attr_reader :opts

    def initialize(env, **opts)
      @opts = opts
    end

    # @param [CucuShift::User] user user to execute command with
    # @param [Symbol] key command key
    # @param [Hash] opts command options
    def exec(user, key, **opts)
      raise
    end

    def api_proto
      opts[:api_proto] || "https"
    end

    def api_port
      opts[:api_port] || "8443"
    end

    def api_hostname
      opts[:api_hostname] || env.master_hosts.first.hostname
    end

    def api_url
      opts[:api_url] || "#{api_proto}://#{api_hostname}:#{api_port}"
    end

    private def version
      return opts[:cli_version]
      # this method needs to be overwriten per executor to find out version
    end

    private def rules_version(str_version)
      return str_version.split('.')[1]
    end
  end

  # execute cli commands on the first master machine as each user respectively
  #   it also does prior cert and token setup
  class MasterOsPerUserCliExecutor < CliExecutor
    def initialize(env, **opts)
      super
      @executors = {}
    end

    # @param [CucuShift::User] user user to execute command with
    # @return rules executor, separate one per user
    def executor(user)
      return @executors[user.name] if @executors[user.name]

      host = user.env.master_hosts.first
      version = version_for_user(user, host)
      executor = RulesCommandExecutor.new(host: host, user: user.name, rules: File.expand_path(RULES_DIR + "/" + rules_version(version) + ".yaml"))

      # make sure cli execution environment is setup for the user
      # in environments where we run client commands as single operating system
      # user, perhaps we need to do this upon switching users
      # clean-up:
      #   .config/openshift/config
      #   .kube/config
      executor.run(:logout, {}) # ignore outcome
      res = executor.run(:login, username: user.name, password: user.password, ca: "/etc/openshift/master/ca.crt", server: "#{api_proto}://#{host.hostname}:#{api_port}")
      unless res[:success]
        logger.error res[:response]
        raise "cannot login with command: #{res[:instruction]}"
      end

      return @executors[user.name] = executor
    end

    private def version_for_user(user, host)
      # return user requested version if set
      return version if version

      res = host.exec_as(user.name, "oc version")
      raise "cannot execute on host #{host.hostname} as user #{user.name}" unless res[:success]

      # we assume all users will use same oc version
      return opts[:cli_version] = res[:response].scan(/^os?c v(.+)$/)[0][0]
    end

    def exec(user, key, **opts)
      executor(user).run(key, opts)
    end
  end
end
