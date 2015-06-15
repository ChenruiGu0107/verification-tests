module CucuShift
  # @note represents an OpenShift environment user account
  class User
    attr_reader :name, :password, :env, :config
    def initialize(name, password, env, **config)
      @name = name.freeze
      @env = env
      @password = password.freeze
      @config = config
    end

    def cli_executor
      env.cli_executor
    end

    def cli_exec(key, opts={})
      cli_executor(self, key, opts)
    end
  end
end
