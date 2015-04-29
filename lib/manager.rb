require 'singleton'

module CucuShift
  # @note this class allows accessing global test execution state
  #       get the singleton object by calling Manager.instance
  class DefaultManager
    include Singleton
    attr_accessor :world

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
  end
end
