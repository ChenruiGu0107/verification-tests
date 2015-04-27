require 'singleton'

module CucuShift
  # @note this class allows accessing global test execution state
  #       get the singleton object by calling Manager.instance
  class Manager
    include Singleton
    attr_accessor :world

    def initialize
      @world = nil

      @environments = []
      # @logger = ...
      # @browsers = ...
    end
  end
end
