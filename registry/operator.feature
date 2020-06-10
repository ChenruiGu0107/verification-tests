Feature: Testing image registry operator

  # @author wzheng@redhat.com
  # @case_id OCP-21593
  @admin
  @destructive
  Scenario:Check registry status by changing managementState for image-registry
    Given I switch to cluster admin pseudo user
    Given admin updated the operator crd "configs.imageregistry" managementstate operand to Removed
    Then the step should succeed
    And I register clean-up steps:
    """
    Given admin updated the operator crd "configs.imageregistry" managementstate operand to Managed
    """
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource  | pods                     |
      | namespace | openshift-image-registry |
    And the output should not match:
      | ^image-registry |
    """
    Given admin updated the operator crd "configs.imageregistry" managementstate operand to Managed
    Then the step should succeed
    Given I use the "openshift-image-registry" project
    And a pod becomes ready with labels:
      | docker-registry=default |
    When I run the :patch client command with:
      | resource      | configs.imageregistry.operator.openshift.io |
      | resource_name | cluster                                     |
      | p             | {"spec":{"logging":8}}                      |
      | type          | merge                                       |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :set_env client command with:
      | resource  | pod                      |
      | all       | true                     |
      | list      | true                     |
      | namespace | openshift-image-registry |
    And the output should contain:
      | REGISTRY_LOG_LEVEL=debug |
    """

    # Check when managementState is Unmanaged, nothing change will take effect

    When I run the :patch client command with:
      | resource      | configs.imageregistry          |
      | resource_name | cluster                                              |
      | p             | {"spec":{"managementState":"Unmanaged","logging":2}} |
      | type          | merge                                                |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource  | pod                      |
      | all       | true                     |
      | list      | true                     |
      | namespace | openshift-image-registry |
    And the output should contain:
      | REGISTRY_LOG_LEVEL=debug |

  # @author wzheng@redhat.com
  # @case_id OCP-22031
  @admin
  @destructive
  Scenario: Config CPU and memory for internal registry
    Given I switch to cluster admin pseudo user
    When I use the "openshift-image-registry" project
    Given current generation number of "image-registry" deployment is stored into :before_change clipboard
    Given as admin I successfully merge patch resource "configs.imageregistry.operator.openshift.io/cluster" with:
      | {"spec":{"resources":{"limits":{"cpu":"100m","memory":"512Mi"}}}} |
    And I register clean-up steps:
    """
    Given as admin I successfully merge patch resource "configs.imageregistry.operator.openshift.io/cluster" with:
      | {"spec":{"resources":null}} | 
    """
    And I wait for the steps to pass:
    """
    Given current generation number of "image-registry" deployment is stored into :after_change clipboard
    And the expression should be true> cb.after_change - cb.before_change >=1
    Given a pod becomes ready with labels:
      | docker-registry=default |
    """
    When I get project config_imageregistry_operator_openshift_io named "cluster" as YAML
    Then the output should contain:
      | cpu: 100m     |
      | memory: 512Mi |

  # @author wzheng@redhat.com
  # @case_id OCP-22032
  @admin
  @destructive
  Scenario: Config NodeSelector for internal registry
    Given I switch to cluster admin pseudo user
    Given as admin I successfully merge patch resource "configs.imageregistry.operator.openshift.io/cluster" with:
      | {"spec":{"nodeSelector":{"node-role.kubernetes.io/master": "abc"}}} |
    And I register clean-up steps:
    """
    Given as admin I successfully merge patch resource "configs.imageregistry.operator.openshift.io/cluster" with:
      | {"spec":{"nodeSelector":null}} |
    """
    When I use the "openshift-image-registry" project
    When I run the :describe client command with:
      | resource | pod                     |
      | l        | docker-registry=default |
    Then the output should contain:
      | node-role.kubernetes.io/master=abc |
      | didn't match node selector         |

  # @author xiuwang@redhat.com
  # @case_id OCP-23651
  Scenario: oc explain work for image-registry operator
    When I run the :explain client command with:
      | resource    | configs                                |
      | api_version | imageregistry.operator.openshift.io/v1 |
    Then the step should succeed
    And the output should contain:
      | Config is the configuration object for a registry instance managed by the |
      | registry operator                                                         |
      | ImageRegistrySpec defines the specs for the running registry.             |
      | ImageRegistryStatus reports image registry operational status             |

  # @author xiuwang@redhat.com
  # @case_id OCP-24353
  @admin
  @destructive
  Scenario: Registry operator storage setup - Azure
    Given a 4 characters random string of type :dns is stored into the :short_nm clipboard
    Given a 25 characters random string of type :dns is stored into the :longer_nm clipboard
    Given I switch to cluster admin pseudo user
    When I use the "openshift-image-registry" project
    When I get project secret named "image-registry-private-configuration" as YAML
    Then the output should contain:
      | REGISTRY_STORAGE_AZURE_ACCOUNTKEY |
    When I get project secret named "installer-cloud-credentials" as YAML
    Then the output should contain:
      | azure_client_secret |
      | azure_region        |
    When I run the :describe client command with:
      | resource | config.imageregistry.operator.openshift.io |
      | name     | cluster|
    Then the output should contain:
      | Azure                    |
      | Storage container exists |
    And evaluation of `deployment("image-registry").generation_number(cached: false)` is stored in the :before_change clipboard
    And a pod becomes ready with labels:
      | docker-registry=default |
    And I successfully merge patch resource "config.imageregistry.operator.openshift.io/cluster" with:
      | {"spec":{"storage":{"azure":{"accountName":"<%= cb.short_nm %>"}}}} |
    And I register clean-up steps:
    """
    When I get project config_imageregistry_operator_openshift_io named "cluster" as YAML
    And evaluation of `@result[:parsed]['spec']['storage']['azure']['container']` is stored in the :cont clipboard
    And evaluation of `@result[:parsed]['spec']['storage']['azure']['accountName']` is stored in the :aname clipboard
    Given I save the output to file> imageregistry.yaml
    And I replace lines in "imageregistry.yaml":
      | accountName: <%= cb.aname %> | accountName: |
      | container: <%= cb.cont %>    | container:   |
    When I run the :apply client command with:
      | f | imageregistry.yaml |
    Then the step should succeed
    """
    And I wait for the steps to pass:
    """
    And evaluation of `deployment("image-registry").generation_number(cached: false)` is stored in the :after_change clipboard
    And the expression should be true> cb.after_change - cb.before_change >=1
    """
    And I wait for the pod to die regardless of current status
    And a pod becomes ready with labels:
      | docker-registry=default |
    When I run the :describe client command with:
      | resource | config.imageregistry.operator.openshift.io |
      | name     | cluster                                    |
    Then the output should contain:
      | Account Name:  <%= cb.short_nm %> |
    And I successfully merge patch resource "config.imageregistry.operator.openshift.io/cluster" with:
      | {"spec":{"storage":{"azure":{"accountName":"<%= cb.longer_nm %>"}}}} |
    When I get project config_imageregistry_operator_openshift_io named "cluster" as YAML
    Then the output should contain:
      | AzureError |
    And evaluation of `@result[:parsed]['spec']['storage']['azure']['container']` is stored in the :container clipboard
    Given I save the output to file> imageregistry.yaml
    And I replace lines in "imageregistry.yaml":
      | accountName: <%= cb.longer_nm %> | accountName: |
      | container: <%= cb.container %>   | container:   |
    When I run the :apply client command with:
      | f | imageregistry.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    And evaluation of `deployment("image-registry").generation_number(cached: false)` is stored in the :third_change clipboard
    And the expression should be true> cb.third_change - cb.after_change >=1
    """
    And I wait for the pod to die regardless of current status
    And a pod becomes ready with labels:
      | docker-registry=default |
    When I run the :describe client command with:
      | resource | config.imageregistry.operator.openshift.io |
      | name     | cluster                                    |
    Then the output should contain:
      | Storage container exists |

  # @author xiuwang@redhat.com
  # @case_id OCP-22945
  @admin
  @destructive
  Scenario: Autoconfigure registry storage on AWS-UPI
    Given a 25 characters random string of type :dns is stored into the :custom_nm clipboard
    Given I switch to cluster admin pseudo user
    When I use the "openshift-image-registry" project
    When I get project secret named "image-registry-private-configuration" as YAML
    Then the output should contain:
      | REGISTRY_STORAGE_S3_ACCESSKEY |
      | REGISTRY_STORAGE_S3_SECRETKEY |
    When I get project secret named "installer-cloud-credentials" as YAML
    Then the output should contain:
      | aws_access_key_id     |
      | aws_secret_access_key |
    When I run the :describe client command with:
      | resource | config.imageregistry.operator.openshift.io |
      | name     | cluster                                    |
    Then the output should contain:
      | S3 Bucket Exists |
    And evaluation of `deployment("image-registry").generation_number(cached: false)` is stored in the :before_change clipboard
    And a pod becomes ready with labels:
      | docker-registry=default |
    And I successfully merge patch resource "config.imageregistry.operator.openshift.io/cluster" with:
      | {"spec":{"storage":{"s3":{"bucket":"<%= cb.custom_nm %>"}}}} |
    And I wait for the steps to pass:
    """
    And evaluation of `deployment("image-registry").generation_number(cached: false)` is stored in the :after_change clipboard
    And the expression should be true> cb.after_change - cb.before_change >=1
    """
    And I wait for the pod to die regardless of current status
    And a pod becomes ready with labels:
      | docker-registry=default |
    When I get project config_imageregistry_operator_openshift_io named "cluster" as YAML
    Then the output should contain:
      | bucket: <%= cb.custom_nm %> |
    Given I save the output to file> imageregistry.yaml
    And I replace lines in "imageregistry.yaml":
      | bucket: <%= cb.custom_nm %> | |
    When I run the :replace client command with:
      | f | imageregistry.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | config.imageregistry.operator.openshift.io |
      | name     | cluster                                    |
    Then the output should contain:
      | S3 Bucket Exists |
    And the output should not contain:
      | bucket: <%= cb.custom_nm %> |

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
    When I get project imagepruners_imageregistry_operator_openshift_io named “cluster” as YAML                                            |
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
  # @case_id OCP-24133
  @admin
  @destructive
  Scenario: TLS can be added to user-defined registry route
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-image-registry" project
    When I run the :create_secret client command with:
      | cert        | <%= BushSlicer::HOME %>/features/tierN/testdata/registry/myregistry.crt |
      | key         | <%= BushSlicer::HOME %>/features/tierN/testdata/registry/myregistry.key |
      | secret_type | tls                                                                     |
      | name        | my-tls                                                                  |
    Then the step should succeed
    Given as admin I successfully merge patch resource "configs.imageregistry.operator.openshift.io/cluster" with:
      | {"spec":{"routes":[{"hostname":"myroute-image-registry.openshift.com","name": "myroute","secretName": "my-tls"}]}} |
    And the expression should be true> route('myroute').spec.tls_certificate != ""
    And the expression should be true> route('myroute').spec.tls_key != ""

  # @author wzheng@redhat.com
  # @case_id OCP-24100
  @admin
  @destructive
  Scenario: Registry OpenStack Storage - UPI	
    Given I switch to cluster admin pseudo user
    When I use the "openshift-image-registry" project
    And evaluation of `deployment("image-registry").generation_number(cached: false)` is stored in the :before_change clipboard
    When I get project secret named "image-registry-private-configuration" as YAML
    Then the output should contain:
      | REGISTRY_STORAGE_SWIFT_PASSWORD |
      | REGISTRY_STORAGE_SWIFT_USERNAME |
    When I get project secret named "installer-cloud-credentials" as YAML
    Then the output should contain:
      | clouds.yaml |
    When I run the :describe client command with:
      | resource | config.imageregistry.operator.openshift.io |
      | name     | cluster                                    |
    Then the output should contain:
      | Swift container Exists |
    When I get project config_imageregistry_operator_openshift_io named "cluster" as YAML
    And evaluation of `@result[:parsed]['spec']['storage']['swift']['container']` is stored in the :old_name clipboard
    When I run the :patch client command with:
      | resource      | configs.imageregistry                             |
      | resource_name | cluster                                           |
      | p             | {"spec":{"storage":{"swift":{"container":null}}}} |
      | type          | merge                                             |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    And evaluation of `deployment("image-registry").generation_number(cached: false)` is stored in the :after_change clipboard
    And the expression should be true> cb.after_change - cb.before_change >=1
    And a pod becomes ready with labels:
      | docker-registry=default |
    """
    When I get project config_imageregistry_operator_openshift_io named "cluster" as YAML
    And evaluation of `@result[:parsed]['spec']['storage']['swift']['container']` is stored in the :new_name clipboard
    And the expression should be true> cb.old_name != cb.new_name

  # @author xiuwang@redhat.com
  # @case_id OCP-23817
  @admin
  Scenario: Registry operator storage setup
    Given I switch to cluster admin pseudo user
    When I use the "openshift-image-registry" project
    When I get project secret named "image-registry-private-configuration" as YAML
    Then the output should contain:
      | REGISTRY_STORAGE_GCS_KEYFILE |
    When I run the :set_env client command with:
      | resource | deployment/image-registry |
      | list     | true                      |
    Then the step should succeed
    Then the output should contain:
      | REGISTRY_STORAGE=gcs                      |
      | REGISTRY_STORAGE_GCS_BUCKET               |
      | REGISTRY_STORAGE_GCS_KEYFILE=/gcs/keyfile |
    And a pod is present with labels:
      | docker-registry=default |
