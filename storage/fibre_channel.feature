Feature: FibreChannel specific scenarios on dedicated servers
  # @author lxia@redhat.com
  # @case_id OCP-12664
  @admin
  Scenario: FibreChannel volume plugin with ROX access mode and Retain policy
    Given I have a project
    When admin creates a PV from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/fc/pv-retain-rwx.json" where:
      | ["metadata"]["name"]       | pv-<%= project.name %> |
      | ["spec"]["accessModes"][0] | ReadOnlyMany           |
    Then the step should succeed
    When I create a manual pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]       | mypvc        |
      | ["spec"]["accessModes"][0] | ReadOnlyMany |
    Then the step should succeed
    And the "mypvc" PVC becomes :bound
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc |
      | ["metadata"]["name"]                                         | mypod |
    Then the step should succeed
    Given the pod named "mypod" becomes ready
    When I execute on the pod:
      | mountpoint | -d | /mnt/ocp_pv |
    Then the step should succeed
    When I execute on the pod:
      | cp | /proc/cpuinfo | /mnt/ocp_pv/ |
    Then the step should succeed
