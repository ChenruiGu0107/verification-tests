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
  if background
    raise 'cli running background commands not supported yet'
  else
    @result = user.cli_exec(yaml_key.to_sym, opts_array_process(table.raw))
  end
end

When /^I run the :([a-z_]*?)( background)? admin command with:$/ do |yaml_key, background, table|
  if background
    raise 'cli running background commands not supported yet'
  else
    @result = env.admin_cli_executor.exec(yaml_key.to_sym, opts_array_process(table.raw))
  end
end

When /^I perform the :([a-z_]*?) rest request$/ do |yaml_key|
  @result = env.rest_request_executor.exec(user: user, req: yaml_key.to_sym)
end

When /^I perform the :([a-z_]*?) rest request with:$/ do |yaml_key, table|
  @result = user.rest_request(yaml_key.to_sym, opts_array_to_hash(table.raw))
end

# @param [String] negative Catches "not" if it is present
# @param [Table] Array of the strings we are searching for
# @note Checks whether the output contains/(does not contain) any of the
# strings or regular expressions listed in the given table
Then /^(the|all)? outputs?( by order)? should( not)? (contain|match)(?: (\d+) times)?:$/ do |all, in_order, negative, match_type, times, table|
  raise "incompatible options 'times' and 'by order'" if times && in_order

  if all == "all"
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
          found = !! o.match(p)
        else
          found = o.include? p
        end
        raise "pattern#{negative ? "" : " not"} found: #{p}" unless found ^ negative
      end
    end
  end
end

# @param [String] negative Catches "not" if it is present
# @param [Table] Array of the strings we are searching for
# @note Checks whether the output contains/(does not contain) any of the
# strings or regular expressions listed in the given table
Then /^(the|all)? outputs?( by order)? should( not)? (contain|match) "(.+)"(?: (\d+) times)?$/ do |all, in_order, negative, match_type, pattern, times|
  step "#{all} output#{in_order} should#{negative} #{match_type}#{times}:",
    table(%{|#{pattern}|})
end

Given /^([0-9]+?) seconds have passed$/ do |num|
  sleep(num.to_i)
end

Given /^evaluation of `(.+?)` is stored in the(?: :(.*?))? clipboard$/ do |what, clipboard_name|
  clipboard_name = 'tmp' unless clipboard_name
  cb[clipboard_name] = eval(what)
end

Then /^(?:the )?expression should be true> (.+)$/ do |expr|
  res = eval expr
  unless res
    raise "expression \"#{expr}\" returned non-positive status: #{res}"
  end
end

Given /^an?(?: (\d+) characters?)? random string(?: of type :(.*?))? is (?:saved|stored) into the(?: :(.*?))? clipboard$/ do |chars, rand_type, clipboard_name|
  chars = 8 unless chars
  rand_type = rand_type.to_sym unless rand_type.nil?
  rand_str = rand_str(chars.to_i, rand_type)
  clipboard_name = 'tmp' unless clipboard_name
  cb[clipboard_name] = rand_str
end

