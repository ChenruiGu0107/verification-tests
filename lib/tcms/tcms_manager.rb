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

    ############ test case manager interface methods ############

    def signal(signal, *args)
    end

    def push(test_case)
      @tcs||=[]
      @tcs << test_case
    end

    def shift
      @tcs.shift
    end

    def attach_logs(caserunid, *urls)
    end

    # @param scenario [Hash] with keys :name, :file_colon_line, :arg
    # @param dir [String] to be attached to test case run; dir emptied on return
    def attach_dir(dir)
      require 'pry'
      binding.pry
    end

    def before_failed?
    end

    def after_failed?
    end

    ############ test case manager interface methods end ############

    private

    def tcms
      return @tcms if @tcms

      if opts[:user] && opts[:password]
        @tcms = TCMS.new(nil, nil, opts)
      else
        @tcms = TCMS.get_tcms(opts)
      end
      return @tcms
    end

    # @param test_case [Hash] a hash tracking test case execution progress
    def finalize(test_case)
      return unless test_case # no test cases executed yet

      # attach any scenario artifacts
      manager.custom_formatters.each(&:process_scenario_log)

      # TODO: ???
    end
  end
end
