Feature: AWS Persistent Volume
  # @author lxia@redhat.com
  # @case_id 484930
  @admin
  @destructive
  Scenario: Creating aws ebs persistent volume with RWO access mode and Default Policy
    Given I have a project
    And I have a 1 GB volume and save volume id in the :volumeID clipboard

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/pv-rwo.yaml" where:
      | ["metadata"]["name"]                         | pv-aws-<%= project.name %> |
      | ["spec"]["capacity"]["storage"]              | 1                          |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce              |
      | ["spec"]["awsElasticBlockStore"]["volumeID"] | <%= cb.volumeID %>         |
      | ["spec"]["persistentVolumeReclaimPolicy"]    | Default                    |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/claim.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-aws-<%= project.name %> |
      | ["spec"]["volumeName"]                       | pv-aws-<%= project.name %>  |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce               |
      | ["spec"]["resources"]["requests"]["storage"] | 1                           |
    Then the step should succeed
    And the "pvc-aws-<%= project.name %>" PVC becomes bound to the "pv-aws-<%= project.name %>" PV

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-aws-<%= project.name %>   |
      | ["metadata"]["name"]                                         | pod484930-<%= project.name %> |
    Then the step should succeed
    Given the pod named "pod484930-<%= project.name %>" becomes ready
    When I execute on the pod:
      | touch | /tmp/tc484930 |
    Then the step should succeed

    When I run the :delete client command with:
      | object_type       | pod                           |
      | object_name_or_id | pod484930-<%= project.name %> |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | pvc                         |
      | object_name_or_id | pvc-aws-<%= project.name %> |
    Then the step should succeed
    And the PV becomes :released

  # @author lxia@redhat.com
  # @case_id 522392
  @admin
  @destructive
  Scenario: Create an ebs volume with RWO accessmode and Delete policy
    Given I have a project
    And I have a 1 GB volume and save volume id in the :volumeID clipboard

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/pv-rwo.yaml" where:
      | ["metadata"]["name"]                         | pv-aws-<%= project.name %> |
      | ["spec"]["capacity"]["storage"]              | 1Gi                        |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce              |
      | ["spec"]["awsElasticBlockStore"]["volumeID"] | <%= cb.volumeID %>         |
      | ["spec"]["persistentVolumeReclaimPolicy"]    | Delete                     |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/claim.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-aws-<%= project.name %> |
      | ["spec"]["volumeName"]                       | pv-aws-<%= project.name %>  |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce               |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                         |
    Then the step should succeed
    And the "pvc-aws-<%= project.name %>" PVC becomes bound to the "pv-aws-<%= project.name %>" PV

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-aws-<%= project.name %>   |
      | ["metadata"]["name"]                                         | pod522392-<%= project.name %> |
    Then the step should succeed
    Given the pod named "pod522392-<%= project.name %>" becomes ready
    When I execute on the pod:
      | touch | /tmp/tc522392 |
    Then the step should succeed

    When I run the :delete client command with:
      | object_type       | pod                           |
      | object_name_or_id | pod522392-<%= project.name %> |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | pvc                         |
      | object_name_or_id | pvc-aws-<%= project.name %> |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "pv-aws-<%= project.name %>" to disappear within 1200 seconds

  # @author lxia@redhat.com
  # @case_id 510564
  @admin
  Scenario: [origin_infra_20] aws ebs volume security testing
    Given I have a project
    And I have a 1 GB volume and save volume id in the :volumeID clipboard

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/security/aws-selinux-fsgroup-test.json" replacing paths:
      | ["metadata"]["name"]                                   | pod510564-1-<%= project.name %> |
      | ["spec"]["securityContext"]["seLinuxOptions"]["level"] | s0:c13,c2                       |
      | ["spec"]["securityContext"]["fsGroup"]                 | 24680                           |
      | ["spec"]["securityContext"]["runAsUser"]               | 1000160000                      |
      | ["spec"]["volumes"][0]["awsElasticBlockStore"]["volumeID"] | <%= cb.volumeID %>          |
    Then the step should succeed
    And the pod named "pod510564-1-<%= project.name %>" becomes ready
    When I execute on the pod:
      | id |
    Then the output should contain:
      | 1000160000 |
      | 24680      |
    When I execute on the pod:
      | ls | -lZd | /mnt/aws |
    Then the output should contain:
      | 24680 |
    When I execute on the pod:
      | touch | /mnt/aws/tc510564 |
    Then the step should succeed
    When I execute on the pod:
      | ls | -lZ | /mnt/aws/tc510564 |
    Then the output should contain:
      | 24680 |
    When I run the :delete client command with:
      | object_type       | pod                             |
      | object_name_or_id | pod510564-1-<%= project.name %> |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/security/aws-privileged-test.json" replacing paths:
      | ["metadata"]["name"]                                   | pod510564-2-<%= project.name %> |
      | ["spec"]["securityContext"]["seLinuxOptions"]["level"] | s0:c13,c2                       |
      | ["spec"]["securityContext"]["fsGroup"]                 | 24680                           |
      | ["spec"]["volumes"][0]["awsElasticBlockStore"]["volumeID"] | <%= cb.volumeID %>          |
    Then the step should succeed
    And the pod named "pod510564-2-<%= project.name %>" becomes ready
    When I execute on the pod:
      | id |
    Then the output should contain:
      | uid=0 |
      | 24680 |
    When I execute on the pod:
      | ls | -lZd | /mnt/aws |
    Then the output should contain:
      | 24680 |
    When I execute on the pod:
      | touch | /mnt/aws/tc510564 |
    Then the step should succeed
    When I execute on the pod:
      | ls | -lZ | /mnt/aws/tc510564 |
    Then the output should contain:
      | 24680 |

  # @author lxia@redhat.com
  # @case_id 522129
  @admin
  Scenario: [storage_201]Only one pod with AWS ebs volume can be scheduled when NoDiskConflicts policy is enabled
    Given I store the schedulable nodes in the :nodes clipboard
    And label "labelForTC522129=1" is added to the "<%= cb.nodes[0].name %>" node

    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :oadm_new_project admin command with:
      | project_name  | <%= cb.proj_name %> |
      | node_selector | labelForTC522129=1  |
      | admin         | <%= user.name %>    |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.proj_name %>" project
    And I have a 1 GB volume and save volume id in the :volumeID clipboard

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/security/aws-selinux-fsgroup-test.json" replacing paths:
      | ["metadata"]["name"]                                       | aws-pod1-<%= cb.proj_name %> |
      | ["spec"]["volumes"][0]["awsElasticBlockStore"]["volumeID"] | <%= cb.volumeID %>           |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/security/aws-selinux-fsgroup-test.json" replacing paths:
      | ["metadata"]["name"]                                       | aws-pod2-<%= cb.proj_name %> |
      | ["spec"]["volumes"][0]["awsElasticBlockStore"]["volumeID"] | <%= cb.volumeID %>           |
    Then the step should succeed

    When I run the :describe client command with:
      | resource | pod                          |
      | name     | aws-pod2-<%= cb.proj_name %> |
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
