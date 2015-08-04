require 'cucumber/core/filter'

module CucuShift
  # this class lives throughout the whole test execution
  #  it passes filter events to the Test Case Manager
  TestCaseManagerFilter = Cucumber::Core::Filter.new(:tc_manager) do
    # called upon new scenario
    def test_case(test_case)
      if tc_manager.should_run? test_case
        super
      else
        return self
      end

      # example fiddling with steps
      #activated_steps = test_case.test_steps.map do |test_step|
      #  test_step.with_action { }
      #end
      #test_case.with_steps(activated_steps).describe_to receiver

      # super source at time of writing
      # test_case.describe_to receiver
      # return self
    end

    # called at end of execution to print summary
    def done
      tc_manager.all_test_cases_completed

      super
      # super source at time of writing
      # receiver.done
      # return self
    end
  end
end
