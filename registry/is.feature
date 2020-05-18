Feature: Testing imagestream
  # @author xiuwang@redhat.com
  # @case_id OCP-26732
  @destructive
  @admin
  Scenario: Increase the limit on the number of image signatures
    Given I have a project
    Given evaluation of `project.name` is stored in the :saved_name clipboard
    Given a 5 characters random string of type :dns is stored into the :sign_name clipboard
    Given I switch to cluster admin pseudo user
    When I use the "openshift-cluster-version" project
    When I run the :scale client command with:
      | resource | deployment               |
      | name     | cluster-version-operator |
      | replicas | 0                        |
    Then the step should succeed
    Given all existing pods die with labels:
      | k8s-app=cluster-version-operator |
    When I use the "openshift-controller-manager-operator" project
    When I run the :scale client command with:
      | resource | deployment                            |
      | name     | openshift-controller-manager-operator |
      | replicas | 0                                     |
    Then the step should succeed
    And I register clean-up steps:
    """
    When I run the :scale admin command with:
      | resource | deployment                            |
      | name     | openshift-controller-manager-operator |
      | replicas | 1                                     |
      | n        | openshift-controller-manager-operator |
    Then the step should succeed
    When I run the :scale admin command with:
      | resource | deployment                |
      | name     | cluster-version-operator  |
      | replicas | 1                         |
      | n        | openshift-cluster-version |
    Then the step should succeed
    """
    Given all existing pods die with labels:
      | app=openshift-controller-manager-operator |
    When I use the "openshift-controller-manager" project
    And evaluation of `daemon_set("controller-manager").generation_number(user: user, cached: false)` is stored in the :before_change clipboard
    When I obtain test data file "registry/registry.access.redhat.com.yaml"
    And "controller-manager" daemonset becomes ready in the "openshift-controller-manager" project
    And I run the :create_configmap client command with:
      | name      | <%= cb.sign_name %>             |
      | from_file | registry.access.redhat.com.yaml |
    Then the step should succeed
    When I run the :set_volume client command with:
      | resource       | ds/controller-manager         |
      | action         | --add                         |
      | type           | configmap                     |
      | mount-path     | /etc/containers/registries.d/ |
      | name           | <%= cb.sign_name %>           |
      | configmap-name | <%= cb.sign_name %>           |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    And evaluation of `daemon_set("controller-manager").generation_number(user: user, cached: false)` is stored in the :after_change clipboard
    And the expression should be true> cb.after_change - cb.before_change >=1
    """
    And "controller-manager" daemonset becomes ready in the "openshift-controller-manager" project
    Given I switch to the first user
    When I use the "<%= cb.saved_name %>" project
    When I run the :import_image client command with:
      | image_name | registry.access.redhat.com/openshift3/ose:latest |
      | confirm    | true                                             |
    Then the step should succeed
    Then I wait up to 300 seconds for the steps to pass:
    """
    When I get project imagestreamtag named "ose:latest" as YAML
    And evaluation of `@result[:parsed]['image']['signatures'].count` is stored in the :sign_count clipboard
    And the expression should be true> cb.sign_count > 3
    """
