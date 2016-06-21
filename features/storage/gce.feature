Feature: GCE Persistent Volume
  # @author lxia@redhat.com
  # @case_id 522125
  @admin
  Scenario: [storage_201] Only one pod with GCE PD can be scheduled when NoDiskConflicts policy is enabled
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :oadm_new_project admin command with:
      | project_name  | <%= cb.proj_name %>                   |
      | node_selector | labelForTC522125=<%= cb.proj_name %>  |
      | admin         | <%= user.name %>                      |
    Then the step should succeed

    Given I store the schedulable nodes in the :nodes clipboard
    And label "labelForTC522125=<%= cb.proj_name %>" is added to the "<%= cb.nodes[0].name %>" node

    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.proj_name %>" project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod-NoDiskConflict-1.json" replacing paths:
      | ["metadata"]["name"]                                       | gce-pod1-<%= project.name %> |
      | ["spec"]["containers"][0]["securityContext"]["privileged"] | true                      |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod-NoDiskConflict-2.json" replacing paths:
      | ["metadata"]["name"]                                       | gce-pod2-<%= project.name %> |
      | ["spec"]["containers"][0]["securityContext"]["privileged"] | true                      |
    Then the step should succeed

    When I run the :describe client command with:
      | resource | pod                       |
      | name     | gce-pod2-<%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | Pending          |
      | FailedScheduling |
      | NoDiskConflict   |
    When I run the :get client command with:
      | resource | events |
    Then the step should succeed
    And the output should contain:
      | FailedScheduling |
      | NoDiskConflict   |

  # @author lxia@redhat.com
  # @case_id 508057
  @admin
  Scenario: GCE persistent disk with RWO access mode and Default policy
    Given I have a project
    And I have a 1 GB volume and save volume id in the :gcepd clipboard

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pv-default-rwo.json" where:
      | ["metadata"]["name"]                      | pv-gce-<%= project.name %> |
      | ["spec"]["capacity"]["storage"]           | 1                          |
      | ["spec"]["accessModes"][0]                | ReadWriteOnce              |
      | ["spec"]["gcePersistentDisk"]["pdName"]   | <%= cb.gcepd %>            |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Default                    |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-gce-<%= project.name %> |
      | ["spec"]["volumeName"]                       | pv-gce-<%= project.name %>  |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce               |
      | ["spec"]["resources"]["requests"]["storage"] | 1                           |
    Then the step should succeed
    And the "pvc-gce-<%= project.name %>" PVC becomes bound to the "pv-gce-<%= project.name %>" PV

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-gce-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %>   |
    Then the step should succeed
    Given the pod named "mypod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | touch | /mnt/gce/tc508057 |
    Then the step should succeed

    When I run the :delete client command with:
      | object_type       | pod                       |
      | object_name_or_id | mypod-<%= project.name %> |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | pvc                         |
      | object_name_or_id | pvc-gce-<%= project.name %> |
    Then the step should succeed
    And the PV becomes :released

  # @author lxia@redhat.com
  # @case_id 522413
  @admin
  Scenario: Create an GCE PD volume with RWO accessmode and Delete policy
    Given I have a project
    And I have a 1 GB volume and save volume id in the :gcepd clipboard

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pv-default-rwo.json" where:
      | ["metadata"]["name"]                      | gce-<%= project.name %> |
      | ["spec"]["capacity"]["storage"]           | 1Gi                     |
      | ["spec"]["accessModes"][0]                | ReadWriteOnce           |
      | ["spec"]["gcePersistentDisk"]["pdName"]   | <%= cb.gcepd %>         |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Delete                  |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-gce-<%= project.name %> |
      | ["spec"]["volumeName"]                       | gce-<%= project.name %>  |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce            |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                      |
    Then the step should succeed
    And the "pvc-gce-<%= project.name %>" PVC becomes bound to the "gce-<%= project.name %>" PV

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-gce-<%= project.name %>  |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
    Then the step should succeed
    Given the pod named "mypod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | touch | /mnt/gce/tc522413 |
    Then the step should succeed

    When I run the :delete client command with:
      | object_type       | pod                       |
      | object_name_or_id | mypod-<%= project.name %> |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | pvc                      |
      | object_name_or_id | pvc-gce-<%= project.name %> |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pv.name %>" to disappear within 1200 seconds

  # @author lxia@redhat.com
  # @case_id 510565
  @admin
  @destructive
  Scenario: [origin_infra_20] gce pd volume security testing
    Given I have a project
    And I have a 1 GB volume and save volume id in the :gcepd clipboard

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/security/gce_selinux_fsgroup_test.json" replacing paths:
      | ["metadata"]["name"]                                   | mypod-<%= project.name %> |
      | ["spec"]["securityContext"]["seLinuxOptions"]["level"] | s0:c13,c2       |
      | ["spec"]["securityContext"]["fsGroup"]                 | 24680           |
      | ["spec"]["securityContext"]["runAsUser"]               | 1000160000      |
      | ["spec"]["volumes"][0]["gcePersistentDisk"]["pdName"]  | <%= cb.gcepd %> |
    Then the step should succeed
    And the pod named "mypod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | id |
    Then the step should succeed
    And the output should contain:
      | 1000160000 |
      | 24680 |
    When I execute on the pod:
      | ls | -lZd | /mnt/gce |
    Then the step should succeed
    And the output should contain:
      | 24680 |
    When I execute on the pod:
      | touch | /mnt/gce/tc510565 |
    Then the step should succeed
    When I execute on the pod:
      | ls | -lZ | /mnt/gce/tc510565 |
    Then the step should succeed
    And the output should contain:
      | 24680 |
    When I run the :delete client command with:
      | object_type       | pod                       |
      | object_name_or_id | mypod-<%= project.name %> |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/security/gce-privileged-test.json" replacing paths:
      | ["metadata"]["name"]                                   | mypod2-<%= project.name %> |
      | ["spec"]["securityContext"]["seLinuxOptions"]["level"] | s0:c13,c2       |
      | ["spec"]["securityContext"]["fsGroup"]                 | 24680           |
      | ["spec"]["volumes"][0]["gcePersistentDisk"]["pdName"]  | <%= cb.gcepd %> |
    Then the step should succeed
    And the pod named "mypod2-<%= project.name %>" becomes ready
    When I execute on the pod:
      | id |
    Then the step should succeed
    And the output should contain:
      | uid=0 |
      | 24680 |
    When I execute on the pod:
      | ls | -lZd | /mnt/gce |
    Then the step should succeed
    And the output should contain:
      | 24680 |
    When I execute on the pod:
      | touch | /mnt/gce/tc510565 |
    Then the step should succeed
    When I execute on the pod:
      | ls | -lZ | /mnt/gce/tc510565 |
    Then the step should succeed
    And the output should contain:
      | 24680 |
