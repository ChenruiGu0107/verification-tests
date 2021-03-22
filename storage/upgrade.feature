Feature: Scenarios which will be used both for function checking and upgrade checking
  # @author lxia@redhat.com
  Scenario Outline: There should be one and only one default storage class
    Given I log the messages:
      | Running <for> test ... |
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
  # @case_id OCP-22715
  @admin
  Scenario: Cluster operator storage should be in available status
    Given I log the messages:
      | Running function test ... |
    Given the expression should be true> cluster_operator('storage').condition(type: 'Progressing')['status'] == "False"
    Given the expression should be true> cluster_operator('storage').condition(type: 'Available')['status'] == "True"
    Given the expression should be true> cluster_operator('storage').condition(type: 'Degraded')['status'] == "False"
    Given the expression should be true> env.version_ge("4.2", user: user) ? cluster_operator('storage').condition(type: 'Upgradeable')['status'] == "True" : true


  # @author lxia@redhat.com
  Scenario Outline: Dynamic provision with default storage class should work
    Given I log the messages:
      | Running <for> test ... |
    Given I have a project
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"] | mypvc |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pod.yaml"
    When I run oc create over "pod.yaml" replacing paths:
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
