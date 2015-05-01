require 'singleton'

require 'log'
require 'configuration'
# should not require 'common'

module CucuShift
  # @note this class allows accessing global test execution state.
  #       Get the singleton object by calling Manager.instance.
  #       Manager should point always at the correct manager implementation.
  class DefaultManager
    include Singleton
    attr_accessor :world
    # attr_reader :logger

    def initialize
      @world = nil

      @environments = []
      # @logger = ...
      # @browsers = ...
    end

    def clean_up
      @environments.each {|e| e.clean_up}
      @environments.clear
      @world = nil
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
