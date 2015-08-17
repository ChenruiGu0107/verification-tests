# Use this step to register clean up steps to be executed in the AfterHook
#   regardless of scenario success status.
#   Embedded table delimiter is '!'
Then /^I register clean\-up steps:$/ do |table|
  if table.respond_to? :lines
    # multi-line string
    data = table.lines
  else
    # Cucumber Table
    data = []
    table.raw.each{ |row| data << row.last unless row.last.strip.empty? }
  end

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
          teardown_add {
            logger.info("Step: " << _step_name)
            step _step_name
          }
        else
          _params = params.join("\n")
          teardown_add {
            logger.info("Step: #{_step_name}\n#{_params}")
            step _step_name, table(_params)
          }
        end
      }.call
      params = []
      step_name = ''
    end
  end
end
