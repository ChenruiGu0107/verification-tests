#### deployConfig related steps
# Given /^I wait until deployment (?: "(.+)")? matches version "(.+)"$/ do |resource_name, version|
#   ready_timeout = 5 * 60
#   resource_name = resource_name + "-#{version}"
#   rc(resource_name).wait_till_ready(user, ready_timeout)
# end

Given /^I wait until the status of deployment "(.+)" becomes :(.+)$/ do |resource_name, status|
  ready_timeout = 10 * 60
  dc(resource_name).wait_till_status(status.to_sym, user, ready_timeout)
end

# restore the selected dc in teardown by getting current deployment and do:
#   'oc rollback <dc_name> --to-version=<saved_good_version>'
Given /^default (router|docker-registry) deployment config is restored after scenario$/ do |resource|
  ensure_destructive_tagged
  _admin = admin
  _project = project("default", switch: false)
  # first we need to save the current version

  # TODO: maybe we just use dc status => latestVersion ?
  _rc = CucuShift::ReplicationController.get_labeled(
    resource,
    user: _admin,
    project: _project
  ).max_by {|rc| rc.props[:created]}

  raise "no matching rcs found" unless _rc
  version = _rc.props[:annotations]["openshift.io/deployment-config.latest-version"]
  unless _rc.ready?(user: :admin, cached: true)
    raise "latest rc version #{version} is bad"
  end

  cb["#{resource.tr("-","_")}_golden_version"] = Integer(version)
  logger.info "#{resource} will be rolled-back to version #{version}"
  teardown_add {
    @result = _admin.cli_exec(:rollback, deployment_name: resource, to_version: version, n: _project.name)
    raise "Cannot restore #{resource}" unless @result[:success]
    latest_version = @result[:response].match(/^#(\d+)/)[1]
    rc_name = resource + "-" + latest_version
    @result = rc(rc_name, _project).wait_till_ready(_admin, 900)
    raise "#{rc_name} didn't become ready" unless @result[:success]
  }
end

Given /^default (docker-registry|router) replica count is restored after scenario$/ do |resource|
  ensure_destructive_tagged
  _admin = admin
  _project = project("default", switch: false)
  _dc = dc(resource, _project)
  _num = _dc.replicas(user: _admin)
  logger.info("#{resource} replicas will be restored to #{_num} after scenario")

  teardown_add {
    if _num != _dc.replicas(user: _admin, quiet: true)
      @result = _admin.cli_exec(:scale,
                                resource: "deploymentconfigs",
                                name: _dc.name,
                                replicas: _num,
                                n: _project.name)
      raise "could not restore #{_dc.name} replica num" unless @result[:success]

      # paranoya check no bad caching takes place
      num_replicas_restored = wait_for(60) {
        _num == _dc.replicas(user: _admin, quiet: true)
      }
      unless num_replicas_restored
        raise "#{_dc.name} replica num still not restored?!"
      end

      @result = _dc.wait_till_ready(_admin, 900)
      raise "scale unsuccessful for #{_dc.name}" unless @result[:success]
    else
      logger.warn("#{resource} replica num is the same after scenario")
    end
  }
end
