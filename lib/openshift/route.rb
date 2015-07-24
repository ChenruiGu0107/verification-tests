module CucuShift
  # @note represents an OpenShift route
  class Route
    def initialize(name: nil, project:, kind: nil, resource: nil..)
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
