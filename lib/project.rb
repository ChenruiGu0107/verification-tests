module CucuShift
  # @note represents an OpenShift environment project
  class Project
    def initialize(name:, env:, owner:, **config)
      @name = name
      @env = env
      @config = config
    end
  end
end
