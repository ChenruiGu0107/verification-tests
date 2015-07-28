module CucuShift
  # represents an OpenShift pod
  class Pod
    include Common::Helper
    include Common::UserObjectHelper

    attr_reader :props, :name, :project

    # @param name [String] name of pod
    # @param project [CucuShift::Project] the project pod belongs to
    # @param props [Hash] additional properties of the pod
    def initialize(name:, project:, props: {})
      @name = name
      @project = project
      @props = props
    end

    def env
      project.env
    end

    def ==(p)
      p.kind_of?(self.class) && name == p.name && project == p.project
    end
    alias eql? ==

    def hash
      :pod.hash ^ name.hash ^ project.hash
    end
  end
end

