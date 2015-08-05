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
    attr_reader :temp_resources, :test_case_manager

    def initialize
      @world = nil
      @temp_resources = []

      # # @browsers = ...
    end

    def clean_up
      @environments.clean_up if @environments
      @temp_resources.each(&:clean_up)
      @temp_resources.clear
      Host.localhost.clean_up
      @world = nil
    end
    alias after_scenario clean_up

    def at_exit
      # test_case_manager.at_exit # call in env.rb for visibility

      # perform clean up in case of abrupt interruption (ctrl+c)
      #   duplicate call after proper clean up in After hook should not hurt
      clean_up
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

    def init_test_case_manager(cucumbler_config)
      tc_mngr = ENV['CUCUSHIFT_TEST_CASE_MANAGER'] || conf[:test_case_manager]
      if tc_mngr
        tc_mngr_obj = conf.get_custom_class_instance(tc_mngr)

        ## register our test case manager
        @test_case_manager = tc_mngr_obj

        ## add our test case manager notifyer to the filter chain
        require 'test_case_manager_filter'
        cucumbler_config.filters << TestCaseManagerFilter.new(tc_mngr_obj)
      else
        # dummy class to always return true and never raise
        @test_case_manager = Class.new do
          def method_missing(m, *args, &block)
            true
          end
        end.new
      end
    end
  end
end
