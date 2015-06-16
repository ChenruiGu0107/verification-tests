require 'rules_command_executor'

module CucuShift
  class AdminCliExecutor
    attr_reader :env, :opts

    RULES_DIR = File.expand_path(HOME + "/lib/rules/admin")

    def initialize(env, **opts)
      @env = env
      @opts = opts
    end

    def exec(key, **opts)
      raise
    end

    private def version
      return opts[:admin_cli_version]
      # this method needs to be overriden per executor to find out version
    end

    private def rules_version(str_version)
      return str_version[0]
    end
  end

  # execites admin commands as admin on first master host
  class MasterOsAdminCliExecutor < AdminCliExecutor
    ADMIN_USER = :admin # might use a config variable for that

    def host
      env.master_hosts.first
    end

    def executor
      @executor ||= RulesCommandExecutor.new(host: host, user: ADMIN_USER, rules: File.expand_path(RULES_DIR + "/" + rules_version(version) + ".yaml"))
    end

    private def version(user, host)
      # return user requested version if set
      return super() if super()

      res = host.exec_as(ADMIN_USER, "oadm version")
      raise "cannot execute on host #{host.hostname} as admin" unless res[:success]
      return opts[:admin_cli_version] = res[:response][/^oadm v(.+)$/][1]
    end

    def exec(key, **opts)
      executor.run(key, opts)
    end
  end
end
