require 'json'
require 'yaml'

Then /^the step should( not)? (succeed|fail)$/ do |negative, outcome|
  if ((outcome == "succeed") ^ negative ) != @result[:success]
    raise "the step #{@result[:success] ? "succeeded" : "failed"}"
  end
end

# @note This step checks whether or not a step successfully timed out
Then /^the step should have timed out$/ do
  raise "The step did not timeout" unless @result[:timeout]
end

When /^I run the :(.*?) client command$/ do |yaml_key|
  yaml_key.sub!(/^:/,'')
  @result = user.cli_exec(yaml_key.to_sym, {})
end

When /^I run the :([a-z_]*?)( background)? client command with:$/ do |yaml_key, background, table|
  if background
    @result = user.cli_exec(
      yaml_key.to_sym,
      opts_array_process(table.raw) << [ :_background, true ]
    )
    @bg_rulesresults << @result
    @bg_processes << @result[:process_object]
  else
    @result = user.cli_exec(yaml_key.to_sym, opts_array_process(table.raw))
  end
end

When /^I run the :([a-z_]*?)( background)? admin command$/ do |yaml_key, background|
  step "I run the :#{yaml_key}#{background} admin command with:",
    table("|dummy|:false|")
end

When /^I run the :([a-z_]*?)( background)? admin command with:$/ do |yaml_key, background, table|
  ensure_admin_tagged

  if background
    @result = env.admin_cli_executor.exec(
      yaml_key.to_sym,
      opts_array_process(table.raw) << [ :_background, true ]
    )
    @bg_rulesresults << @result
    @bg_processes << @result[:process_object]
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
        unless (found_times == times) ^ negative
          raise "found pattern #{found_times} times with baseline #{times} times: #{p}"
        end
      end
    when in_order
      i = 0
      pattern = "nil"
      found = false
      patterns.each do |p|
        pattern = p
        if p.kind_of? Regexp
          match = p.match(o, i)
          if match
            found = true
            i = match.end(0)
          else
            found = false
            break
          end
        else
          match = o.index(p, i)
          if match
            found = true
            i = match + p.size
          else
            found = false
            break
          end
        end
      end
      if !found && !negative
        raise "pattern #{pattern} not found in specified order"
      elsif found && negative
        raise "all patterns found in specified order"
      end
    else
      patterns.each do |p|
        if p.kind_of? Regexp
          found = !!o.match(p)
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
    table([[pattern]])
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

Given /^the output is parsed as (YAML|JSON)$/ do |format|
  case format
  when "YAML"
    @result[:parsed] = YAML.load @result[:response]
  when "JSON"
    @result[:parsed] = JSON.load @result[:response]
  else
    raise "unknown format: #{format}"
  end
end

# this step basically wraps around the steps we use for simulating 'oc edit <resource_name'  which includes the following steps:
# #   1.  When I run the :get client command with:
#       | resource      | dc |
#       | resource_name | hooks |
#       | o             | yaml |
#     And I save the output to file>hooks.yaml
#     And I replace lines in "hooks.yaml":
#       | 200 | 10 |
#       | latestVersion: 1 | latestVersion: 2 |
#     When I run the :replace client command with:
#       | f      | hooks.yaml |
#  So the output file name will be hard-coded to 'tmp_out.yaml', we still need to
#  supply the resouce_name and the lines we are replacing
Given /^I replace resource "([^"]+)" named "([^"]+)"(?: saving edit to "([^"]+)")?:$/ do |resource, resource_name, filename,table |
  filename = "edit_resource.yaml" if filename.nil?
  step %Q/I run the :get client command with:/, table(%{
    | resource | #{resource} |
    | resource_name |  #{resource_name} |
    | o | yaml |
    })
  step %Q/the step should succeed/
  step %Q/I save the output to file>#{filename}/
  step %Q/I replace lines in "#{filename}":/, table
  step %Q/I run the :replace client command with:/, table(%{
    | f | #{filename} |
    })
end

# wrapper around  oc logs, keep executing the command until we have an non-empty response
# There are few occassion that the 'oc logs' cmd returned empty response
#   this step should address those situations
Given /^I collect the deployment log for pod "(.+)" until it disappears$/ do |pod_name|
  opts = {pod_name: pod_name}
  res_cache = {}
  res = {}
  seconds = 15 * 60   # just put a timeout so we don't hang there indefintely
  success = wait_for(seconds) {
    res = user.cli_exec(:logs, **opts)
    if res[:response].include? 'not found'
      # the deploy pod has disappeared which mean we are done waiting.
      break
    else #
      res_cache = res
    end
  }
  res_cache ||= res
  res_cache[:success] = success
  @result  = res_cache
end

# When applying "oc delete" on one resource, the resource may take some time to
# terminate, so use this step to wait for its dispapearing.
Given /^I wait for the resource "(.+)" named "(.+)" to disappear$/ do |resource_type, resource_name|
  opts = {resource_name: resource_name, resource: resource_type}
  res = {}
  seconds = 15 * 60   # just put a timeout so we don't hang there indefintely
  success = wait_for(seconds) {
    res = user.cli_exec(:get, **opts)
    if res[:response].include? 'not found'
      # the resource has terminated which means we are done waiting.
      break true
    end
  }
  res[:success] = success
  @result  = res
  unless @result[:success]
    logger.error(@result[:response])
    raise "#{resource_name} #{resource_type} did not terminate"
  end
end

# repeat doing web action until success,useful for waiting resource to become visible and available on web
Given /^I wait(?: (\d+) seconds)? for the :(.+?) web console action to succeed with:$/ do |time, web_action, table|
  time = time ? time.to_i : 120
  success = wait_for(time) {
    step "I perform the :#{web_action} web console action with:",table
    break true if @result[:success]
  }
  @result[:success] = success
  unless @result[:success]
    raise "can not wait the :#{web_action} web action to succeed"
  end
end
