Feature: kubelet restart and node restart

  # @author lxia@redhat.com
  @admin
  @destructive
  Scenario Outline: node restart should not affect attached/mounted volumes
    Given admin creates a project with a random schedulable node selector
    And evaluation of `%w{ReadWriteOnce ReadWriteOnce ReadWriteOnce}` is stored in the :accessmodes clipboard
    And I run the steps 3 times:
    """
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | dynamic-pvc-#{cb.i}       |
      | ["spec"]["accessModes"][0]                   | #{cb.accessmodes[cb.i-1]} |
      | ["spec"]["resources"]["requests"]["storage"] | #{cb.i}Gi                 |
    Then the step should succeed
    And the "dynamic-pvc-#{cb.i}" PVC becomes :bound
    When I run the :get admin command with:
      | resource | pv |
    Then the output should contain:
      | dynamic-pvc-#{cb.i} |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc-#{cb.i} |
      | ["metadata"]["name"]                                         | mypod#{cb.i}        |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/<platform>     |
    Then the step should succeed
    Given the pod named "mypod#{cb.i}" becomes ready
    When I execute on the pod:
      | touch | /mnt/<platform>/testfile_before_restart_#{cb.i} |
    Then the step should succeed
    """
    # restart node
    Given I use the "<%= node.name %>" node
    And the host is rebooted and I wait it up to 600 seconds to become available
    And I wait up to 120 seconds for the steps to pass:
    """
    Given I run the steps 3 times:
    <%= '"'*3 %>
    # verify previous created files still exist
    When I execute on the "mypod#{cb.i}" pod:
      | ls | /mnt/<platform>/testfile_before_restart_#{cb.i} |
    Then the step should succeed
    # write to the mounted storage
    When I execute on the "mypod#{cb.i}" pod:
      | touch | /mnt/<platform>/testfile_after_restart_#{cb.i} |
    Then the step should succeed
    <%= '"'*3 %>
    """

    Examples:
      | platform |
      | gce      | # @case_id OCP-11620
      | cinder   | # @case_id OCP-11330
      | aws      | # @case_id OCP-10919

  # @author jhou@redhat.com
  @admin
  @destructive
  Scenario Outline: node restart should not affect attached/mounted volumes on IaaS
    Given admin creates a project with a random schedulable node selector

    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/storageClass.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %>      |
      | ["provisioner"]      | kubernetes.io/<provisioner> |
    Then the step should succeed

    And evaluation of `%w{ReadWriteOnce ReadWriteOnce ReadWriteOnce}` is stored in the :accessmodes clipboard
    And I run the steps 3 times:
    """
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-#{ cb.i }                 |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>        |
      | ["spec"]["accessModes"][0]                   | #{ cb.accessmodes[ cb.i-1 ] } |
      | ["spec"]["resources"]["requests"]["storage"] | #{ cb.i }Gi                   |
    Then the step should succeed
    And the "pvc-#{ cb.i }" PVC becomes :bound

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod#{ cb.i } |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-#{ cb.i }  |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/iaas      |
    Then the step should succeed
    And the pod named "mypod#{ cb.i }" becomes ready

    When I execute on the pod:
      | touch | /mnt/iaas/testfile_before_restart_#{ cb.i } |
    Then the step should succeed
    """

    # reboot node
    Given I use the "<%= node.name %>" node
    And the host is rebooted and I wait it to become available
    And I wait up to 120 seconds for the steps to pass:
    """
    # verify previous created files still exist
    Given I run the steps 3 times:
    <%= '"'*3 %>
    When I execute on the "mypod#{ cb.i }" pod:
      | ls | /mnt/iaas/testfile_before_restart_#{ cb.i } |
    Then the step should succeed
    # write to the mounted storage
    When I execute on the "mypod#{ cb.i }" pod:
      | touch | /mnt/iaas/testfile_after_restart_#{ cb.i } |
    Then the step should succeed
    <%= '"'*3 %>
    """

  Examples:
    | provisioner    |
    | vsphere-volume | # @case_id OCP-13632
    | azure-disk     | # @case_id OCP-13435


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
