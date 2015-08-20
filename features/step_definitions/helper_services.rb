# store here steps that create test services within OpenShift test env

Given /^I have a NFS service in the(?: "([^ ]+?)")? project$/ do |project_name|
  project(project_name)
  unless project.exists?(user: user)
    raise "project #{project_name} does not exist"
  end

  # project service account is automatically created with the project creation
  step %Q@service account "#{project.name}" is granted the following scc policy: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/scc_super_template.yaml@

  @result = user.cli_exec(:create, n: project.name, f: 'https://github.com/openshift-qe/v3-testfiles/raw/master/storage/nfs/nfs-server.yaml')

  raise "could not create NFS Server service" unless @result[:success]

  step 'I wait for the "nfs-service" service to become ready'

  # now you have NFS running, to get IP, call `service.ip`
end
