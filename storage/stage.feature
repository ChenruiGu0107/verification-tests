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
      | local-storage-sc |
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
    And the "mypvc" PVC becomes :bound within 120 seconds
    And the expression should be true> pv(pvc.volume_name).reclaim_policy == "Delete"
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
      | <%= pvc.volume_name %> |

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
      | <%= pvc.volume_name %> |
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

    Given I ensure "mydeploy" deployments is deleted
    And I ensure "mypvc" pvc is deleted
    Then the PV becomes :available within 120 seconds


  # @author wduan@redhat.com
  # @case_id OCP-35943
  @admin
  Scenario: [Stage] PV is provisioned by Localvolumeset
    Given the master version >= "4.6"

    # LSO and LVS are installed during stage pipline
    # storageclass(local-storage-set-sc) and pv(local-pv-*) is supposed to be availabel at this moment
    Given I check that the "local-storage-set-sc" storageclass exists
    When I run the :get admin command with:
      | resource | pv |
    Then the step should succeed
    And the output should contain:
      | local-storage-set-sc |

    Given I have a project
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]                         | mypvc                |
      | ["spec"]["storageClassName"]                 | local-storage-set-sc |
      | ["spec"]["resources"]["requests"]["storage"] | 2G                   |
    Then the step should succeed
    Given I obtain test data file "storage/misc/deployment.yaml"
    When I run oc create over "deployment.yaml" replacing paths:
      | ["metadata"]["name"]                                                             | mydeploy            |
      | ["spec"]["template"]["metadata"]["labels"]["id"]                                 | <%= project.name %> |
      | ["spec"]["template"]["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc               |
    Then the step should succeed
    And the "mypvc" PVC becomes :bound within 120 seconds
    And the expression should be true> pv(pvc.volume_name).reclaim_policy == "Delete"
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
      | <%= pvc.volume_name %> |

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
      | <%= pvc.volume_name %> |
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

    Given I ensure "mydeploy" deployments is deleted
    And I ensure "mypvc" pvc is deleted
    Then the PV becomes :available within 120 seconds


  # @author wduan@redhat.com
  # @case_id OCP-35942
  @admin
  Scenario: [Stage] LocalVolumeDiscovery works
    Given the master version >= "4.6"
    # LSO, LVS and LVD are installed during stage pipline
    # storageclass(local-storage-set-sc) and pv(local-pv-*) is supposed to be availabel at this moment
    Given I check that the "local-storage-set-sc" storageclass exists
    When I run the :get admin command with:
      | resource | pv |
    Then the step should succeed
    And the output should contain:
      | local-storage-set-sc |

    Given I switch to cluster admin pseudo user
    Given I use the "local-storage" project
    When I run the :get admin command with:
      | resource | localvolumediscovery  |
    Then the output should contain "auto-discover-devices"
    And I save all localvolumediscoveryresults for my cluster to :lvdr_1 clipboard

    Given I switch to the first user
    And I have a project
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]                         | mypvc                |
      | ["spec"]["storageClassName"]                 | local-storage-set-sc |
      | ["spec"]["resources"]["requests"]["storage"] | 2G                   |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pod.yaml"
    When I run oc create over "pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod        |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc        |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/storage |
    Then the step should succeed
    Given the pod named "mypod" becomes ready
    And the "mypvc" PVC becomes :bound within 120 seconds
    When I run the :get admin command with:
      | resource      | pv                               |
      | resource_name | <%= pvc.volume_name %>           |
      | o             | custom-columns=:.spec.local.path |
    Then the step should succeed
    And evaluation of `@result[:stdout].split("/")[-1].strip` is stored in the :device_id clipboard

    Given I log the message> <%= cb.lvdr_1 %>
    Then the output should contain "<%= cb.device_id %>"

    Given 300 seconds have passed
    Given I switch to cluster admin pseudo user
    Given I use the "local-storage" project
    Given I save all localvolumediscoveryresults for my cluster to :lvdr_2 clipboard
    And I log the message> <%= cb.lvdr_2 %>
    Then the output should not contain "<%= cb.device_id %>"

  # @author wduan@redhat.com
  # @case_id OCP-40577
  @admin
  Scenario: [Stage] Local storage must-gather image can gather logs
    Given the master version >= "4.7"
    Given a 5 characters random string is saved into the :rand_str clipboard
    And I store master major version in the :master_version clipboard
    When I switch to cluster admin pseudo user
    And I run the :oadm_must_gather admin command with:
      | dest_dir | /tmp/ocp40577/must-gather.local.<%= cb.rand_str %>                                         |
      | image    | registry.redhat.io/openshift4/ose-local-storage-mustgather-rhel8:v<%= cb.master_version %> |
    Then the step should succeed
    And the output should not contain:
      | "unable to pull image" |
    And the "/tmp/ocp40577/must-gather.local.<%= cb.rand_str %>" file is present
    Given the "/tmp/ocp40577/must-gather.local.<%= cb.rand_str %>" directory is removed

