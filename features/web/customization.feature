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
