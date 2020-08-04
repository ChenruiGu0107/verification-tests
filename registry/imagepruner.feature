Feature: Testing image pruner

  # @author wzheng@redhat.com
  # @case_id OCP-27588
  @admin
  @destructive
  Scenario: ManagementState setting in Image registry operator config can influence image prune
    Given admin updated the operator crd "configs.imageregistry" managementstate operand to Managed
    When I run the :describe admin command with:
      | resource  | cronjob.batch            |
      | name      | image-pruner             |
      | namespace | openshift-image-registry |
    Then the step should succeed
    Then the output should contain:
      | -certificate-authority  |
      | --keep-tag-revisions=3  |
      | --keep-younger-than=60m |
      | --prune-registry=true   |
      | --confirm=true          |
    Given admin updated the operator crd "configs.imageregistry" managementstate operand to Unmanaged
    And I register clean-up steps:
    """
    Given admin updated the operator crd "configs.imageregistry" managementstate operand to Managed
    """
    When I run the :describe admin command with:
      | resource  | cronjob.batch            |
      | name      | image-pruner             |
      | namespace | openshift-image-registry |
    Then the step should succeed
    Then the output should contain:
      | --prune-registry=false |

  # @author wzheng@redhat.com
  # @case_id OCP-27577
  Scenario: Explain and check the custom resource definition for the prune
    When I run the :explain client command with:
      | resource    | imagepruners                           |
      | api_version | imageregistry.operator.openshift.io/v1 |
    Then the step should succeed
    And the output should contain:
      | ImagePruner is the configuration object for an image registry pruner |
      | ImagePrunerSpec defines the specs for the running image pruner       |
      | ImagePrunerStatus reports image pruner operational status            |

  # @author wzheng@redhat.com
  # @case_id OCP-27576
  @admin
  Scenario: CronJob is added to automate image prune	
    Given I switch to cluster admin pseudo user
    When I use the "openshift-image-registry" project 
    When I get project image_pruner_imageregistry_operator_openshift_io named "cluster" as YAML
    Then the output should contain:
      | failedJobsHistoryLimit: 3     |
      | keepTagRevisions: 3           |
      | schedule: ""                  |
      | successfulJobsHistoryLimit: 3 |
      | suspend: false                |
    Given I save the output to file> imagepruners.yaml
    And I replace lines in "imagepruners.yaml":
      | keepTagRevisions: 3       | keepTagRevisions: 1       |
      | failedJobsHistoryLimit: 3 | failedJobsHistoryLimit: 1 |
      | schedule: ""              |  schedule: "* * * * *"    | 
    When I run the :apply client command with:
      | f | imagepruners.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | imagepruners.imageregistry.operator.openshift.io |
      | name     | cluster                                          |
    Then the output should contain:
      | Failed Jobs History Limit:      1         |
      | Keep Tag Revisions:             1         |
      | Schedule:                       * * * * * |
    When I run the :get client command with:
      | resource | pods |
    Then the output should contain:
      | image-pruner |


  # @author wzheng@redhat.com
  # @case_id OCP-32329
  @admin
  @destructive
  Scenario: keepYoungerThanDuration can be defined for image-pruner
    Given I switch to cluster admin pseudo user
    When I use the "openshift-image-registry" project
    Given as admin I successfully merge patch resource "imagepruners.imageregistry.operator.openshift.io/cluster" with:
      | {"spec": {"keepYoungerThan": 60}} |
    And I register clean-up steps:
    """
    Given as admin I successfully merge patch resource "imagepruners.imageregistry.operator.openshift.io/cluster" with:
      | {"spec": {"keepYoungerThan":null ,"keepYoungerThanDuration":null}} |
    """
    When I run the :describe admin command with:
      | resource  | cronjob.batch            |
      | name      | image-pruner             |
      | namespace | openshift-image-registry |
    Then the step should succeed
    Then the output should contain:
      | --keep-younger-than=60ns |
    Given as admin I successfully merge patch resource "imagepruners.imageregistry.operator.openshift.io/cluster" with:
      | {"spec": {"keepYoungerThanDuration": "90s"}} |
    When I run the :describe admin command with:
      | resource  | cronjob.batch            |
      | name      | image-pruner             |
      | namespace | openshift-image-registry |
    Then the step should succeed
    Then the output should contain:
      | --keep-younger-than=1m30s |
