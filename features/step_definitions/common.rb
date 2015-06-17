When /^I switch to(?: the)? ([a-z]+) user$/ do |who|
  @user = user(word_to_num(who))
end

Then /^the step should( not)? (succeed|fail)$/ do |negative, outcome|
  if ((outcome == "succeed") ^ negative ) != @result[:success]
    raise "the step #{@result[:success] ? "succeeded" : "failed"}"
  end
end

When /^I run the :(.*?) client command$/ do |yaml_key|
  yaml_key.sub!(/^:/,'')
  @result = user.cli_exec(yaml_key.to_sym, {})
end

When /^I run the :([a-z_]*?)( background)? client command with:$/ do |yaml_key, background, table|
  options = {}

  # here we allow multiple options from same type
  table.raw.each do |key, value|
    key = str_to_sym key
    case
    when options.has_key?(key) && !options[key].kind_of?(Array)
      options[key] = [options[key], value]
    when options.has_key?(key)
      options[key] << value
    else
      options[key] = value
    end
  end

  if background
    raise 'cli running background commands not supported yet'
  else
    @result = user.cli_exec(yaml_key.to_sym, options)
  end
end

When /^I run the :([a-z_]*?)( background)? admin command with:$/ do |yaml_key, background, table|
  options = {}

  # here we allow multiple options from same type
  table.raw.each do |key, value|
    key = str_to_sym key
    case
    when options.has_key?(key) && !options[key].kind_of?(Array)
      options[key] = [options[key], value]
    when options.has_key?(key)
      options[key] << value
    else
      options[key] = value
    end
  end

  if background
    raise 'cli running background commands not supported yet'
  else
    @result = env.admin_cli_executor.exec(yaml_key.to_sym, options)
  end
end

# @param [String] negative Catches "not" if it is present
# @param [Table] Array of the strings we are searching for
# @note Checks whether the output contains/(does not contain) any of the
# strings or regular expressions listed in the given table
Then /^the( all)? outputs?( by order)? should( not)? (contain|match)(?: "(\d+)" times)?:/ do |all, in_order, negative, match_type, times, table|
  raise "incompatible options 'times' and 'by order'" if times && in_order

  if all
    case
    when @result.kind_of?(Array)
      outputs = @result.map {|r| r[:response].to_s}
    when @result[:response].kind_of?(Array)
      outputs = @result[:response].map(&:to_s)
    else
      outputs = [ @result[:response].to_s ]
    end
  else
    outputs = [ @result[:response].to_s ]
  end

  if match_type == "match"
    patterns = table.raw.map {|p| Regexp.new(p.first)}
  else
    patterns = table.raw.map(&:first)
  end

  times = Integer(times) if times

  outputs.each do |o|
    case
    when times
      patterns.each do |p|
        found_times = o.scan(p).size
        if (found_times == times) ^ negative
          raise "found pattern #{found_times} times with baseline #{times} times: #{p}"
        end
      end
    when in_order
      raise "by order not implemented yet"
      #o = o.dup
      #patterns.each do |p|
      #  if m = o.match(p)
      #  else
      #  end
      #end
    else
      patterns.each do |p|
        if p.kind_of? Regexp
          found = o.match p
        else
          found = o.include? p
        end
        raise "pattern#{negative ? "" : " not"} found: #{p}" unless found ^ negative
      end
    end
  end
end

Given /^([0-9]+?) seconds have passed$/ do |num|
  sleep(num.to_i)
end
