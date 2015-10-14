# Use this step to register clean up steps to be executed in the AfterHook
#   regardless of scenario success status.
# Clean-up steps are registered in reverse order to make first step execute
#   first as test developer would expect. Still separate register step
#   invocations will execute in reverse order as designed. We in general run
#   clean-up steps in reverse order so that environment for resource clean-up
#   is same as on creation.
# Embedded table delimiter is '!' if '|' not used
Then /^I register clean\-up steps:$/ do |table|
  if table.respond_to? :lines
    # multi-line string
    data = table.lines
  else
    # Cucumber Table
    data = []
    table.raw.each{ |row| data << row.last unless row.last.strip.empty? }
  end

  step_list = []
  step_name = ''
  params = []
  data.each_with_index do |line, index|
    if line.strip.start_with?('!')
      params << [line.gsub('!','|')]
    elsif line.strip.start_with?('|')
      # with multiline string we can use '|'
      params << line
    else
      step_name = line
    end
    next_is_not_param = data[index+1].nil? ||
                        !data[index+1].strip.start_with?('!','|')
    if next_is_not_param
      raise "step not specified" if step_name.strip.empty?

      # then we should add the step to tierdown
      # But do it within a proc to have separately scoped variable for each step
      #   otherwise we end up with all lambdas using the same `step_name` and
      #   `params` variables. That means all lambdas defined within this step
      #   invocation, because lambdas and procs inherit binding context.
      #
      proc {
        _step_name = step_name
        if params.empty?
          step_list.unshift proc {
            logger.info("Step: " << _step_name)
            step _step_name
          }
        else
          _params = params.join("\n")
          step_list.unshift proc {
            logger.info("Step: #{_step_name}\n#{_params}")
            step _step_name, table(_params)
          }
        end
      }.call
      params = []
      step_name = ''
    end
  end

  teardown_add *step_list
end
