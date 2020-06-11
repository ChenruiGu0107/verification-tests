Feature: GCE specific scenarios
  # @author lxia@redhat.com
  # @case_id OCP-15528
  @admin
  Scenario: Dynamic provision with storageclass which has zones set to empty string
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["volumeBindingMode"]   | Immediate |
      | ["parameters"]["zones"] | ''        |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc-with-storageClassName.json"
    When I create a dynamic pvc from "pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | pvc                    |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "pvc" PVC becomes :pending
    When I run the :describe client command with:
      | resource | pvc/pvc |
    Then the step should succeed
    And the output should contain:
      | ProvisioningFailed        |
      | must not contain an empty |

  # @author lxia@redhat.com
  # @case_id OCP-11063
  @admin
  Scenario: Dynamic provision with storageclass which has comma separated list of zones
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["volumeBindingMode"]   | Immediate                   |
      | ["parameters"]["zones"] | us-central1-a,us-central1-b |
    Then the step should succeed
    And I run the steps 10 times:
    """
    Given I obtain test data file "storage/misc/pvc-with-storageClassName.json"
    When I create a dynamic pvc from "pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | pvc-#{cb.i}            |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-#{cb.i}" PVC becomes :bound
    When I run the :get admin command with:
      | resource | pv/<%= pvc.volume_name %> |
      | o        | json                      |
    Then the output should match:
      | us-central1-[ab] |
    """

  # @author lxia@redhat.com
  # @case_id OCP-12834
  @admin
  Scenario: Dynamic provision with storageclass which has parameter zone set with multiple values should fail
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["volumeBindingMode"]  | Immediate                   |
      | ["parameters"]["zone"] | us-central1-a,us-central1-b |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc-with-storageClassName.json"
    When I create a dynamic pvc from "pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | pvc                    |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "pvc" PVC becomes :pending
    When I run the :describe client command with:
      | resource | pvc/pvc |
    Then the step should succeed
    And the output should match:
      | ProvisioningFailed                            |
      | does not .*zone "us-central1-a,us-central1-b" |

  # @author lxia@redhat.com
  # @case_id OCP-12833
  @admin
  Scenario: Dynamic provision with storageclass which has both parameter zone and parameter zones set should fail
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["volumeBindingMode"]   | Immediate                   |
      | ["parameters"]["zone"]  | us-central1-a               |
      | ["parameters"]["zones"] | us-central1-a,us-central1-b |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc-with-storageClassName.json"
    When I create a dynamic pvc from "pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | pvc                    |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "pvc" PVC becomes :pending
    When I run the :describe client command with:
      | resource | pvc/pvc |
    Then the step should succeed
    And the output should contain:
      | ProvisioningFailed                           |
      | parameters must not be used at the same time |

  # @author lxia@redhat.com
  # @case_id OCP-15435
  @admin
  Scenario: Dynamic provision with storageclass which contains invalid parameter should fail
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["volumeBindingMode"]          | Immediate |
      | ["parameters"]["invalidParam"] | test      |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc-with-storageClassName.json"
    When I create a dynamic pvc from "pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | pvc                    |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "pvc" PVC becomes :pending
    When I run the :describe client command with:
      | resource | pvc/pvc |
    Then the step should succeed
    And the output should contain:
      | ProvisioningFailed            |
      | invalid option "invalidParam" |

  # @author lxia@redhat.com
  # @case_id OCP-15429
  @admin
  Scenario: Dynamic provision with storageclass which has zone set to empty string
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["volumeBindingMode"]  | Immediate |
      | ["parameters"]["zone"] | ''        |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc-with-storageClassName.json"
    When I create a dynamic pvc from "pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | pvc                    |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "pvc" PVC becomes :pending
    When I run the :describe client command with:
      | resource | pvc/pvc |
    Then the step should succeed
    And the output should match:
      | ProvisioningFailed                                   |
      | (it's an empty string\|does not have a node in zone) |

  # @author lxia@redhat.com
  # @case_id OCP-13672
  @admin
  Scenario: PV with annotation storage-class bind PVC with annotation storage-class
    Given I have a project
    Given I obtain test data file "storage/hostpath/local-retain.yaml"
    When admin creates a PV from "local-retain.yaml" where:
      | ["metadata"]["name"]                                                   | pv-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | <%= project.name %>    |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc-storageClass.json"
    When I run oc create over "pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                                                   | mypvc               |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | <%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV

  # @author lxia@redhat.com
  # @case_id OCP-13673
  @admin
  Scenario: PV with attribute storageClassName bind PVC with attribute storageClassName
    Given I have a project
    Given I obtain test data file "storage/hostpath/local-retain.yaml"
    When admin creates a PV from "local-retain.yaml" where:
      | ["metadata"]["name"]         | pv-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc-with-storageClassName.json"
    When I run oc create over "pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV

  # @author lxia@redhat.com
  # @case_id OCP-13674
  @admin
  Scenario: PV with annotation storage-class bind PVC with attribute storageClassName
    Given I have a project
    Given I obtain test data file "storage/hostpath/local-retain.yaml"
    When admin creates a PV from "local-retain.yaml" where:
      | ["metadata"]["name"]                                                   | pv-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %> |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc-with-storageClassName.json"
    When I run oc create over "pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV

  # @author lxia@redhat.com
  # @case_id OCP-13675
  @admin
  Scenario: PV with attribute storageClassName bind PVC with annotation storage-class
    Given I have a project
    Given I obtain test data file "storage/hostpath/local-retain.yaml"
    When admin creates a PV from "local-retain.yaml" where:
      | ["metadata"]["name"]         | pv-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc-storageClass.json"
    When I run oc create over "pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                                                   | mypvc                  |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV
