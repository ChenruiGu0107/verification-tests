Feature: samplesoperator

  # @author xiuwang@redhat.com
  # @case_id OCP-22400
  @admin
  @destructive
  Scenario: Samples operator finalizer
    Given admin updated the operator crd "config.samples" managementstate operand to Removed
    And I register clean-up steps:
    """
    admin updated the operator crd "config.samples" managementstate operand to Managed
    """
    And I switch to cluster admin pseudo user
    And I use the "openshift" project
    And I wait for the resource "imagestream" named "ruby" to disappear
    And I wait for the resource "template" named "cakephp-mysql-persistent" to disappear
    When I run the :delete admin command with:
      | object_type       | config.samples |
      | object_name_or_id | cluster        |
    Then the step should succeed
    Then admin waits for the "cluster" config_samples_operator_openshift_io to appear up to 120 seconds
    When I run the :describe admin command with:
      | resource | config.samples.operator.openshift.io |
      | name     | cluster                              |
    Then the step should succeed
    And the output should contain:
      | Management State:  Managed |
    Given I wait for the "ruby" image_stream to appear in the "openshift" project up to 120 seconds
    And I wait for the "cakephp-mysql-persistent" template to appear in the "openshift" project up to 120 seconds

  # @author xiuwang@redhat.com
  # @case_id OCP-20963
  @admin
  @destructive
  Scenario: Can't recreate/update/delete imagestream/template after defined skippedImagestreams and skippedTemplates
    Given as admin I successfully merge patch resource "config.samples.operator.openshift.io/cluster" with:
      | {"spec":{"skippedImagestreams":["jenkins","perl","mysql"],"skippedTemplates":["rails-pgsql-persistent","httpd-example"]}} |
    And I register clean-up steps:
    """
    Given as admin I successfully merge patch resource "config.samples.operator.openshift.io/cluster" with:
      | {"spec":{"skippedImagestreams": null,"skippedTemplates": null,"samplesRegistry": null}} |
    """
    And I switch to cluster admin pseudo user
    And I use the "openshift" project
    When I run the :get client command with:
      | resource | is                                          |
      | l        | samples.operator.openshift.io/managed=false |
    Then the output should contain:
      | jenkins |
      | perl    |
      | mysql   |
    When I run the :get client command with:
      | resource | template                                   |
      | l        | samples.operator.openshift.io/managed=true |
    Then the output should not contain:
      | rails-pgsql-persistent |
      | httpd-example          |
    When I run the :delete admin command with:
      | object_type       | is        |
      | object_name_or_id | perl      |
      | object_name_or_id | php       |
    Then the step should succeed
    When I run the :delete admin command with:
      | object_type       | template               |
      | object_name_or_id | rails-pgsql-persistent |
    Then the step should succeed
    Given I wait for the "php" image_stream to appear up to 60 seconds
    And I wait for the resource "imagestream" named "perl" to disappear
    And I wait for the resource "template" named "rails-pgsql-persistent" to disappear
    Given admin updated the operator crd "config.samples" managementstate operand to Removed
    Then I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | is                                         |
      | l        | samples.operator.openshift.io/managed=true |
    Then the output should match:
      | No resources found. |
    """
    When I run the :get client command with:
      | resource | is                                          |
      | l        | samples.operator.openshift.io/managed=false |
    Then the output should match:
      | jenkins |
      | mysql   |
    Then I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | template                                   |
      | l        | samples.operator.openshift.io/managed=true |
    Then the output should match:
      | No resources found. |
    """
    Given as admin I successfully merge patch resource "config.samples.operator.openshift.io/cluster" with:
      | {"spec":{"samplesRegistry":"test.registry.fake.com","managementState":"Managed"}} |
    Then I wait up to 120 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource  | is        |
      | name      | ruby      |
    Then the step should succeed
    And the output should contain:
      |test.registry.fake.com |
    """
    When I run the :describe client command with:
      | resource  | is        |
      | name      | jenkins   |
    Then the step should succeed
    And the output should not contain:
      |test.registry.fake.com |

  # @author xiuwang@redhat.com
  # @case_id OCP-20962
  @admin
  @destructive
  Scenario: Update imagestreams which managed by samples operator to use other registry
    When as admin I successfully merge patch resource "config.samples.operator.openshift.io/cluster" with:
     | {"spec":{"samplesRegistry":"registry.access.redhat.com"}} |
    And I register clean-up steps:
    """
    Given as admin I successfully merge patch resource "config.samples.operator.openshift.io/cluster" with:
     | {"spec":{"samplesRegistry": null}} |
    """
    Then I wait up to 120 seconds for the steps to pass:
    """
    Then the expression should be true> image_stream("ruby", project("openshift")).tag_statuses(cached: false, user: admin).first.imageref.uri.include? "registry.access.redhat.com"
    """

  # @author xiuwang@redhat.com
  # @case_id OCP-23654
  Scenario: oc explain with samples operator crd
    When I run the :explain client command with:
      | resource    | configs                          |
      | api_version | samples.operator.openshift.io/v1 |
    Then the step should succeed
    And the output should contain:
      | Config contains the configuration and detailed condition status for the |
      | Samples Operator                                                        |
      | ConfigSpec contains the desired configuration and state for the Samples |
      | Operator                                                                |
      | ConfigStatus contains the actual configuration in effect                |

  # @author xiuwang@redhat.com
  # @case_id OCP-27315
  @admin
  Scenario: Bootstrap Samples Operator as Managed when proxy is configured
    When I run the :logs admin command with:
      | resource_name | deployment/cluster-samples-operator |
      | namespace     | openshift-cluster-samples-operator  |
      | c             | cluster-samples-operator            |
    And the output should contain:
      | with global proxy configured assuming registry.redhat.io is accessible, bootstrap to Managed |
    When I run the :describe admin command with:
      | resource | config.samples.operator.openshift.io |
      | name     | cluster                              |
    Then the step should succeed
    And the output should contain:
      | Management State:  Managed |

  # @author xiuwang@redhat.com
  # @case_id OCP-27102
  @admin
  Scenario: Bootstrap Samples Operator as Removed when TBR inaccessible
    When I run the :logs admin command with:
      | resource_name | deployment/cluster-samples-operator |
      | namespace     | openshift-cluster-samples-operator  |
      | c             | cluster-samples-operator            |
    And the output should contain:
      | test connection to registry.redhat.io failed                                                     |
      | unable to establish HTTPS connection to registry.redhat.io after 3 minutes, bootstrap to Removed |

  # @author xiuwang@redhat.com
  # @case_id OCP-21527
  @admin
  @destructive
  Scenario: openshift-samples co status update
    Given admin updated the operator crd "config.samples" managementstate operand to Unmanaged
    And I register clean-up steps:
    """
    admin updated the operator crd "config.samples" managementstate operand to Managed
    """
    Then I wait up to 120 seconds for the steps to pass:
    """
    And the expression should be true> cluster_operator('openshift-samples').condition(cached: false, type: 'Available')['reason'] == "CurrentlyUnmanaged"
    And the expression should be true> cluster_operator('openshift-samples').condition(cached: false, type: 'Progressing')['reason'] == "CurrentlyUnmanaged"
    And the expression should be true> cluster_operator('openshift-samples').condition(cached: false, type: 'Degraded')['reason'] == "CurrentlyUnmanaged"
    """
    Given admin updated the operator crd "config.samples" managementstate operand to Removed
    Then I wait up to 120 seconds for the steps to pass:
    """
    And the expression should be true> cluster_operator('openshift-samples').condition(cached: false, type: 'Available')['reason'] == "CurrentlyRemoved"
    And the expression should be true> cluster_operator('openshift-samples').condition(cached: false, type: 'Progressing')['reason'] == "CurrentlyRemoved"
    And the expression should be true> cluster_operator('openshift-samples').condition(cached: false, type: 'Degraded')['reason'] == "CurrentlyRemoved"
    """

  # @author xiuwang@redhat.com
  # @case_id OCP-35997
  @admin
  @destructive
  Scenario: imagestreamtag-to-image configmap contains all images managed by samples operator
    And I switch to cluster admin pseudo user
    And I use the "openshift-cluster-samples-operator" project
    When I get project configmap named "imagestreamtag-to-image" as JSON
    Then the output should contain:
      | registry.redhat.io/rhscl/ruby  |
      | registry.redhat.io/rhscl/mysql |
    Given evaluation of `@result[:parsed]['metadata']['creationTimestamp']` is stored in the :creation1 clipboard
    Given admin updated the operator crd "config.samples" managementstate operand to Removed
    And I register clean-up steps:
    """
    admin updated the operator crd "config.samples" managementstate operand to Managed
    """
    When I get project configmap named "imagestreamtag-to-image" as JSON
    Given evaluation of `@result[:parsed]['metadata']['creationTimestamp']` is stored in the :creation2 clipboard
    And the expression should be true> cb.creation1 == cb.creation2
    When I run the :delete admin command with:
      | object_type       | config.samples |
      | object_name_or_id | cluster        |
    Then the step should succeed
    Then I wait up to 300 seconds for the steps to pass:
    """
    Given I get project configmaps
    Then the output should contain:
      | ruby | 
    """
    Then admin waits for the "cluster" config_samples_operator_openshift_io to appear up to 120 seconds
    When I get project configmap named "imagestreamtag-to-image" as JSON
    Given evaluation of `@result[:parsed]['metadata']['creationTimestamp']` is stored in the :creation3 clipboard
    And the expression should be true> cb.creation3 == cb.creation1
    And I wait for the resource "configmap" named "ruby" to disappear

  # @case_id OCP-35999
  @admin
  Scenario: Configmap operation for skip imagestreams and fail import imagestream
    Given I switch to cluster admin pseudo user
    And I use the "openshift-cluster-samples-operator" project
    Given I get project configmaps
    Then the output should contain:
      | ruby  | 
      | httpd | 
    Then the output should not contain:
      | php  | 
      | perl | 
    When I run the :describe admin command with:
      | resource | config.samples.operator.openshift.io |
      | name     | cluster                              |
    Then the step should succeed
    And the output should not contain:
      | ruby  | 
      | httpd | 
    Given I switch to the first user
    And I have a project
    When I run the :new_app client command with:
      | template | mysql-ephemeral |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deploymentconfig=mysql |
