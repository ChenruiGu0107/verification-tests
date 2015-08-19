When /^I pry$/ do
  require 'pry'
  binding.pry
end

When /^I pry in a step with table$/ do |table|
  require 'pry'
  binding.pry
end

And /^I fail the scenario$/ do
  raise "Stop in the name of Christ!"
end

And /^I log the message> (.+)$/ do |message|
  @result = {}
  @result[:response] = message
  @result[:success] = true
  @result[:instruction] = "log message: #{message}"
  @result[:exitstatus] = 0
  logger.info(message)
end

And /^I log the messages:$/ do |table|
  table.raw.flatten.each { |m| logger.info(m) }
end

Then /^I do nothing$/ do
end
