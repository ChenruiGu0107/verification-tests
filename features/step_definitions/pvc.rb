require 'yaml'

Given /^the#{OPT_QUOTED} PVC becomes #{SYM}(?: within (\d+) sec)?$/ do |pvc_name, status, timeout|
  timeout = timeout ? timeout.to_i : 30
  @result = pvc(pvc_name).wait_till_status(status.to_sym, user, timeout)

  unless @result[:success]
    raise "PVC #{pvc_name} never reached status: #{status}"
  end
end
