require 'yaml'

Given /^the#{OPT_QUOTED} PVC becomes #{SYM}$/ do |pvc_name, status|
  @result = pvc(pvc_name).wait_till_status(status.to_sym, user, 30)

  unless @result[:success]
    raise "PVC #{pvc_name} never reached status: #{status}"
  end
end
