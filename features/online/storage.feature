Feature: ONLY ONLINE Storage related scripts in this file
  # @author bingli@redhat.com
  # @case_id OCP-9967
  @smoke
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
      | volumetest\\s+0/1\\s+RunContainerError.+ |
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
      | volumetest\\s+0/1\\s+RunContainerError.+ |
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
  @smoke
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
  @smoke
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
      | pvc-annotation-notexist | pending | StorageClass "yasun-test-class-not-exist" not found                        |
      | pvc-annotation-blank    | pending | no persistent volumes available for this claim and no storage class is set |
      | pvc-annotation-alpha    | bound   | StorageClass:\\t+randomName                                                |
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
