Feature: Add, update remove volume to rc/dc and --overwrite option
  # @author jialiu@redhat.com
  # @case_id OCP-11495
  @admin
  @destructive
  Scenario: Add/Remove hostPath volume to dc and rc
    # Preparations
    Given I have a project
    And SCC "privileged" is added to the "default" user
    And SCC "privileged" is added to the "system:serviceaccounts" group
    When I run the :new_app_as_dc client command with:
      | docker_image | quay.io/openshifttest/storage@sha256:a05b96d373be86f46e76817487027a7f5b8b5f87c0ac18a246b018df11529b40 |
      | name         | mydb                                                                                                  |
      | labels       | app=mydb                                                                                              |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=mydb |
    # add hostPath to dc
    When I run the :set_volume client command with:
      | resource   | dc/mydb  |
      | action     | --add    |
      | type       | hostPath |
      | mount-path | /opt1    |
      | path       | /usr     |
      | name       | v1       |
    Then the step should succeed
    And I wait for the resource "pod" named "<%= pod.name %>" to disappear
    And a pod becomes ready with labels:
      | app=mydb |
    # check after add hostPath to dc
    When I get project dc named "mydb" as YAML
    Then the step should succeed
    And the output should contain:
      | - mountPath: /opt1 |
      | - hostPath:        |
      | path: /usr         |
      | name: v1           |
    When I get project rc named "mydb-2" as YAML
    Then the step should succeed
    And the output should contain:
      | - mountPath: /opt1 |
      | - hostPath:        |
      | path: /usr         |
      | name: v1           |
    When I execute on the pod:
      | grep | opt1 | /proc/mounts |
    Then the step should succeed
    When I execute on the pod:
      | ls | /opt1/sbin |
    Then the step should succeed
    # remove hostPath from dc
    When I run the :set_volume client command with:
      | resource | dc/mydb  |
      | action   | --remove |
      | name     | v1       |
    Then the step should succeed
    And I wait for the resource "pod" named "<%= pod.name %>" to disappear
    And a pod becomes ready with labels:
      | app=mydb |
    # check after remove hostPath from dc
    When I get project dc named "mydb" as YAML
    Then the step should succeed
    And the output should not contain:
      | name: v1 |
    When I get project rc named "mydb-3" as YAML
    Then the step should succeed
    And the output should not contain:
      | name: v1 |
    When I execute on the pod:
      | grep | opt1 | /proc/mounts |
    Then the step should fail
    When I execute on the pod:
      | ls | /opt1/sbin |
    Then the step should fail
    # add hostPath to rc
    When I run the :set_volume client command with:
      | resource   | rc/mydb-3 |
      | action     | --add     |
      | type       | hostPath  |
      | mount-path | /opt2     |
      | path       | /usr      |
      | name       | v2        |
    Then the step should succeed
    # check after add hostPath to rc
    When I get project rc named "mydb-3" as YAML
    Then the step should succeed
    And the output should contain:
      | - mountPath: /opt2 |
      | - hostPath:        |
      | path: /usr         |
      | name: v2           |
    When I run the :delete client command with:
      | object_type | pod      |
      | l           | app=mydb |
    Then the step should succeed
    And I wait for the resource "pod" named "<%= pod.name %>" to disappear
    And a pod becomes ready with labels:
      | app=mydb |
    When I execute on the pod:
      | grep | opt2 | /proc/mounts |
    Then the step should succeed
    When I execute on the pod:
      | ls | /opt2/sbin |
    Then the step should succeed
    # remove hostPath from rc
    When I run the :set_volume client command with:
      | resource | rc/mydb-3 |
      | action   | --remove  |
      | name     | v2        |
    Then the step should succeed
    # check after remove emptyDir from rc
    When I get project rc named "mydb-3" as YAML
    Then the step should succeed
    And the output should not contain:
      | name: v2 |
    When I run the :delete client command with:
      | object_type | pod      |
      | l           | app=mydb |
    Then the step should succeed
    And I wait for the resource "pod" named "<%= pod.name %>" to disappear
    And a pod becomes ready with labels:
      | app=mydb |
    When I execute on the pod:
      | grep | opt2 | /proc/mounts |
    Then the step should fail
    When I execute on the pod:
      | ls | /opt2/sbin |
    Then the step should fail

  # @author chaoyang@redhat.com
  # @case_id OCP-9606
  @admin
  Scenario: Create a claim when adding volumes to dc/rc
    Given I have a project
    Given I have a NFS service in the project

    # Creating PV
    Given I obtain test data file "storage/nfs/auto/pv.json"
    Given admin creates a PV from "pv.json" where:
      | ["metadata"]["name"]         | pv-<%= project.name %>           |
      | ["spec"]["nfs"]["server"]    | <%= service("nfs-service").ip %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>           |
    Then the step should succeed

    # new-app
    When I run the :new_app_as_dc client command with:
      | image_stream | openshift/postgresql:latest|
      | env          | POSTGRESQL_USER=tester     |
      | env          | POSTGRESQL_PASSWORD=xxx    |
      | env          | POSTGRESQL_DATABASE=testdb |
      | name         | mydb                       |
      | labels       | app=mydb                   |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=mydb |

    When I run the :set_volume client command with:
      | resource      | dc                       |
      | resource_name | mydb                     |
      | action        | --add                    |
      | type          | persistentVolumeClaim    |
      | claim-mode    | ReadWriteMany            |
      | claim-name    | nfsc-<%= project.name %> |
      | claim-size    | 5                        |
      | name          | mydb                     |
      | mount-path    | /opt111                  |
      | claim-class   | sc-<%= project.name %>   |
    Then the step should succeed

    When I run the :set_volume client command with:
      | resource      | dc     |
      | resource_name | mydb   |
    Then the step should succeed

    And I wait for the resource "pod" named "<%= pod.name %>" to disappear
    And a pod becomes ready with labels:
      | app=mydb |
    #Verify the PVC mode, size, name are correctly created, the PVC has bound the PV
    And the "nfsc-<%= project.name %>" PVC becomes bound to the "pv-<%= project.name %>" PV
    And the expression should be true> pvc.access_modes[0] == "ReadWriteMany"
    And the expression should be true> pvc.capacity == "5Gi"

    #Verify the pod has mounted the nfs
    When I execute on the pod:
      | grep | opt111 | /proc/mounts |
    Then the step should succeed

  # @author lxia@redhat.com
  # @case_id OCP-9845
  Scenario: Pod should be able to mount multiple PVCs
    Given I have a project
    When I run the :new_app client command with:
      | template | mysql-persistent |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=mysql |

    When I run the :set_volume client command with:
      | resource   | dc/mysql              |
      | action     | --add                 |
      | type       | persistentVolumeClaim |
      | mount-path | /mypath1              |
      | name       | myvolume1             |
      | claim-size | 1Gi                   |
    Then the step should succeed
    When I run the :set_volume client command with:
      | resource   | dc/mysql              |
      | action     | --add                 |
      | type       | persistentVolumeClaim |
      | mount-path | /mypath2              |
      | name       | myvolume2             |
      | claim-size | 2Gi                   |
    Then the step should succeed
    And I wait for the resource "pod" named "<%= pod.name %>" to disappear
    And a pod becomes ready with labels:
      | name=mysql |

    When I execute on the pod:
      | df |
    Then the step should succeed
    And the output should contain:
      | /mypath1 |
      | /mypath2 |
    When I execute on the pod:
      | mount |
    Then the step should succeed
    And the output should contain:
      | /mypath1 |
      | /mypath2 |


  # @author lxia@redhat.com
  @admin
  Scenario Outline: oc set volume with claim-class parameter test
    Given I have a project
    When I run the :new_app_as_dc client command with:
      | docker_image | quay.io/openshifttest/storage@sha256:a05b96d373be86f46e76817487027a7f5b8b5f87c0ac18a246b018df11529b40 |
      | name         | storage                                                                                               |
      | labels       | app=storage                                                                                           |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=storage |

    When I run the :set_volume client command with:
      | resource      | dc                   |
      | resource_name | storage              |
      | action        | --add                |
      | type          | pvc                  |
      | claim-mode    | rwo                  |
      | claim-name    | pvcsc                |
      | claim-size    | 1G                   |
      | name          | gcevolume            |
      | mount-path    | /opt111              |
      | claim-class   | <storage-class-name> |
    Then the step should succeed
    When I run the :set_volume client command with:
      | resource      | dc         |
      | resource_name | storage    |
      | action        | --all      |
    Then the step should succeed
    Then the output should contain:
      | pvcsc              |
      | mounted at /opt111 |

    And I wait for the resource "pod" named "<%= pod.name %>" to disappear
    And a pod becomes ready with labels:
      | app=storage |
    And the "pvcsc" PVC becomes :bound
    And the expression should be true> pvc.storage_class == "<storage-class-name>"
    And the expression should be true> pvc.access_modes[0] == "ReadWriteOnce"
    And the expression should be true> pvc.capacity == "1Gi"

    Examples:
      | provisioner | storage-class-name |
      | gce-pd      | standard           | # @case_id OCP-10414
      | aws-ebs     | gp2                | # @case_id OCP-10489
      | cinder      | standard           | # @case_id OCP-10490
      | azure-disk  | managed-premium    | # @case_id OCP-13729

  # @author lxia@redhat.com
  # @case_id OCP-10415
  @admin
  Scenario: Negetive test of oc set volume with claim-class paraters
    Given I have a project
    When I run the :new_app client command with:
      | template | mysql-persistent |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=mysql |

    When I run the :set_volume client command with:
      | resource      | dc                     |
      | resource_name | mysql                  |
      | action        | --add                  |
      | type          | pvc                    |
      | claim-mode    | rwo                    |
      | claim-name    | pvcsc                  |
      | claim-size    | 1G                     |
      | name          | gcevolume              |
      | mount-path    | /opt111                |
      | claim-class   | sc-<%= project.name %> |
    Then the step should succeed
    And the "pvcsc" PVC status is :pending

    Given admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | | |

    When I run the :set_volume client command with:
      | resource      | dc                     |
      | resource_name | mysql                  |
      | action        | --add                  |
      | type          | pvc                    |
      | claim-mode    | rwo                    |
      | claim-name    | pvcsc                  |
      | name          | gcevolume              |
      | mount-path    | /opt111                |
      | claim-class   | sc-<%= project.name %> |
    Then the step should fail
    Then the outputs should contain:
      | must provide --claim-size to create new pvc with claim-class |


  # @author wduan@redhat.com
  # @case_id OCP-25833
  Scenario: Add/Remove dynamic-provisioning persistentVolumeClaim to dc
    Given I have a project
    When I run the :new_app_as_dc client command with:
      | docker_image | quay.io/openshifttest/storage@sha256:a05b96d373be86f46e76817487027a7f5b8b5f87c0ac18a246b018df11529b40 |
      | name         | mydb                                                                                                  |
      | labels       | app=mydb                                                                                              |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=mydb |
    # add pvc to dc and check
    When I run the :set_volume client command with:
      | resource   | dc/mydb                 |
      | action     | --add                   |
      | type       | persistentVolumeClaim   |
      | mount-path | /opt1                   |
      | name       | v1                      |
      | claim-name | pvc-<%= project.name %> |
      | claim-mode | ReadWriteOnce           |
      | claim-size | 1Gi                     |
    Then the step should succeed
    And I wait for the resource "pod" named "<%= pod.name %>" to disappear
    And a pod becomes ready with labels:
      | app=mydb |
    And the expression should be true> dc('mydb').containers_spec.first.volume_mounts.last['mountPath'] == "/opt1"
    And the expression should be true> dc('mydb').containers_spec.first.volume_mounts.last['name'] == "v1"
    And the expression should be true> dc('mydb').template['spec']['volumes'].last['persistentVolumeClaim']['claimName'] == "pvc-#{project.name}"
    And the expression should be true> rc('mydb-2').containers_spec.first.volume_mounts.last['mountPath'] == "/opt1"
    And the expression should be true> rc('mydb-2').containers_spec.first.volume_mounts.last['name'] == "v1"
    And the expression should be true> rc('mydb-2').template['spec']['volumes'].last['persistentVolumeClaim']['claimName'] == "pvc-#{project.name}"
    When I execute on the pod:
      | grep | opt1 | /proc/mounts |
    Then the step should succeed
    # remove pvc from dc and check
    When I run the :set_volume client command with:
      | resource | dc/mydb  |
      | action   | --remove |
      | name     | v1       |
    Then the step should succeed
    And I wait for the resource "pod" named "<%= pod.name %>" to disappear
    And a pod becomes ready with labels:
      | app=mydb |
    # check after remove pvc from dc
    When I get project dc named "mydb" as YAML
    Then the step should succeed
    And the output should not contain:
      | name: v1 |
    When I get project rc named "mydb-3" as YAML
    Then the step should succeed
    And the output should not contain:
      | name: v1 |
    When I execute on the pod:
      | grep | opt1 | /proc/mounts |
    Then the step should fail


  # @author wduan@redhat.com
  # @case_id OCP-25837
  Scenario: Add/Remove dynamic-provisioning persistentVolumeClaim to rc
    Given I have a project
    When I run the :new_app_as_dc client command with:
      | docker_image | quay.io/openshifttest/storage@sha256:a05b96d373be86f46e76817487027a7f5b8b5f87c0ac18a246b018df11529b40 |
      | name         | mydb                                                                                                  |
      | labels       | app=mydb                                                                                              |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=mydb |
    # add pvc to rc and check
    When I run the :set_volume client command with:
      | resource   | rc/mydb-1               |
      | action     | --add                   |
      | type       | persistentVolumeClaim   |
      | mount-path | /opt2                   |
      | name       | v2                      |
      | claim-name | pvc-<%= project.name %> |
      | claim-mode | ReadWriteOnce           |
      | claim-size | 1Gi                     |
    Then the step should succeed
    And the expression should be true> rc('mydb-1').containers_spec.first.volume_mounts.last['mountPath'] == "/opt2"
    And the expression should be true> rc('mydb-1').containers_spec.first.volume_mounts.last['name'] == "v2"
    And the expression should be true> rc('mydb-1').template['spec']['volumes'].last['persistentVolumeClaim']['claimName'] == "pvc-#{project.name}"
    When I run the :delete client command with:
      | object_type | pod      |
      | l           | app=mydb |
    Then the step should succeed
    And I wait for the resource "pod" named "<%= pod.name %>" to disappear
    And a pod becomes ready with labels:
      | app=mydb |
    When I execute on the pod:
      | grep | opt2 | /proc/mounts |
    Then the step should succeed
    # remove pvc from rc and check
    When I run the :set_volume client command with:
      | resource | rc/mydb-1 |
      | action   | --remove  |
      | name     | v2        |
    Then the step should succeed
    # check after remove pvc from rc
    When I get project rc named "mydb-1" as YAML
    Then the step should succeed
    And the output should not contain:
      | name: v2 |
    When I run the :delete client command with:
      | object_type | pod      |
      | l           | app=mydb |
    Then the step should succeed
    And I wait for the resource "pod" named "<%= pod.name %>" to disappear
    And a pod becomes ready with labels:
      | app=mydb |
    When I execute on the pod:
      | grep | opt2 | /proc/mounts |
    Then the step should fail


  # @author wduan@redhat.com
  # @case_id OCP-25839
  Scenario: Add/Remove dynamic-provisioning persistentVolumeClaim to dc with '--overwrite' option
    Given I have a project
    When I run the :new_app_as_dc client command with:
      | docker_image | quay.io/openshifttest/storage@sha256:a05b96d373be86f46e76817487027a7f5b8b5f87c0ac18a246b018df11529b40 |
      | name         | mydb                                                                                                  |
      | labels       | app=mydb                                                                                              |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=mydb |
    # add pvc to dc without '--overwrite' option
    When I run the :set_volume client command with:
      | resource   | dc/mydb                    |
      | action     | --add                      |
      | type       | persistentVolumeClaim      |
      | mount-path | /mnt/volume                |
      | name       | mydb-volume-1              |
      | claim-name | mypvc-1                    |
      | claim-mode | ReadWriteOnce              |
      | claim-size | 1Gi                        |
    Then the step should succeed
    And I wait for the resource "pod" named "<%= pod.name %>" to disappear
    And a pod becomes ready with labels:
      | app=mydb |
    When I run the :set_volume client command with:
      | resource   | dc/mydb                    |
      | action     | --add                      |
      | type       | persistentVolumeClaim      |
      | mount-path | /mnt/volume                |
      | claim-name | mypvc-                     |
      | claim-mode | ReadWriteOnce              |
      | claim-size | 1Gi                        |
    Then the step should fail
    And the output should contain:
      | already exists |
    When I run the :set_volume client command with:
      | resource   | dc/mydb                    |
      | action     | --add                      |
      | type       | persistentVolumeClaim      |
      | mount-path | /mnt/volume                |
      | name       | mydb-volume-1              |
      | claim-name | mypvc-                     |
      | claim-mode | ReadWriteOnce              |
      | claim-size | 1Gi                        |
    Then the step should fail
    And the output should contain:
      | Use --overwrite to replace |
    # add pvc to dc with '--overwrite' option and check
    When I run the :set_volume client command with:
      | resource   | dc/mydb                    |
      | action     | --add                      |
      | type       | persistentVolumeClaim      |
      | mount-path | /mnt/volume                |
      | name       | mydb-volume-1              |
      | claim-name | mypvc                      |
      | claim-mode | ReadWriteOnce              |
      | claim-size | 1Gi                        |
      | overwrite  |                            |
    Then the step should succeed
    And I wait for the resource "pod" named "<%= pod.name %>" to disappear
    And a pod becomes ready with labels:
      | app=mydb |
    And the expression should be true> dc('mydb').containers_spec.first.volume_mounts.first['mountPath'] == "/mnt/volume"
    And the expression should be true> dc('mydb').containers_spec.first.volume_mounts.first['name'] == "mydb-volume-1"
    And the expression should be true> dc('mydb').template['spec']['volumes'].last['persistentVolumeClaim']['claimName'] == "mypvc"
    When I execute on the pod:
      | ls | -l | /mnt/volume |
    Then the step should succeed
