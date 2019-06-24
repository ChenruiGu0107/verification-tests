Feature: Scenarios which will be used both for function checking and upgrade checking
  # @author lxia@redhat.com
  Scenario Outline: There should be one and only one default storage class
    When I run the :get client command with:
      | resource | storageclass |
    Then the step should succeed
    And the output should contain:
      | default |
    When I run the :get client command with:
      | resource | storageclass |
      | o        | yaml         |
    Then the step should succeed
    And the output should contain 1 times:
      | is-default-class: "true" |
    When I run the :describe client command with:
      | resource | storageclass |
    Then the step should succeed
    And the output should contain 1 times:
      | is-default-class=true |
    Examples:
      | for      |
      | function | # @case_id OCP-22125
      | upgrade  | # @case_id OCP-23499


  # @author lxia@redhat.com
  @admin
  Scenario Outline: Cluster operator storage should be in available status
    When I run the :get admin command with:
      | resource      | clusteroperator                                                    |
      | resource_name | storage                                                            |
      | o             | jsonpath='{.status.conditions[?(@.type == "Progressing")].status}' |
    Then the step should succeed
    And the output should contain "False"
    When I run the :get admin command with:
      | resource      | clusteroperator                                                  |
      | resource_name | storage                                                          |
      | o             | jsonpath='{.status.conditions[?(@.type == "Available")].status}' |
    Then the step should succeed
    And the output should contain "True"
    When I run the :get admin command with:
      | resource      | clusteroperator                                                 |
      | resource_name | storage                                                         |
      | o             | jsonpath='{.status.conditions[?(@.type == "Degraded")].status}' |
    Then the step should succeed
    And the output should contain "False"
    Examples:
      | for      |
      | function | # @case_id OCP-22715
      | upgrade  | # @case_id OCP-23501


  # @author lxia@redhat.com
  Scenario: Dynamic provision with default storage class should work
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | mypvc |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc |
    Then the step should succeed
    Given the pod named "mypod" becomes ready
    And the "mypvc" PVC becomes :bound within 120 seconds

    When I execute on the pod:
      | cp | /proc/cmdline | /mnt/ocp_pv |
    Then the step should succeed
    When I execute on the pod:
      | cat | /mnt/ocp_pv/cmdline |
    Then the step should succeed
    And the output should contain "vmlinuz"
    Examples:
      | for      |
      | function | # @case_id OCP-22729
      | upgrade  | # @case_id OCP-23500
