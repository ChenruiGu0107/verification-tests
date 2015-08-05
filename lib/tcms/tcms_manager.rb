# require 'thread'

require 'common'
require_relative 'tcms'

module CucuShift
  # this is our TCMS test case manager
  class TCMSManager
    include Common::Helper

    attr_accessor :current_test_case
    # attr_reader :attach_queue

    def initialize(**opts)
      # @attach_queue = Queue.new
    end

    def tcms
      return @tcms if @tcms

      if opts[:user] && opts[:password]
        @tcms = TCMS.new(nil, nil, opts)
      else
        @tcms = TCMS.get_tcms(opts)
      end
      return @tcms
    end

    def attach_logs(caserunid, *urls)
    end

    def should_run?(test_case)
      # Fist thing, lets finalize operation with previous test_case
      finalize(current_test_case)

      self.current_test_case = test_case
      logger.info("Skipping scenario: " << test_case.name)
      true
    end

    def all_test_cases_completed
      finalize(current_test_case)
    end

    # @param test_case [Hash] a hash tracking test case execution progress
    def finalize(test_case)
      return unless test_case # no test cases executed yet

      # attach any scenario artifacts
      manager.custom_formatters.each(&:process_scenario_log)

      # TODO: ???
    end

    # @param scenario [Hash] with keys :name, :file_colon_line, :arg
    # @param dir [String] to be attached to test case run; dir emptied on return
    def attach_dir(dir)
      require 'pry'
      binding.pry
    end

    ## TODO: implement class and remove noop fallback
    def method_missing(m, *args, &block)
      #puts "There's no method called #{m} here -- please try again."
      # require 'pry'
      #binding.pry
    end

  end
end
