When /^I pry$/ do
  require 'pry'
  binding.pry
end

And /^I fail the scenario$/ do
  raise "Stop in the name of Christ!"
end
