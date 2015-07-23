module CucuShift
  # @note represents an OpenShift environment project
  class Project
    attr_reader :cached_admins

    def initialize(name:, env:, admins:, **config)
      @name = name
      @env = env
      @config = config
      @cached_admins = admins
    end

    #def delete
    #end

    #def create
    #end
  end
end
