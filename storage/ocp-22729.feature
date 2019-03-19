Feature: https://polarion.engineering.redhat.com/polarion/#/project/OSE/workitem?id=OCP-22729
  # @author lxia@redhat.com
  # @case_id OCP-22729
  Scenario: Dynamic provision with default storage class should work
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | mypvc |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc |
    Then the step should succeed
    Given the "mypvc" PVC becomes :bound within 120 seconds
    And the pod named "mypod" becomes ready

    When I execute on the pod:
      | cp | /proc/cmdline | /mnt/ocp_pv |
    Then the step should succeed
    When I execute on the pod:
      | cat | /mnt/ocp_pv/cmdline |
    Then the step should succeed
    And the output should contain:
      | vmlinuz |
