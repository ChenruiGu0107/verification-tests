Feature: web console customization related features

  # @author xiaocwan@redhat.com
  # @case_id OCP-15364
  @destructive
  @admin
  Scenario: Check System Alerts on Masthead as online message
    Given the master version >= "3.7"
    Given I use the first master host
    Given the "/etc/origin/master/system-status.js" file is restored on host after scenario
    When I run commands on all masters:
      | curl -o /etc/origin/master/system-status.js https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/extensions/system-status.js                                                                |
      | sed -i 's#https://m0sg3q4t415n.statuspage.io/api/v2/summary.json#https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/extensions/system-status.json#g'  /etc/origin/master/system-status.js |
    Then the step should succeed
    Given master config is merged with the following hash:
    """
    assetConfig:
      extensionScripts:
      - /etc/origin/master/system-status.js
      - /etc/origin/master/openshift-ansible-catalog-console.js
    """
    And the master service is restarted on all master nodes

    When I run the :check_system_status_issues_warning web console action
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
