Feature: kubelet restart and node restart

  # @author lxia@redhat.com
  # @case_id OCP-26972
  @admin
  @destructive
  Scenario: Node restart should not affect attached/mounted cloud provider volumes
    Given I have a project
    When I run the :new_app client command with:
      | template | jenkins-persistent |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=jenkins |

    When I execute on the pod:
      | touch | /var/lib/jenkins/testfile_before_restart |
    Then the step should succeed
    Given I use the "<%= pod.node_name %>" node
    And the host is rebooted and I wait it up to 600 seconds to become available
    And I wait up to 120 seconds for the steps to pass:
    """
    # verify previous created files still exist
    When I execute on the pod:
      | ls | /var/lib/jenkins/testfile_before_restart |
    Then the step should succeed

    # write to the mounted storage
    When I execute on the pod:
      | touch | /var/lib/jenkins/testfile_after_restart |
    Then the step should succeed
    """


  # @author lxia@redhat.com
  Scenario Outline: Dynamic provisioning with raw block volume
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc-without-annotations.json" replacing paths:
      | ["metadata"]["name"]   | mypvc |
      | ["spec"]["volumeMode"] | Block |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod-with-block-volume.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod        |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc        |
      | ["spec"]["containers"][0]["volumeDevices"][0]["devicePath"]  | /dev/myblock |
    Then the step should succeed
    And the pod named "mypod" becomes ready
    When I execute on the pod:
      | sh | -c | [[ -b /dev/myblock ]] |
    Then the step should succeed
    Examples:
      | provisioner    |
      | aws-ebs        | # @case_id OCP-24015
      | azure-disk     | # @case_id OCP-24336
      | cinder         | # @case_id OCP-25884
      | gce-pd         | # @case_id OCP-24337
      | vsphere-volume | # @case_id OCP-24014


  # @author lxia@redhat.com
  Scenario Outline: Dynamic provisioning with file system volume
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc-without-annotations.json" replacing paths:
      | ["metadata"]["name"]   | mypvc      |
      | ["spec"]["volumeMode"] | Filesystem |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod     |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc     |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/mypd |
    Then the step should succeed
    And the pod named "mypod" becomes ready
    When I execute on the pod:
      | sh | -c | [[ -d /mnt/mypd ]] |
    Then the step should succeed
    Examples:
      | provisioner    |
      | aws-ebs        | # @case_id OCP-24039
      | vsphere-volume | # @case_id OCP-24040


  # @author lxia@redhat.com
  Scenario Outline: Dynamic provisioning with invalid volume mode
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc-without-annotations.json" replacing paths:
      | ["metadata"]["name"]   | mypvc  |
      | ["spec"]["volumeMode"] | <mode> |
    Then the step should fail
    And the output should match "supported values:\s+\"Block\",\s+\"Filesystem\""

    Examples:
      | mode        |
      | ""          | # @case_id OCP-24089
      | invalidMode | # @case_id OCP-24090


  # @author lxia@redhat.com
  @admin
  Scenario Outline: kubelet have cloud provider configured
    Given I store the schedulable nodes in the :nodes clipboard
    And I use the "<%= cb.nodes.first.name %>" node
    When I run commands on the host:
      | ps -eaf \| grep 'cloud-provider' |
    Then the step should succeed
    And the output should contain:
      | --cloud-provider=<provider> |

    And I use the "<%= cb.nodes.last.name %>" node
    When I run commands on the host:
      | ps -eaf \| grep 'cloud-provider' |
    Then the step should succeed
    And the output should contain:
      | --cloud-provider=<provider> |

    Examples:
      | provider  |
      | aws       | # @case_id OCP-26261
      | azure     | # @case_id OCP-26263
      | gce       | # @case_id OCP-26260
      | openstack | # @case_id OCP-26262
      | vsphere   | # @case_id OCP-26264
      |           | # @case_id OCP-26265
