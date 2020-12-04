Feature: oc_set_image_lookup

  # @author wzheng@redhat.com
  # @case_id OCP-24160
  Scenario: lookupPolicy can be set by oc set image-lookup	
    When I have a project
    And I run the :import_image client command with:
      | image_name   | myimage                       |
      | from         | quay.io/openshifttest/busybox |
      | confirm      | true                          |
    Then the step should succeed
    And I run the :set_image_lookup client command with:
      | image_stream | myimage |
    Then the step should succeed
    When I get project is named "myimage" as YAML
    And the output should match:
      | lookupPolicy |
      | local: true  |
    And I run the :new_app client command with:
      | template | mysql-ephemeral |
    Then the step should succeed
    And I run the :set_image_lookup client command with:
      | deployment | dc/mysql |
    Then the step should succeed
    When I get project dc named "mysql" as YAML
    And the output should match:
      | alpha.image.policy.openshift.io/resolve-names: '*' |
