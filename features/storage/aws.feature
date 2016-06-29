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
