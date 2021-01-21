Feature: Storage stage tests
  # @author wduan@redhat.com
  # @case_id OCP-31437
  @admin
  Scenario: [Stage] LocalVolume can be used by deployment
    Given the master version >= "4.2"

    Given I store the schedulable nodes in the :nodes clipboard
    And I use the "<%= cb.nodes[0].name %>" node
    When I run commands on the host:
        | losetup -d /dev/loop23                                     |
        | mkdir /srv/block-devices                                   |
        | dd if=/dev/zero of=/srv/block-devices/dev1 bs=1M count=100 |
        | losetup /dev/loop23 /srv/block-devices/dev1                |
    Then the step should succeed

    # LSO is installed during stage pipline
    # storageclass(local-storage-sc) and pv(local-pv-*) is supposed to be availabel at this moment
    And I wait up to 90 seconds for the steps to pass:
    """
    Given I check that the "local-storage-sc" storageclass exists
    When I run the :get admin command with:
      | resource | pv |
    Then the step should succeed
    And the output should contain:
      | local-pv- |
    """

    Given I have a project
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]                         | mypvc            |
      | ["spec"]["storageClassName"]                 | local-storage-sc |
      | ["spec"]["resources"]["requests"]["storage"] | 100Mi            |
    Then the step should succeed
    Given I obtain test data file "storage/misc/deployment.yaml"
    When I run oc create over "deployment.yaml" replacing paths:
      | ["metadata"]["name"]                                                             | mydeploy            |
      | ["spec"]["template"]["metadata"]["labels"]["id"]                                 | <%= project.name %> |
      | ["spec"]["template"]["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc               |
    Then the step should succeed
    And a pod becomes ready with labels:
      | id=<%= project.name %> |
    When I execute on the pod:
      | touch | /mnt/storage/hello |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/storage |
    Then the output should contain:
      | hello |
    Given I use the "<%= pod.node_name %>" node
    When I run commands on the host:
      | mount |
    Then the output should contain:
      | local-pv |

    When I run the :scale admin command with:
      | resource | deployment          |
      | name     | mydeploy            |
      | replicas | 0                   |
      | n        | <%= project.name %> |
    Then the step should succeed
    And I wait for the resource "pod" named "<%= pod.name %>" to disappear
    And I wait up to 30 seconds for the steps to pass:
    """
    Given I use the "<%= pod.node_name %>" node
    When I run commands on the host:
      | mount |
    Then the output should not contain:
      | local-pv |
    """

    When I run the :scale admin command with:
      | resource | deployment          |
      | name     | mydeploy            |
      | replicas | 1                   |
      | n        | <%= project.name %> |
    Then the step should succeed
    And a pod becomes ready with labels:
      | id=<%= project.name %> |
    When I execute on the pod:
      | ls | /mnt/storage |
    Then the output should contain:
      | hello |
