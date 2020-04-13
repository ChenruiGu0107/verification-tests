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
    And admin ensures "cluster" config_samples_operator_openshift_io is deleted after scenario
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
     | {"spec":{"samplesRegistry":""}} |
    """
    Then I wait up to 60 seconds for the steps to pass:
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
