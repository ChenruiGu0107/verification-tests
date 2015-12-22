Feature: template related scnearios:

  # @author pruan@redhat.com
  # @case_id 483165
  Scenario: template with code explicitly attached should not be supported when creating app with template via cli
    Given I have a project
    And I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    And I run the :get client command with:
      | resource | template |
    Then the output should contain:
      | ruby-helloworld-sample   This example shows how to create a simple ruby application in openshift origi...   5 (4 generated)   8 |
    And I create a new application with:
      | template | ruby-helloworld-sample~git@github.com/openshift/ruby-hello-world.git |
    And the step should fail
    And the output should contain:
      | error: template with source code explicitly attached is not supported - you must either specify the template and source code separately or attach an image to the source code using the '[image]~[code]' form |
    And I create a new application with:
      | template | ruby-helloworld-sample |
      | code     | git://github.com/openshift/nodejs-ex |
    Then the step should succeed

  # @author pruan@redhat.com
  # @case_id 483164
  Scenario: create app from non-existing/invalid template via CLI
    Given I have a project
    And I run the :new_app client command with:
      | template | I_do_no_exist |
    Then the step should fail
    And the output should contain:
      |  error: no match for "I_do_no_exist"|
    And I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    # activate/install the template to the project
    And I run the :create client command with:
      | filename | application-template-stibuild.json |
    Then the step should succeed
    And I run the :new_app client command with:
      | template | ruby-helloworld-sample |
    Then the step should succeed

  # @author pruan@redhat.com
  # @case_id 497538
  Scenario: Create app from template containing invalid type - cli
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc497538/application-template-stibuild.json"
    And I run the :create client command with:
      | filename | application-template-stibuild.json |
    Then the step should succeed
    And I run the :new_app client command with:
      | template | ruby-helloworld-sample |
    Then the step should fail
    And the output should contain:
      | Error: unable to get type info from the object "*runtime.Unknown": no kind is registered for the type runtime.Unknown |

