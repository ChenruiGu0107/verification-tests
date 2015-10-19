When /^I access the "(.*?)" path in web console$/ do |url|
  @result = web_browser.handle_url(url)
end

Given /^I login via web console$/ do
  @result = web_browser.run_action(:login, username: user.name, password: user.password)

  unless @result[:success]
    logger.error(@result[:response])
    raise "#{user.name} login via web console failed"
  end
end

# Given one attribute of the element with specific selector,then can get the attribute value by
# setting one table parameter "attribute",if not,return the html text
# @param table:
#       | type      | <value>      |
#       | selector  | <hash_value> |
#       | attribute | <value>      |
When /^I get the content of the web element with:$/ do |table|
  if table.headers.size != 2 || table.raw.size < 2 || table.raw.size > 3
    raise "table parameter error"
  end
  type = table.raw[0][1]
  selector = {table.raw[1][1].split("=>")[0].gsub(":", "").to_sym => table.raw[1][1].split("=>")[1]}
  if table.raw.size == 2
    attribute = ""
  elsif table.raw.size == 3
    attribute = table.raw[2][1]
  end
  found_elements = web_browser.get_visible_elements(type, selector)

  if found_elements.empty?
    raise "can not find this #{type} element with #{selector}"
  else
    if attribute.empty?
      get_value = found_elements.last.html
    else
      get_value = found_elements.last.attribute_value(attribute)
    end
    @result[:response] = get_value
  end
end

When /^I get the html of the web page$/ do
  @result[:response] = web_browser.page_html
end
