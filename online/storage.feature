Feature: ONLY ONLINE Storage related scripts in this file

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
    Then the expression should be true> @result[:success] == env.version_ge("3.6", user: user)

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
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/ebs/dynamic-provisioning/storageclass-io1.yaml |
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

  # @author yuwei@redhat.com
  # @case_id OCP-19803
  Scenario: User is ONLY allowed to select the valid access mode for the default storageclass in web console
    When I run the :get client command with:
      | resource      | storageclass |
    Then the step should succeed
    And the output should contain "gp2-encrypted (default)"
    When I run the :get client command with:
      | resource      | storageclass                                                                         |
      | resource_name | gp2-encrypted                                                                        |
      | template      | '{{ index .metadata.annotations "storage.alpha.openshift.io/access-mode" }}'         |
    Then the step should succeed
    And the output should contain "ReadWriteOnce"
    Given I have a project
    When I perform the :check_default_pvc_access_mode web console action with:
      | project_name    | <%= project.name %>    |
      | storage_class   | gp2-encrypted          |
      | storage_type    | gp2                    |
    Then the step should succeed
    When I perform the :create_default_pvc_from_storage_page web console action with:
      | project_name    | <%= project.name %>    |
      | pvc_name        | yuwei-test             |
      | storage_size    | 0.001                  |
      | storage_unit    | TiB                    |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-19480
  Scenario Outline: create pvc with annotation in aws using dedicated env
    Given I have a project
    When I run the :create client command with:
      | f | https://github.com/openshift-qe/v3-testfiles/raw/master/online/dynamic_persistent_volumes/<pvc-name>.json |
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

    Examples: create pvc with annotation in aws using dedicated env
      | pvc-name                | status  | output                                                                     |
      | pvc-annotation-default  | bound   | StorageClass:\s+gp2-encrypted                                              |
      | pvc-annotation-notexist | pending | "yasun-test-class-not-exist" not found                                     |
      | pvc-annotation-blank    | pending | no persistent volumes available for this claim and no storage class is set |
      | pvc-annotation-alpha    | bound   | StorageClass:\s+gp2-encrypted                                              |
      | pvc-annotation-gp2      | bound   | StorageClass:\s+gp2                                                        |
      