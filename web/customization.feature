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
    ## redeploy pod to make restored configmap work in tear-down
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
      | curl -o /etc/origin/master/saas-offering.js <%= BushSlicer::HOME %>/features/tierN/testdata/extensions/saas-offering.js |
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
    Given I log the message> Case is low importance so no scripts for 3.5 to 3.8
    And the master version >= "3.9"
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
      | And the output should not contain "external-logging.js"     |
    """
    And the "webconsole-config" configmap is recreated by admin in the "openshift-web-console" project after scenario
    And value of "webconsole-config.yaml" in configmap "webconsole-config" as YAML is merged with:
    """
    extensions:
      scriptURLs:
      - https://rawgit.com/openshift-qe/v3-testfiles/master/extensions/external-logging.js
    """
    Then I wait up to 360 seconds for the steps to pass:
    """
    Given a pod becomes ready with labels:
      | webconsole=true |
    When admin executes on the pod:
      | cat | /var/webconsole-config/webconsole-config.yaml |
    Then the step should succeed
    And the output should contain "external-logging.js"
    """
    Given I switch to the first user
    And I have a project
    When I run the :new_app client command with:
      | app_repo  | docker.io/openshift/hello-openshift |
      | name      | hello                               |
    Then the step should succeed
    When I run the :new_build client command with:
      | app_repo  | centos/ruby-22-centos7~https://github.com/sclorg/ruby-ex.git |
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

  # @author xiaocwan@redhat.com
  # @case_id OCP-11021
  @destructive
  @admin
  Scenario: Create and Edit wildcard routes on web console
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
      | And the output should not contain "wildcard.js"        |
    """
    ## redeploy pod to make restored configmap work in tear-down
    And the "webconsole-config" configmap is recreated by admin in the "openshift-web-console" project after scenario
    And a pod becomes ready with labels:
      | webconsole=true |
    When value of "webconsole-config.yaml" in configmap "webconsole-config" as YAML is merged with:
    """
    extensions:
      scriptURLs:
      - "https://rawgit.com/openshift-qe/v3-testfiles/master/extensions/wildcard.js"
    """

    # delete old console pod and recreate one with changes
    When I run the :delete admin command with:
      | object_type | pods                      |
      | l           | app=openshift-web-console |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | webconsole=true |
    When admin executes on the pod:
      | cat | /var/webconsole-config/webconsole-config.yaml |
    Then the step should succeed
    And the output should contain "wildcard.js"

    ## test scenario 1 - router didn't support subdomains
    Given I switch to the first user
    When I have a project
    Then evaluation of `project.name` is stored in the :project clipboard
    When I run the :new_app client command with:
      | app_repo    | centos/ruby-22-centos7~https://github.com/sclorg/ruby-ex.git |
    Then the step should succeed
    When I perform the :open_create_route_page_from_service_page web console action with:
      | project_name | <%= project.name%> |
      | service_name | ruby-ex            |
    Then the step should succeed
    When I perform the :create_unsecured_route_for_hostname web console action with:
      | route_name | my-route-wildcard |
      | hostname   | "*.example.com"   |
    Then the step should succeed
    When I perform the :check_page_contain_text web console action with:
      | text | wildcard routes are not allowed |
    Then the step should succeed

    ## test scenario 2 - Enable wildcard subdomains
    Given admin ensures new router pod becomes ready after following env added:
      | ROUTER_ALLOW_WILDCARD_ROUTES=true |
    Then the step should succeed
    Given I switch to the first user
    And I use the "<%= cb.project %>" project
    When I perform the :create_route_specify_name_and_hostname_from_routes_page web console action with:
      | project_name | <%= project.name%> |
      | route_name   | my-route-wildcard1  |
      | hostname     | '*.example.com'    |
    Then the step should succeed
    When I get project route as JSON
    Then the step should succeed
    And the output should match:
      | [Hh]ost.*wildcard.example.com |
      | wildcardPolicy.*Subdomain     |

    ## test scenario 3 - Check route edit page for hostname
    When I perform the :check_wildcard_hostname_readonly_when_edit web console action with:
      | project_name | <%= project.name%> |
      | route_name   | my-route-wildcard1 |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-10349
  @destructive
  @admin
  Scenario: Customization for web-console configurations
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
      | And the output should not contain "project-left-nav.js"     |
      | And the output should not contain "saas-offering.js"        |
      | And the output should not contain "application-launcher.js" |
      | And the output should not contain "catalog-categore.js"     |
      | And the output should not contain "quota-message.js"        |
    """
    ## redeploy pod to make restored configmap work in tear-down
    And the "webconsole-config" configmap is recreated by admin in the "openshift-web-console" project after scenario
    And a pod becomes ready with labels:
      | webconsole=true |
    When value of "webconsole-config.yaml" in configmap "webconsole-config" as YAML is merged with:
    """
    extensions:
      scriptURLs:
      - "https://rawgit.com/openshift-qe/v3-testfiles/master/extensions/project-left-nav.js"
      - "https://rawgit.com/openshift-qe/v3-testfiles/master/extensions/saas-offering.js"
      - "https://rawgit.com/openshift-qe/v3-testfiles/master/extensions/application-launcher.js"
      - "https://rawgit.com/openshift-qe/v3-testfiles/master/extensions/catalog-categories.js"
      - "https://rawgit.com/openshift-qe/v3-testfiles/master/extensions/quota-message.js"
    """

    # delete old console pod and recreate one with changes
    When I run the :delete admin command with:
      | object_type | pods                      |
      | l           | app=openshift-web-console |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | webconsole=true |
    When admin executes on the pod:
      | cat | /var/webconsole-config/webconsole-config.yaml |
    Then the step should succeed
    And the output should contain "project-left-nav.js"
    And the output should contain "saas-offering.js"
    And the output should contain "application-launcher.js"
    And the output should contain "catalog-categories.js"
    And the output should contain "quota-message.js"

    ## user and cluster-admin prepare projects and resources
    Given I switch to the first user
    When I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed

    ## Scenario 1: check left navigation menu
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :check_navigator_extension_menus web console action
    Then the step should succeed

    ## Scenario 2: Check customized the Experience Catalog section
    When I run the :goto_home_page web console action
    Then the step should succeed
    When I run the :check_visible_items_when_more_saas_offerings web console action
    Then the step should succeed
    When I run the :check_more_saas_offerings web console action
    Then the step should succeed
    When I run the :check_less_saas_offerings web console action
    Then the step should succeed

    ## Scenario 3: Check Application Launcher in top navigation bar
    When I run the :check_launch_apps_items web console action
    Then the step should succeed

    ## Scenario 4: Check defined category by tag
    Given admin ensures "myhttpd" image_stream is deleted from the "openshift" project after scenario
    When I run the :create admin command with:
      | f    | <%= BushSlicer::HOME %>/features/tierN/testdata/image-streams/httpd-istag.yaml |
      | n    | openshift  |
    Then the step should succeed
    Given I run the :goto_home_page web console action
    When I perform the :click_primary_category_from_catalog web console action with:
      | primary_catagory | My Category |
    Then the step should succeed
    When I perform the :check_page_contain_text web console action with:
      | text | httpd |
    Then the step should succeed

    ## Scenario 5: Check Customaize quota message in message drawer
    Given I create a new project
    When I run the :run client command with:
      | name      | myrc                  |
      | image     | aosqe/hello-openshift |
      | limits    | cpu=500m,memory=500Mi |
      | generator | run/v1                |
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/quota/pod-quota.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    Then I run the :scale client command with:
      | resource | rc   |
      | name     | myrc |
      | replicas | 2    |
    Then the step should succeed
    When I perform the :open_notification_drawer_on_overview web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_message_context_in_drawer web console action with:
      | status   | at   |
      | using    | 2    |
      | total    | 2    |
      | resource | pods |
    Then the step should succeed
    When I perform the :check_page_contain_text web console action with:
      | text | OpenShift Online Pro1 |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-17848
  @destructive
  @admin
  Scenario: Enable ClusterResourceOverrides for web console
    Given the master version >= "3.9"

    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        ClusterResourceOverride:
          configuration:
            apiVersion: v1
            kind: ClusterResourceOverrideConfig
            limitCPUToMemoryPercent: 200
            cpuRequestToLimitPercent: 25
            memoryRequestToLimitPercent: 25
    """
    Given the master service is restarted on all master nodes

    Given I have a project
    Then evaluation of `project.name` is stored in the :project clipboard
    When I run the :run client command with:
      | name      | testdc                |
      | image     | aosqe/hello-openshift |
    Then the step should succeed

    When I perform the :goto_set_resource_limits_for_dc web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | testdc              |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the html of the web page
    Then the output should contain:
      | CPU     |
      | Request |
      | Limit   |
      | Memory  |
    """
    And system verification steps are used:
    """
    I switch to cluster admin pseudo user
    I use the "openshift-web-console" project
    I wait up to 360 seconds for the steps to pass:
      | Given a pod becomes ready with labels:                                    |
      |  \| webconsole=true \|                                                    |
      | When admin executes on the pod:                                           |
      |  \| cat \| /var/webconsole-config/webconsole-config.yaml \|               |
      | Then the step should succeed                                              |
      | And the output should not contain "clusterResourceOverridesEnabled: true" |
    """
    ## redeploy pod to make restored configmap work in tear-down
    And the "webconsole-config" configmap is recreated by admin in the "openshift-web-console" project after scenario
    And a pod becomes ready with labels:
      | webconsole=true |
    Given I use the first master host
    And value of "webconsole-config.yaml" in configmap "webconsole-config" as YAML is merged with:
    """
    features:
      clusterResourceOverridesEnabled: true
    """
    Then I wait up to 360 seconds for the steps to pass:
    """
    Given a pod becomes ready with labels:
      | webconsole=true |
    When admin executes on the pod:
      | cat | /var/webconsole-config/webconsole-config.yaml |
    Then the step should succeed
    And the output should contain "clusterResourceOverridesEnabled: true"
    """

    Given I switch to the first user
    And I use the "<%= cb.project %>" project
    Given I wait for the steps to pass:
    """
    When I perform the :goto_set_resource_limits_for_dc web console action with:
      | project_name | <%= cb.project %> |
      | dc_name      | testdc            |
    Then the step should succeed
    When I perform the :check_page_contain_text web console action with:
      | text | Memory |
    Then the step should succeed
    When I perform the :check_page_not_contain_text web console action with:
      | text | CPU |
    Then the step should succeed
    When I perform the :check_page_not_contain_text web console action with:
      | text | Request |
    Then the step should succeed
    """
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | memory     |
      | limit_type      |            |
      | amount_unit     | MB         |
      | resource_amount | 100        |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed

    Given a pod is present with labels:
      | deployment=testdc-2 |
    When I perform the :goto_one_dc_page web console action with:
      | project_name | <%= cb.project %> |
      | dc_name      | testdc            |
    Then the step should succeed
    When I run the :click_on_configuration_tab web console action
    Then the step should succeed
    When I perform the :check_memory_in_pod_template web console action with:
      | container_name | testdc       |
      | memory_range   | 100 MB limit |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the html of the web page
    Then the output should not contain "CPU"
    """
    When I perform the :check_limits_on_pod_page web console action with:
      | project_name   | <%= cb.project %>               |
      | pod_name       | <%= pod.name %>                 |
      | container_name | testdc                          |
      | cpu_range      | 46 millicores to 186 millicores |
      | memory_range   | 25 MB to 100 MB                 |
    Then the step should succeed
