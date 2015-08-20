# require 'thread'

require 'ostruct' # for TCMSTestCase
require 'json'

require 'common'
require_relative 'tcms'

module CucuShift
  # this is our TCMS test case manager
  class TCMSManager
    include Common::Helper

    attr_accessor :current_test_case, :opts
    # attr_reader :attach_queue

    def initialize(**opts)
      @opts = opts


      # @attach_queue = Queue.new
    end

    ############ test case manager interface methods ############

    def signal(signal, *args)
      case signal
      when :end_of_cases
      when :start_case
        test_case = args[0]
        job = current_job(test_case)
        job.executing!(test_case)
      when :end_case
        test_case = args[0]
        job = current_job(test_case)
        job.completed!(test_case)
        handle_artifacts(job, test_case)
        if job.completed?
          tcms_final_status(job)
          finished_jobs << cucumber_test_cases.delete(job)
        end
      when :finish_before_hook, :finish_after_hook
        test_case = args[0]
        err = args[1]
        if err
          job = current_job(test_case)
          job.force_status = :error
          if signal == :finish_before_hook
            # TODO: make this per test job
            @before_failed = true
          else
            @after_failed = true
          end
        end
      when :at_exit
        # TODO: log any incomplete and ready jobs
      end
    end

    # @param job [TCMSTestCase]
    # @param test_case [Cucumber::Core::Test::Case]
    def handle_artifacts(job, test_case)
      # TODO
    end

    # @param job [TCMSTestCase]
    def tcms_final_status(job)
      # TODO now
    end

    def current_job(test_case)
        job = ready_jobs[0]
        if job.nil? || job.status != :running || !job.matches?(test_case)
          raise "looks like a TCMS manager bug: #{job.inspect}, #{test_case.name}?!"
        end
        return job
    end

    def finished_jobs
      @finished_jobs ||= []
    end

    def after_failed?
      @after_failed
    end

    def before_failed?
      @before_failed
    end

    # @param test_case [Cucumber::Core::Test::Case]
    def push(test_case)
      # WIP pls leave debug statement alone
      require 'pry'
      binding.pry
      job = incomplete_jobs.find { |job| job.matches?(test_case) }
      if job && job.ready? # job may still require more scenarios
        ready_jobs << incomplete_jobs.delete(job)
      elsif job.nil?
        Kernel.puts("skipping #{test_case.location.to_s} for no cases match it")
      end
    end

    # return next cucumber test_case to be executed and sets status to RUNNING
    def next
      # try to set next job to running (already running is ok)
      until ready_jobs.empty? || ready_jobs.first.running?
        unless set_to_running(ready_jobs.first)
          ready_jobs.shift # some other executor running this
        end
      end
      if ready_jobs.empty?
        return nil
      else
        return ready_jobs.first.next_cucumber_test_case
      end
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
      return @tcms ||= TCMS.new(opts[:tcms_opts] || {})
    end

    # @return [Array[ExecutionUnit]>
    # @note TEST_SPEC would be like "run:12356" or "caseruns:123,43,23"
    def incomplete_jobs
      return @incomplete_jobs if @incomplete_jobs

      job = ENV["TCMS_SPEC"] || opts[:tcms_spec]
      unless job
        raise "don't know what to execute, please specify TCMS execution specification in TCMS_SPEC"
      end
      type, garbage, items = job.partition(/s?:/)
      items = items.split(',').map { |i| Integer(i) }

      case type
      when "case"
        @incomplete_jobs = jobs_from_case_list(tcms.get_cases2(items))
      when "run"
        @incomplete_jobs =
          jobs_from_case_list(tcms.get_runs_cases(items))
      when "caserun"
        @incomplete_jobs = jobs_from_case_list(tcms.get_caseruns(items))
      end

      return @incomplete_jobs
    end


    # @param case_list [Array<Hash>] this basically takes cases from TCMS
    #   optionally intermixed with test case run fields
    def jobs_from_case_list(case_list)
      jobs = case_list.map { |c| TCMSTestCaseRun.new(c) }
      jobs.select! { |c| c.runnable? }
      return jobs
    end

    # @param test_case [Hash] a hash tracking test case execution progress
    #def finalize(test_case)
    #  return unless test_case # no test cases executed yet
    #
    #  # attach any scenario artifacts
    #  manager.custom_formatters.each(&:process_scenario_log)
    #
    #  # TODO: ???
    #end

    # represents the TCMS test case with list of scenario specifications to
    #   execute and status of everything related
    class TCMSTestCaseRun < OpenStruct

      def runnable?
        auto? && confirmed? && scenario_specification
      end

      # @param test_case [Cucumber::Core::Test::Case]
      def matches?(test_case)
        # fast match if we already own that scenario
        return true if cucumber_test_cases.any? { |c|
          c.location.to_s == test_case.location.to_s
        }

        # compare filename and scenario name
        if (test_case.location.file != scenario_specification[:file]) ||
          (
            test_case.keyword.length == "Scenario Outline".length &&
            test_case.source[-3].name != scenario_specification[:scenario_name]
          ) ||
          ( test_case.keyword.length == "Scenario".length &&
            test_case.name.start_with != scenario_specification[:scenario_name]
          )
            return false # surely we do not match
        end

        if test_case.keyword.length == "Scenario".length &&
            (
              scenario_specification[:example] ||
              scenario_specification[:examples_table]
            )
          # we expect an outline but have simple scenario
          Kernel.puts("case #{self.case_id} mismatch with scenario type, will never run")
          return false
        elsif test_case.keyword.length == "Scenario".length
          # single scenario to be run
          cucumber_test_cases << test_case
          @ready = true
          return true
        elsif scenario_specification[:example]
          # we want single example of outline to be run
          unless test_case.source.last.class.to_s.end_with?("::Row")
            Kernel.puts("case #{self.case_id} vs #{test_case.location.to_s}; cucumber API changed? Source is not a Row?")
            return false
          end

          if test_case.source.last.instance_variable_get(:@data) ==
              scenario_specification[:example]
            cucumber_test_cases << test_case
            @ready = true
            return true
          else
            return false
          end
        elsif scenario_specification[:examples_table]
          # we want a whole examples table to be run
          unless test_case.source.last.class.to_s.end_with?("::Row") &&
              test_case.source[-2].class.to_s.end_with?("::ExamplesTable")
            Kernel.puts("case #{self.case_id} vs #{test_case.location.to_s}; cucumber API changed?")
            return false
          end

          examples_table = test_case.source[-2]
          if examples_table.name == scenario_specification[:examples_table]
            cucumber_test_cases << test_case
            @ready = cucumber_test_cases.size == examples_table.example_rows.size
            return true
          else
            return false
          end
        elsif scenario_specification[:example].nil? &&
          scenario_specification[:examples_table].nil?
          # we want a whole outline to be run
          unless test_case.source.last.class.to_s.end_with?("::Row") &&
              test_case.source[-2].class.to_s.end_with?("::ExamplesTable") &&
              test_case.source[-3].class.to_s.end_with?("ScenarioOutline")
            Kernel.puts("case #{self.case_id} vs #{test_case.location.to_s}; cucumber API changed?")
            return false
          end

          outline = test_case.source[-3]
          cucumber_test_cases << test_case
          @ready = cucumber_test_cases.size == test_case.source[-3].examples_tables.reduce(0) { |sum, t| sum + t.example_rows.size }
          return true
        else
          raise "we should never be here, #{self.case_id}, #{test_case.location.to_s}"
        end
      end

      def cucumber_test_cases
        @cucumber_test_cases ||= []
      end

      def scenario_specification
        return @scenario_specification if defined?(@scenario_specification)

        @scenario_specification = nil

        if self.script.nil? || self.script.empty?
          Kernel.puts "Skipping #{self.case_run_id} with empty script."
          return nil
        end

        res = {}

        begin
          parsed_script = JSON.load(self.script)
          unless parsed_script["ruby"]
            Kernel.puts "Skipping #{self.case_run_id} with no ruby element."
            return nil
          end

          res[:file], nothing, res[:scenario_name] = parsed_script["ruby"].partition(':')

          # normalize file used
          unless res[:scenario_name].start_with?("features/", File.basename(PRIVATE_DIR), PRIVATE_DIR)
            res[:scenario_name] = "features/" + res[:scenario_name]
          end

          if self.arguments && !self.arguments.empty?
            parsed_args = JSON.load(self.arguments)
            if !parsed_args.kind_of?(Hash)
              Kernel.puts "Skipping #{self.case_run_id} with faux arguments."
              return nil
            end
            if parsed_args.size == 1 && parsed_args.keys[0] == "Examples"
              res[:examples_table] = parsed_args.values[0]
            else
              res[:example] = parsed_args
            end
          end
        rescue => e
          Kernel.puts "Skipping #{self.case_run_id}: #{e}"
          return nil
        end

        @scenario_specification = res
        return res
      end

      def auto?
        self.is_automated != 0
      end

      def confirmed?
        self.case_status_id == 2
        #self.case_status == "CONFIRMED"
      end

      def ready?
        @ready
      end

      # @param test_case [Cucumber::Core::Test::Case]
      def completed!(test_case)
        res = cucumber_test_cases.find { |tc| tc.location.to_s ==
                                              test_case.location.to_s}
        unless res
          raise "how on earth we were told test case is completed when we do not own it: #{test_case.location}"
        end

        cucumber_test_cases.delete(res)

        # TODO: set completed, forse status and status
      end
    end
  end
end
