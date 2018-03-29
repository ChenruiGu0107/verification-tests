Given /^I wait for all servicebindings in the project become ready$/ do
	servicebindings = project.service_bindings(by:user)
	ready_timeout = 1 * 60
	start_time = monotonic_seconds
	logger.info("Number of servicebindings: #{servicebindings.count}")
	servicebindings.each do |servicebinding|
		cache_resources(servicebinding)
		@result = servicebinding.wait_till_ready(user, ready_timeout - monotonic_seconds + start_time)
		unless @result[:success]
			raise "servicebinding #{servicebinding.name} did not become ready within allowed time"
		end
	end
end
