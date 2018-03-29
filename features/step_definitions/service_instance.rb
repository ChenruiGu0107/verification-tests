Given /^I wait for all serviceinstances in the project become ready$/ do
	serviceinstances = project.service_instances(by:user)
	ready_timeout = 3 * 60
	start_time = monotonic_seconds
	logger.info("Number of serviceinstances: #{serviceinstances.count}")
	serviceinstances.each do |serviceinstance|
		cache_resources(serviceinstance)
		@result = serviceinstance.wait_till_ready(user, ready_timeout - monotonic_seconds + start_time)
		unless @result[:success]
			raise "serviceinstance #{serviceinstance.name} did not become ready within allowed time"
		end
	end
end
