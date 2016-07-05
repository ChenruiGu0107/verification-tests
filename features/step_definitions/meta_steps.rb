# Use this step to register clean up steps to be executed in the AfterHook
#   regardless of scenario success status.
# Clean-up steps are registered in reverse order to make first step execute
#   first as test developer would expect. Still separate register step
#   invocations will execute in reverse order as designed. We in general run
#   clean-up steps in reverse order so that environment for resource clean-up
#   is same as on creation.
# see #to_step_procs
Then /^I register clean\-up steps:$/ do |table|
  teardown_add *to_step_procs(table)
end

# put usually at beginning of scenario to execute env consistency checks
# and then those checks will be execute as last clean-up to check env is back up
# @note one issue here is that transformation will take place when defining
#   steps, so you may need the step `the expression should be true>` as a
#   workaround
Then /^system verification steps are used:$/ do |table|
  steps = to_step_procs(table)
  steps.reverse_each { |s| s.call }
  teardown_add *steps
end

# repeat steps specified in a multi-line string until they pass (that means
#   until they execute without raising an error)
Given /^I wait(?: up to ([0-9]+) seconds)? for the steps to pass:$/ do |seconds, steps_string|
  begin
    logger.dedup_start
    seconds = Integer(seconds) rescue 60
    repetitions = 0
    error = nil
    success = wait_for(seconds) {
      repetitions += 1
      # this message needs to be disabled as it defeats deduping
      # logger.info("Beginning step repetition: #{repetitions}")
      begin
        steps steps_string
        true
      rescue => e
        error = e
        false
      end
    }

    raise error unless success
  ensure
    logger.dedup_flush
  end
end

# repeat steps x times in a multi-line string
Given /^I run the steps (\d+) times:$/ do |num, steps_string|
  begin
    logger.dedup_start
    (1..Integer(num)).each {
      steps steps_string
    }
  ensure
    logger.dedup_flush
  end
end
