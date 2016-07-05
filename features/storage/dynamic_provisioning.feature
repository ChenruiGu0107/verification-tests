Feature: Dynamic provisioning
  # @author lxia@redhat.com
  # @case_id 510362 508987 510359
  @admin
  Scenario: dynamic provisioning
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :oadm_new_project admin command with:
      | project_name  | <%= cb.proj_name %>         |
      | node_selector | <%= cb.proj_name %>=dynamic |
      | admin         | <%= user.name %>            |
    Then the step should succeed

    Given I store the schedulable nodes in the :nodes clipboard
    And label "<%= cb.proj_name %>=dynamic" is added to the "<%= cb.nodes[0].name %>" node

    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.proj_name %>" project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | dynamic-pvc1-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce                    |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                              |
    Then the step should succeed
    And the "dynamic-pvc1-<%= project.name %>" PVC becomes :bound

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | dynamic-pvc2-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteMany                    |
      | ["spec"]["resources"]["requests"]["storage"] | 2Gi                              |
    Then the step should succeed
    And the "dynamic-pvc2-<%= project.name %>" PVC becomes :bound

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | dynamic-pvc3-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadOnlyMany                     |
      | ["spec"]["resources"]["requests"]["storage"] | 3Gi                              |
    Then the step should succeed
    And the "dynamic-pvc3-<%= project.name %>" PVC becomes :bound

    When I run the :get admin command with:
      | resource | pv |
    Then the output should contain:
      | dynamic-pvc1-<%= project.name %> |
      | dynamic-pvc2-<%= project.name %> |
      | dynamic-pvc3-<%= project.name %> |

    When I run the :get client command with:
      | resource      | pvc                              |
      | resource_name | dynamic-pvc1-<%= project.name %> |
      | o             | json                             |
    Then the step should succeed
    And evaluation of `@result[:parsed]['spec']['volumeName']` is stored in the :pv_name1 clipboard

    When I run the :get client command with:
      | resource      | pvc                              |
      | resource_name | dynamic-pvc2-<%= project.name %> |
      | o             | json                             |
    Then the step should succeed
    And evaluation of `@result[:parsed]['spec']['volumeName']` is stored in the :pv_name2 clipboard

    When I run the :get client command with:
      | resource      | pvc                              |
      | resource_name | dynamic-pvc3-<%= project.name %> |
      | o             | json                             |
    Then the step should succeed
    And evaluation of `@result[:parsed]['spec']['volumeName']` is stored in the :pv_name3 clipboard

    And I save volume id from PV named "<%= cb.pv_name1 %>" in the :volumeID1 clipboard
    And I save volume id from PV named "<%= cb.pv_name2 %>" in the :volumeID2 clipboard
    And I save volume id from PV named "<%= cb.pv_name3 %>" in the :volumeID3 clipboard

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc1-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod1-<%= project.name %>       |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc2-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod2-<%= project.name %>       |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc3-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod3-<%= project.name %>       |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=frontendhttp |

    When I execute on the "<%= pod(-1).name %>" pod:
      | touch | /mnt/gce/testfile_1 |
    Then the step should succeed
    When I execute on the "<%= pod(-2).name %>" pod:
      | touch | /mnt/gce/testfile_2 |
    Then the step should succeed
    When I execute on the "<%= pod(-3).name %>" pod:
      | touch | /mnt/gce/testfile_3 |
    Then the step should succeed

    When I run the :delete client command with:
      | object_type | pod |
      | all         |     |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type | pvc |
      | all         |     |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    Then I wait for the resource "pv" named "<%= cb.pv_name1 %>" to disappear within 1200 seconds
    And I wait for the resource "pv" named "<%= cb.pv_name2 %>" to disappear within 1200 seconds
    And I wait for the resource "pv" named "<%= cb.pv_name3 %>" to disappear within 1200 seconds

    Given I use the "<%= cb.nodes[0].name %>" node
    When I run commands on the host:
      | mount |
    Then the step should succeed
    And the output should not contain:
      | <%= cb.pv_name1 %> |
      | <%= cb.pv_name2 %> |
      | <%= cb.pv_name3 %> |
      | <%= cb.volumeID1 %> |
      | <%= cb.volumeID2 %> |
      | <%= cb.volumeID3 %> |

  # @author lxia@redhat.com
  # @case_id 528853
  @admin
  Scenario: dynamic provisioning with multiple access modes
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | dynamic-pvc-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce                   |
      | ["spec"]["accessModes"][1]                   | ReadWriteMany                   |
      | ["spec"]["accessModes"][2]                   | ReadOnlyMany                    |
      | ["spec"]["resources"]["requests"]["storage"] | 1                               |
    Then the step should succeed
    And the "dynamic-pvc-<%= project.name %>" PVC becomes :bound

    When I run the :get admin command with:
      | resource      | pv                                                |
      | resource_name | <%= pvc.volume_name(user: admin, cached: true) %> |
    Then the step should succeed
    And the output should contain:
      | dynamic-pvc-<%= project.name %> |
      | Bound |
      | RWO |
      | ROX |
      | RWX |

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %>       |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=frontendhttp |

    When I execute on the "<%= pod.name %>" pod:
      | touch | /mnt/gce/testfile |
    Then the step should succeed

    When I run the :delete client command with:
      | object_type | pod |
      | all         |     |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type | pvc |
      | all         |     |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name(user: admin, cached: true) %>" to disappear within 1200 seconds

  # @author lxia@redhat.com
  # @case_id 519501
  @admin
  Scenario: Check only one pv created for one pvc for dynamic provisioner
    Given I have a project
    And I run the steps 100 times:
    """
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-ERB.json
    Then the step should succeed
    """
    Given 100 PVCs become :bound within 600 seconds with labels:
      | name=dynamic-pvc-<%= project.name %> |
    When I run the :get admin command with:
      | resource | pv |
    Then the output should contain 100 times:
      | <%= project.name %> |
