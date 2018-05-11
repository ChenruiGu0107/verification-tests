Given /the storage applied_cluster_resource_quota is stored in the#{OPT_QUOTED} clipboard/ do |cb_name|
  cb_name ||= "acrq"
  list = CucuShift::AppliedClusterResourceQuota.list(user: user, project: project)
  cb["#{cb_name}-list"] = list

  cb[cb_name] = list.find { |o| o.name.end_with?('-noncompute') }
end
