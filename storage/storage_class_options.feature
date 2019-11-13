Feature: Dynamic provision via storage class with options
  # @author lxia@redhat.com
  # @case_id OCP-22882
  @admin
  Scenario: Dynamic provision using storage class with option volumeBindingMode set to WaitForFirstConsumer
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["volumeBindingMode"] | WaitForFirstConsumer |
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes :pending
    When I run the :describe client command with:
      | resource | pvc   |
      | name     | mypvc |
    Then the step should succeed
    And the output should contain:
      | WaitForFirstConsumer |

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc |
    Then the step should succeed
    And the pod named "mypod" becomes ready
    And the "mypvc" PVC becomes :bound

  # @author lxia@redhat.com
  # @case_id OCP-22948
  @admin
  Scenario: Dynamic provision using storage class with option volumeBindingMode set to Immediate
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["volumeBindingMode"] | Immediate |
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes :bound
