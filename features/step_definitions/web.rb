When /^I perform the :(.*?) web( console)? action with:$/ do |action, console, table|
  if console
    # OpenShift web console actions should not depend on last used browser but
    #   current user we are switched to
    cache_browser(user.webconsole_executor)
    @result = user.webconsole_exec(action.to_sym, opts_array_to_hash(table.raw))
  else
    browser.exec(action.to_sym, opts_array_to_hash(table.raw))
  end
end

#run web action without parameters
When /^I run the :(.+?) web( console)? action$/ do |action, console|
  if console
    cache_browser(user.webconsole_executor)
    @result = user.webconsole_exec(action.to_sym)
  else
    browser.exec(action.to_sym)
  end
end

When /^I access the "(.*?)" path in the web (?:console|browser)$/ do |url|
  @result = browser.handle_url(url)
end

Given /^I login via web console$/ do
  step "I perform the :login web console action with:",
    table([["username", user.name], ["password", user.password]])

  unless @result[:success]
    logger.error(@result[:response])
    raise "#{user.name} login via web console failed"
  end
end

# get element html or attribute value
# Provide element selector in the step table using key/value pairs, e.g.
# And I get the "disabled" attribute of the "button" web element with:
#   | type | submit |
When /^I get the (?:"([^"]*)" attribute|content) of the "([^"]*)" web element:$/ do |attribute, element_type, table|
  selector = opts_array_to_hash(table.raw)
  #Collections.map_hash!(selector) do |key, value|
  #  [ key, YAML.load(value) ]
  #end

  found_elements = browser.get_visible_elements(element_type, selector)

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

When /^I get the html of the web page$/ do
  @result = {
    response: browser.page_html,
    success: true,
    instruction: "read the HTML of the currently opened web page",
    exitstatus: -1
  }
end

#useful for web common "click" action
When /^I click the following "([^"]*)" element:$/ do |element_type, table|
  selector = opts_array_to_hash(table.raw)
  @result = browser.handle_element({type: element_type, selector: selector, op: "click"})
end
