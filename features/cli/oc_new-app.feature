Feature: oc new-app related scenarios

  # @author xiaocwan@redhat.com
  # @case_id OCP-10471
  Scenario: oc new-app handle arg variables in Dockerfiles
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://github.com/php-coder/s2i-test#use_arg_directive|
    # not caring if the resule could be succedd or not, only to test if $VAR is valid
    And the output should not contain:
      | parsing        |
      | invalid syntax |

  # @author yapei@redhat.com
  # @case_id OCP-12255
  Scenario: cli:parameter requirement check works correctly
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    Given I backup the file "application-template-stibuild.json"
    And I replace lines in "application-template-stibuild.json":
      | "value": "root" | "value": "" |
    When I run the :new_app client command with:
      | file | application-template-stibuild.json |
    Then the step should fail
    And the output should match:
      | [Ee]rror.*is required and must be specified |
    
    Given I restore the file "application-template-stibuild.json"
    When I run oc create over "application-template-stibuild.json" replacing paths:
      | ["parameters"][0]["required"] | false |
    Then the step should succeed
    When I run the :new_app client command with:
      | template | ruby-helloworld-sample |
    Then the step should succeed

  # @author xiuwang@redhat.com
  # @case_id OCP-12774
  Scenario: oc new-app/new-build should respect ImageStream hidden tag	
    Given I have a project
    When I run the :new_app client command with:
      | search_raw | ruby |
    And the output should contain:
      | Project: openshift |
      | 2.2, 2.3           |
    And the output should not contain:
      | 2.0 |
    When I run the :new_app client command with:
      | image_stream | ruby:2.0 |
      | app_repo | https://github.com/openshift/ruby-hello-world |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | bc               |
      | name     | ruby-hello-world |
    Then the output should match "ImageStreamTag openshift/ruby:2.0"
    When I run the :new_build client command with:
      | image_stream | ruby:2.0 |
      | app_repo | https://github.com/openshift/ruby-ex |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | bc      |
      | name     | ruby-ex |
    Then the output should match "ImageStreamTag openshift/ruby:2.0"
