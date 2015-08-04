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
