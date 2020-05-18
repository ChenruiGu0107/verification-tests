Feature: Check overview page
  # @author yapei@redhat.com
  # @case_id OCP-18266
  @admin
  Scenario: Check Daemon Sets on Overview
    Given the master version >= "3.10"
    Given cluster role "cluster-admin" is added to the "first" user
    And I use the "openshift-template-service-broker" project
    Given a pod becomes ready with labels:
      | apiserver=true |
    When I perform the :goto_overview_page web console action with:
      | project_name | openshift-template-service-broker |
    Then the step should succeed
    When I perform the :operate_in_kebab_drop_down_list_on_overview web console action with:
      | resource_name        | apiserver                          |
      | resource_type        | daemon set                         |
      | project_name         | openshift-template-service-broker  |
      | viewlog_type         | pods                               |
      | log_name             | <%= pod.name %>                    |
      | edityaml_type        | DaemonSet                          |
      | yaml_name            | apiserver                          |
    Then the step should succeed
    When I perform the :expand_resource_entry web console action with:
      | resource_name | apiserver |
    Then the step should succeed
    When I perform the :check_internal_traffic web console action with:
      | project_name         | openshift-template-service-broker |
      | service_name         | apiserver                         |
      | service_port_mapping | 443/TCP 8443                      |
    Then the step should succeed
    When I perform the :check_container_info_on_overview web console action with:
      | container_image | openshift3/ose-template-service-broker |
      | container_ports | 8443/TCP                               |
    Then the step should succeed
