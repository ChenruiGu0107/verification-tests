When /^I perform the :(.*?) web( console)? action with:$/ do |action, console, table|
  if console
    # OpenShift web console actions should not depend on last used browser but
    #   current user we are switched to
    cache_browser(user.webconsole_executor)
    @result = user.webconsole_exec(action.to_sym, opts_array_to_hash(table.raw))
  else
    @result = browser.run_action(action.to_sym, opts_array_to_hash(table.raw))
  end
end

#run web action without parameters
When /^I run the :(.+?) web( console)? action$/ do |action, console|
  if console
    cache_browser(user.webconsole_executor)
    @result = user.webconsole_exec(action.to_sym)
  else
    @result = browser.run_action(action.to_sym)
  end
end

# @precondition a `browser` object
When /^I access the "(.*?)" (?:path|url) in the web (?:console|browser)$/ do |url|
  @result = browser.handle_url(url)
end

Given /^I login via web console$/ do
  step "I run the :null web console action"

  unless @result[:success]
    logger.error(@result[:response])
    raise "#{user.name} login via web console failed"
  end
end

# @author cryan@redhat.com
# @params the table is to be populated with values from the initialization
# method in the web4cucumber.rb file. Below, you will see samples from rules
# and base_url, but other values can be added also.
# @notes this creates a separate browser instance, different from the console
# browser previously used. Use this step for non-console cases.
# *NOTE* be sure to include the protocol before the base URL in your table,
# for example, http:// or https://, otherwise this will generate a URI error.
Given /^I have a browser with:$/ do |table|
  init_params = opts_array_to_hash(table.raw)
  if init_params[:rules].kind_of? Array
    init_params[:rules].map! { |r| expand_path(r) }
  else
    init_params[:rules] = [expand_path(init_params[:rules])]
  end
  if conf[:browser]
    init_params[:browser_type] ||= conf[:browser].to_sym
  end
  init_params[:logger] = logger
  browser = Web4Cucumber.new(**init_params)
  cache_browser(browser)
  teardown_add { @result = browser.finalize }
end

Given /^I open (registry|accountant) console in a browser$/ do |console|
  base_rules = CucuShift::WebConsoleExecutor::RULES_DIR + "/base/"
  snippets_dir = CucuShift::WebConsoleExecutor::SNIPPETS_DIR
  case console
  when "registry"
    step "default registry-console route is stored in the :reg_console_url clipboard"
    step "I have a browser with:", table(%{
      | rules        | #{base_rules}                     |
      | rules        | lib/rules/web/registry_console/   |
      | base_url     | https://<%= cb.reg_console_url %> |
      | snippets_dir | #{snippets_dir}                   |
    })
    @result = browser.run_action(:goto_registry_console)
    step 'I perform login to registry console in the browser'
  when "accountant"
    step "evaluation of `env.web_console_url[/(?<=\\.).*(?=\.openshift)/]` is stored in the :acc_console_url clipboard"
    step "I have a browser with:", table(%{
      | rules        | #{base_rules}                                           |
      | rules        | lib/rules/web/accountant_console/                       |
      | base_url     | https://account.<%= cb.acc_console_url %>.openshift.com |
      | snippets_dir | #{snippets_dir}                                         |
    })
    if user.password?
      @result = browser.run_action(:login_acc_console,
                          username: user.name,
                          password: user.password)
    else
      raise "cannot login to accountant console via token"
    end
  else
    raise "Unknown console type"
  end
end

When /^I perform login to registry console in the browser$/ do
  @result = if user.password?
    browser.run_action(:login_reg_console,
                       username: user.name,
                       password: user.password)
  else
    browser.run_action(:login_token_reg_console,
                       token: user.get_bearer_token.token)
  end
end

# @precondition a `browser` object
# get element html or attribute value
# Provide element selector in the step table using key/value pairs, e.g.
# And I get the "disabled" attribute of the "button" web element with:
#   | type | submit |
When /^I get the (?:"([^"]*)" attribute|content) of the "([^"]*)" web element:$/ do |attribute, element_type, table|
  selector = opts_array_to_hash(table.raw)
  #Collections.map_hash!(selector) do |key, value|
  #  [ key, YAML.load(value) ]
  #end

  found_elements = browser.get_visible_elements(type:     element_type,
                                                selector: selector)

  if found_elements.empty?
    raise "can not find this #{element_type} element with #{selector}"
  else
    if attribute
      value = found_elements.last.attribute_value(attribute)
    else
      value = found_elements.last.html
    end
    @result = {
      response: value,
      success: true,
      exitstatus: -1,
      instruction: "get the #{attribute ? attribute + ' attibute' : ' content'} of the #{element_type} element with selector: #{selector}"
    }
  end
end

# @precondition a `browser` object
When /^I get the html of the web page$/ do
  @result = {
    response: browser.page_html,
    success: true,
    instruction: "read the HTML of the currently opened web page",
    exitstatus: -1
  }
end

# @precondition a `browser` object
# useful for web common "click" action
When /^I click the following "([^"]*)" element:$/ do |element_type, table|
  selector = opts_array_to_hash(table.raw)
  @result = browser.handle_element({type: element_type, selector: selector, op: "click"})
end

# @precondition a `browser` object
# return the text of html body
When /^I get the visible text on web html page$/ do
  @result = {
    response: browser.text,
    success: true,
    instruction: "read the visible body TEXT of the currently opened web page",
    exitstatus: -1
  }
end

# repeat doing web action until success,useful for waiting resource to become visible and available on web
Given /^I wait(?: (\d+) seconds)? for the :(.+?) web( console)? action to succeed with:$/ do |time, web_action, console, table|
  time = time ? time.to_i : 15 * 60
  if console
    step_string = "I perform the :#{web_action} web console action with:"
  else
    step_string = "I perform the :#{web_action} web action with:"
  end
  success = wait_for(time) {
    step step_string, table
    break true if @result[:success]
  }
  @result[:success] = success
  unless @result[:success]
    raise "can not wait the :#{web_action} web action to succeed"
  end
end

# @precondition a `browser` object
Given /^I wait(?: (\d+) seconds)? for the title of the web browser to match "(.+)"$/ do |time, pattern|
  time = time ? time.to_i : 10
  reg = Regexp.new(pattern)
  success = wait_for(time) {
    reg =~ browser.title
  }
  unless success
    raise "browser title #{browser.title} did not match #{pattern} within timeout"
  end
end


# @notes used for swithing browser window,e.g. do some action in pop-up window
# @window_spec is something like,":url=>console\.html"(need escape here,part of url),":title=>some info"(part of title)
When /^I perform the :(.*?) web( console)? action in "([^"]+)" window with:$/ do |action, console, window_spec, table|
  window_selector = opts_array_to_hash([window_spec.split("=>")])
  window_selector.each{ |key,value| window_selector[key] = Regexp.new(value) }
  if console
    cache_browser(user.webconsole_executor)
    webexecutor = user.webconsole_executor
  else
    webexecutor = browser
  end
  if webexecutor.browser.window(window_selector).exists?
    webexecutor.browser.window(window_selector).use do
      @result = webexecutor.run_action(action.to_sym, opts_array_to_hash(table.raw))
    end
  else
    for win in webexecutor.browser.windows
      logger.warn("window title: #{win.title}, window url: #{win.url}")
    end
    raise "can not switch to the specific window"
  end
end

Given /^I open metrics console in the browser$/ do
  step %Q/I store the metrics url to the clipboard/
  step %Q/I access the "<%= cb.metrics_url %>" url in the web browser/
end
