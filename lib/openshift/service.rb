module CucuShift
  # represents OpenShift v3 Service concept
  class Service
    include Common::Helper
    include Common::UserObjectHelper

    attr_reader :props, :name, :project

    # @param name [String] service name
    # @param project [CucuShift::Project] the project where service was created
    def initialize(name:, project:, props: {})
      @name = name
      @project = project
      @props = props
    end

    def env
      project.env
    end

    def ==(s)
      s.kind_of?(self.class) && name == s.name && project == s.project
    end
    alias eql? ==

    def hash
      :service.hash ^ name.hash ^ project.hash
    end
  end
end
