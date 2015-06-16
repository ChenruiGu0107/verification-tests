require 'rules_command_executor'

module CucuShift
  class CliExecutor
    RULES_DIR = File.expand_path(HOME + "/lib/rules/client")

    def initialize(**opts)
      @opts = opts
    end

    # @param [CucuShift::User] user user to execute command with
    # @param [Symbol] key command key
    # @param [Hash] opts command options
    def exec(user, key, **opts)
      raise
    end

    private def version
      return opts[:cli_version]
      # this method needs to be overwriten per executor to find out version
    end

    private def rules_version(str_version)
      return str_version[0]
    end
  end

  # execute cli commands on the first master machine as each user respectively
  class MasterOsPerUserCliExecutor < CliExecutor
    def initialize(**opts)
      super
      @executors = {}
    end

    # @param [CucuShift::User] user user to execute command with
    # @return rules executor, separate one per user
    def executor(user)
      return @executors[user.name] if @executors[user.name]

      host = user.env.master_hosts.first
      version = version_for_user(user, host)
      @executors[user.name] = RulesCommandExecutor.new(host: host, user: user.name, rules: File.expand_path(RULES_DIR + "/" + rules_version(version) + ".yaml"))
      return @executors[user.name]
    end

    private def version_for_user(user, host)
      # return user requested version if set
      return version if version

      res = host.exec_as(user.name, "oc version")
      raise "cannot execute on host #{host.hostname} as user #{user.name}" unless res[:success]

      # we assume all users will use same oc version
      return opts[:cli_version] = res[:response][/^os?c v(.+)$/][1]
    end

    def exec(user, key, **opts)
      executor(user).run(key, opts)
    end
  end
end
