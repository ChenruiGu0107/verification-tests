Feature: web console customization related features

  # @author xiaocwan@redhat.com
  # @case_id OCP-15364
  @destructive
  @admin
  Scenario: Check System Alerts on Masthead as online message
    Given the master version >= "3.9"
    And system verification steps are used:
    """
    I switch to cluster admin pseudo user
    I use the "openshift-web-console" project
    I wait up to 360 seconds for the steps to pass:
      | Given a pod becomes ready with labels:                      |
      |  \| webconsole=true \|                                      |
      | When admin executes on the pod:                             |
      |  \| cat \| /var/webconsole-config/webconsole-config.yaml \| |
      | Then the step should succeed                                |
      | And the output should not contain "system-status.js"        |
    """
    ## redeploy pod to make restored comfigmap work in tear-down
    And the "webconsole-config" configmap is recreated by admin in the "openshift-web-console" project after scenario
    And a pod becomes ready with labels:
      | webconsole=true |
    When value of "webconsole-config.yaml" in configmap "webconsole-config" as YAML is merged with:
    """
    extensions:
      scriptURLs:
      - "https://rawgit.com/openshift-qe/v3-testfiles/master/extensions/system-status.js"
    """
    Then I wait up to 360 seconds for the steps to pass:
    """
    Given a pod becomes ready with labels:
      | webconsole=true |
    When admin executes on the pod:
      | cat | /var/webconsole-config/webconsole-config.yaml |
    Then the step should succeed
    And the output should contain "system-status.js"
    """

    ## check web-console
    Given I switch to the first user
    And I have a project
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :systemstatus_warning web console action with:
      | text | open issues |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-13804
  @destructive
  @admin
  Scenario: Check and customize the Experience Catalog section
    Given I log the message> Tech preview in 3.6, no scripts for 3.6
    Given the master version >= "3.7"
    Given I use the first master host
    Given the "/etc/origin/master/saas-offering.js" file is restored on host after scenario
    When I run commands on all masters:
      | curl -o /etc/origin/master/saas-offering.js https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/extensions/saas-offering.js |
    Then the step should succeed
    Given master config is merged with the following hash:
    """
    assetConfig:
      extensionScripts:
      - /etc/origin/master/saas-offering.js
      - /etc/origin/master/openshift-ansible-catalog-console.js
    """
    And the master service is restarted on all master nodes
    Given I login via web console
    When I run the :check_visible_items_when_more_saas_offerings web console action
    Then the step should succeed
    When I run the :check_more_saas_offerings web console action
    Then the step should succeed
    When I run the :check_less_saas_offerings web console action
    Then the step should succeed

  # @author xxia@redhat.com
  # @case_id OCP-11024
  @destructive
  @admin
  Scenario: Support other external logging solution via extension file
    Given I log the message> Case is low importance so no scripts for 3.5 and 3.6
    Given the master version >= "3.7"
    And I use the first master host
    And the "/etc/origin/master/external-logging.js" file is restored on host after scenario
    When I run commands on all masters:
      | curl -o /etc/origin/master/external-logging.js https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/extensions/external-logging.js |
    Then the step should succeed
    When master config is merged with the following hash:
    """
    assetConfig:
      extensionScripts:
      - external-logging.js
      - /etc/origin/master/openshift-ansible-catalog-console.js
    """
    Then the master service is restarted on all master nodes

    Given I have a project
    When I run the :new_app client command with:
      | app_repo  | docker.io/openshift/hello-openshift |
      | name      | hello                               |
    Then the step should succeed
    When I run the :new_build client command with:
      | app_repo  | centos/ruby-22-centos7~https://github.com/openshift/ruby-ex.git |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deploymentconfig=hello |
    When I perform the :check_external_log_link_on_pod_page web console action with:
      | project_name  | <%= project.name %> |
      | resource_name | <%= pod.name %>     |
    Then the step should succeed
    When I perform the :check_external_log_link_on_rc_page web console action with:
      | project_name  | <%= project.name %> |
      | resource_name | hello-1             |
      | check_expand  |                     |
    Then the step should succeed
    Given the "ruby-ex-1" build finished
    When I perform the :goto_monitoring_page web console action with:
      | project_name  | <%= project.name %> |
    Then the step should succeed
    When I perform the :expand_resource_logs web console action with:
      | resource_type | Builds     |
      | resource_name | ruby-ex-1  |
    Then the step should succeed
    When I perform the :check_external_log_link web console action with:
      | resource_name | ruby-ex-1 |
    Then the step should succeed
