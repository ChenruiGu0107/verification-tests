Feature: ONLY ONLINE Storage related scripts in this file
  # @author bingli@redhat.com
  # @case_id OCP-9967
  Scenario: Delete pod with mounting error
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/tc526564/pod_volumetest.json |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource | pod |
    Then the output should match:
      | volumetest\\s+0/1.+[eE]rror.+ |
    """
    When I run the :describe client command with:
      | resource | pod        |
      | name     | volumetest |
    Then the step should succeed
    And the output should contain:
      | mkdir /var/lib/docker/volumes/ |
      | permission denied              |
    When I run the :delete client command with:
      | object_type       | pod        |
      | object_name_or_id | volumetest |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource | pod |
    Then the output should not contain:
      | volumetest |
    """

  # @author yasun@redhat.com
  # @case_id OCP-9809
  Scenario: Pod should not create directories within /var/lib/docker/volumes/ on nodes
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/tc526564/pod_volumetest.json |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource | pod |
    Then the output should match:
      | volumetest\\s+0/1.+[eE]rror.+ |
    """
    When I run the :describe client command with:
      | resource | pod        |
      | name     | volumetest |
    Then the step should succeed
    And the output should contain:
      | mkdir /var/lib/docker/volumes/ |
      | permission denied              |

  # @author yasun@redhat.com
  # @case_id OCP-13108
  Scenario: Basic user could not get pv object info
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/claim.json" replacing paths:
      | ["metadata"]["name"]                           | ebsc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"]   | 1Gi                      |
    And the step should succeed
    And the "ebsc-<%= project.name %>" PVC becomes :bound
    And evaluation of `pvc("ebsc-#{project.name}").volume_name(user: user)` is stored in the :pv_name clipboard

    When I run the :describe client command with:
      | resource          | pvc                      |
      | name              | ebsc-<%= project.name %> |
    And the step should succeed

    When I run the :get client command with:
      | resource          | pv                |
      | resource_name     | <%= cb.pv_name %> |
    And the step should fail
    And the output should contain:
      | Forbidden     |
      | cannot get    |

    When I run the :describe client command with:
      | resource          | pv                |
      | name              | <%= cb.pv_name %> |
    And the step should fail
    And the output should contain:
      | Forbidden     |
      | cannot get    |

    When I run the :delete client command with:
      | object_type       | pv                |
      | object_name_or_id | <%= cb.pv_name %> |
    And the step should fail
    And the output should contain:
      | Forbidden     |
      | cannot delete |

  # @author yasun@redhat.com
  # @case_id OCP-9923
  Scenario: Claim requesting to get the maximum capacity
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/dynamic_persistent_volumes/pvc-equal.yaml |
    Then the step should succeed
    And the "claim-equal-limit" PVC becomes :bound
    Then I run the :delete client command with:
      | object_type       | pvc               |
      | object_name_or_id | claim-equal-limit |
    Then the step should succeed

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/dynamic_persistent_volumes/pvc-over.yaml  |
    Then the step should fail
    And the output should contain:
      | Forbidden                                              |
      | maximum storage usage per PersistentVolumeClaim is 1Gi |
      | limit is 5Gi                                           |

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/dynamic_persistent_volumes/pvc-less.yaml  |
    Then the step should fail
    And the output should contain:
      | Forbidden                                              |
      | minimum storage usage per PersistentVolumeClaim is 1Gi |
      | request is 600Mi                                       |

  # @author yasun@redhat.com
  # @case_id OCP-10529
  Scenario Outline: create pvc with annotation in aws
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/dynamic_persistent_volumes/<pvc-name>.json |
    Then the step should succeed
    And the "<pvc-name>" PVC becomes :<status>
    When I run the :describe client command with:
      | resource | pvc        |
      | name     | <pvc-name> |
    Then the step should succeed
    And the output should match:
      | <output> |
    Then I run the :delete client command with:
      | object_type       | pvc        |
      | object_name_or_id | <pvc-name> |
    Then the step should succeed

    Examples: create pvc with annotation in aws
      |  pvc-name               | status  | output                                                                     |
      | pvc-annotation-default  | bound   | StorageClass:\\t+ebs                                                       |
      | pvc-annotation-notexist | pending | "yasun-test-class-not-exist" not found                                     |
      | pvc-annotation-blank    | pending | no persistent volumes available for this claim and no storage class is set |
      | pvc-annotation-alpha    | bound   | StorageClass:\\t+ebs                                                       |
      | pvc-annotation-ebs      | bound   | StorageClass:\\t+ebs                                                       |

  # @author yasun@redhat.com
  # @case_id OCP-13969
  Scenario: scale up&down the application to check the pv can be attached successfully
    Given I have a project
    When I run the :new_app client command with:
      | template | mysql-persistent |
    Then the step should succeed
    And the "mysql" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | name=mysql|
    When I execute on the pod:
      | touch | /var/lib/mysql/data/openshift-test-1 |
    Then the step should succeed
    Then I run the steps 50 times:
    """
    When I run the :scale client command with:
      | resource | deploymentconfig |
      | name     | mysql            |
      | replicas | 0                |
    And all existing pods die with labels:
      | name=mysql |
    Then I run the :scale client command with:
      | resource | deploymentconfig |
      | name     | mysql            |
      | replicas | 1                |
    And a pod becomes ready with labels:
      | name=mysql|
    Then I execute on the pod:
      | ls | /var/lib/mysql/data/ |
    Then the step should succeed
    And the output should contain:
      | openshift-test-1 |
    """

  # @author yasun@redhat.com
  # @case_id OCP-9791
  Scenario: Emptydir volume size is limited in online openshiftd when new an app using emptydir
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/mysql       |
      | env          | MYSQL_USER=tester     |
      | env          | MYSQL_PASSWORD=test   |
      | env          | MYSQL_DATABASE=testdb |
      | name         | mydb                  |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=mydb |
    When I execute on the pod:
      | bash | -lc | dd if=/dev/zero of=/var/lib/mysql/data/openshift-test-1 bs=100M count=6 |
    Then the step should fail
    And the output should contain:
      | Disk quota exceeded |

  # @author yasun@redhat.com
  # @case_id OCP-9792
  Scenario: Volume emptyDir is limited in the Pod in online openshift
    Given I have a project
    And evaluation of `project.mcs(user: user)` is stored in the :proj_selinux_options clipboard
    And evaluation of `project.supplemental_groups(user: user).begin` is stored in the :supplemental_groups clipboard
    And evaluation of `project.uid_range(user: user).begin` is stored in the :uid_range clipboard

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/emptydir/emptydir_pod_selinux_test.json" replacing paths:
      | ["spec"]["containers"][0]["securityContext"]["runAsUser"] | <%= cb.uid_range %>             |
      | ["spec"]["containers"][1]["securityContext"]["runAsUser"] | <%= cb.uid_range %>             |
      | ["spec"]["securityContext"]["fsGroup"]                    | <%= cb.supplemental_groups %>   |
      | ["spec"]["securityContext"]["supplementalGroups"]         | [<%= cb.supplemental_groups %>] |
      | ["spec"]["securityContext"]["seLinuxOptions"]["level"]    | <%= cb.proj_selinux_options %>  |
    Then the step should succeed
    Given the pod named "emptydir" becomes ready
    Then I execute on the pod:
      | bash | -lc | dd if=/dev/zero of=/tmp/openshift-test-1 bs=100M count=6 |
    Then the step should fail
    And the output should contain:
      | Disk quota exceeded |

  # @author chaoyang@redhat.com
  # @case_id OCP-14187
  Scenario: Basic user could not get deeper storageclass object info
    Given I have a project
    When I run the :get client command with:
      | resource   | storageclass |
      | no_headers | true         |
    Then the step should succeed
    And evaluation of `@result[:response].split(" ")[0]` is stored in the :storageclass clipboard

    When I run the :get client command with:
      | resource      | storageclass           |
      | resource_name | <%= cb.storageclass %> |
      | o             | yaml                   |
    Then the step should fail
    And the output should match:
      | Error.*storageclasses.* at the cluster scope |

    When I run the :get client command with:
      | resource | storageclass |
      | o        | yaml         |
    Then the step should succeed

    When I run the :describe client command with:
      | resource | storageclass           |
      | name     | <%= cb.storageclass %> |
    Then the step should fail
    And the output should match:
      | Error.*storageclasses.* at the cluster scope |

    When I run the :delete client command with:
      | object_type       | storageclass           |
      | object_name_or_id | <%= cb.storageclass %> |
    Then the step should fail
    And the output should match:
      | Error.*storageclasses.* at the cluster scope |

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/dynamic-provisioning/storageclass-io1.yaml |
    Then the step should fail
    And the output should match:
      | Error.*storageclasses.* at the cluster scope |

    When I run the :get client command with:
      | resource      | storageclass           |
      | resource_name | <%= cb.storageclass %> |
    Then the step should succeed

  # @author yasun@redhat.com
  # @case_id OCP-14565
  Scenario: check the storage size description on web console on paid tier
    Given I have a project
    When I perform the :check_storage_limit_min_size_on_paid web console action with:
      | project_name     | <%= project.name %> |
    Then the step should succeed

  # @author yasun@redhat.com
  # @case_id OCP-15010
  Scenario: check the storage size description on web console on free tier
    Given I have a project
    When I perform the :check_storage_limit_min_size_on_free web console action with:
      | project_name     | <%= project.name %> |
    Then the step should succeed
