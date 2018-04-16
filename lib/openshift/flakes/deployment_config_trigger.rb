require_relative 'image_ref'

module CucuShift
  # represents a trigger structure inside a deployment config
  class DeploymentConfigTrigger
    attr_reader :params, :spec, :from
    private :spec, :params

    SUBCLASSES = []

    def self.inherited(subclass)
      super
      SUBCLASSES << subclass
    end

    # @param spec [Hash] the trigger hash as found within deployment config
    #   triggers array
    # @param dc [DeploymentConfig] the original deployment config
    def initialize(spec, dc)
      if spec["type"] != self.class::TYPE
        raise(ArgumentError, "wrong type #{spec["type"]}")
      end
      @spec = spec

      if defined? self.class::PARAMS_KEY
        @params = spec[self.class::PARAMS_KEY]
        raise(ArgumentError, "no params") if @params.nil? || @params.empty?
      end
    end

    # @see #initialize
    def self.from_list(triggers, dc)
      if triggers.nil?
        trigger = { "type" => DeploymentConfigConfigChangeTrigger::TYPE }
        return [DeploymentConfigConfigChangeTrigger.new(trigger, dc)]
      end
      triggers.map do |trigger|
        clazz = SUBCLASSES.find { |tc| tc::TYPE == trigger["type"] }
        raise "unknown trigger type #{trigger["type"]}" unless clazz
        clazz.new trigger, dc
      end
    end

    def type
      self.class::TYPE
    end
  end

  class DeploymentConfigImageChangeTrigger < DeploymentConfigTrigger
    TYPE = "ImageChange".freeze
    PARAMS_KEY = "imageChangeParams".freeze

    attr_reader :dc
    private :dc

    # @param spec [Hash] the trigger hash as found within deployment config
    #   triggers array
    # @param dc [DeploymentConfig] the original deployment config
    def initialize(spec, dc)
      super
      @dc = dc
      set_from(dc)
    end

    private def set_from(dc)
      case params.dig("from", "kind")
      when "ImageStreamTag"
        project_name = params.dig("from", "namespace")
        if dc && project_name == dc.project.name
          project = dc.project
        else
          project = Project.new(name: project_name, env: dc.env)
        end
        @from = ImageStreamTag.new(
          name: params.dig("from", "name"),
          project: project
        )
        @from.default_user(dc.default_user(optional: true), optional: true)
      else
        raise "unknown image change trigger from type " \
          "#{params.dig("from", "kind")}"
      end
    end

    def last_image
      image_ref = params['lastTriggeredImage']
      return image_ref ? ImageRef.new(image_ref, dc) : nil
    end
  end

  class DeploymentConfigConfigChangeTrigger < DeploymentConfigTrigger
    TYPE = "ConfigChange".freeze
  end
end
