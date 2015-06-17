require 'singleton'

require 'log'
require 'configuration'
require 'environment_manager'
# should not require 'common'

module CucuShift
  # @note this class allows accessing global test execution state.
  #       Get the singleton object by calling Manager.instance.
  #       Manager should point always at the correct manager implementation.
  class DefaultManager
    include Singleton
    attr_accessor :world
    # attr_reader :environments

    def initialize
      @world = nil

      # @browsers = ...
    end

    def clean_up
      @environments.clean_up
      @world = nil
    end

    def environments
      @environments ||= EnvironmentManager.new
    end

    def logger
      @logger ||= Logger.new
    end

    def conf
      @conf ||= Configuration.new
    end

    def self.conf
      self.instance.conf
    end
  end
end
