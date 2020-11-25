Feature: template related scenarios:

  # @author pruan@redhat.com
  # @case_id OCP-12131
  Scenario: template with code explicitly attached should not be supported when creating app with template via cli
    Given I have a project
    Given I obtain test data file "templates/ui/application-template-stibuild-without-customize-route.json"
    And I run the :create client command with:
      | filename | application-template-stibuild-without-customize-route.json |
    Then the step should succeed
    And I run the :get client command with:
      | resource | template |
    Then the output should contain:
      | ruby-helloworld-sample |
    And I create a new application with:
      | template | ruby-helloworld-sample~git@github.com:openshift/ruby-hello-world.git |
    And the step should fail
    And the output should contain:
      | rror: template with source code explicitly attached is not supported |
    And I create a new application with:
      | template | ruby-helloworld-sample               |
      | code     | git://github.com/sclorg/nodejs-ex |
    Then the step should succeed
  # @author pruan@redhat.com
  # @case_id OCP-12032
  Scenario: create app from non-existing/invalid template via CLI
    Given I have a project
    And I run the :new_app client command with:
      | template | I_do_no_exist |
    Then the step should fail
    And the output should contain:
      | error                   |
      | I_do_no_exist |
    And I obtain test data file "templates/ui/application-template-stibuild-without-customize-route.json"
    # activate/install the template to the project
    And I run the :create client command with:
      | filename | application-template-stibuild-without-customize-route.json |
    Then the step should succeed
    And I run the :new_app client command with:
      | template | ruby-helloworld-sample |
    Then the step should succeed

  # @author pruan@redhat.com
  # @case_id OCP-9562
  Scenario: Create app from template containing invalid type - cli
    Given I have a project
    And I obtain test data file "templates/ocp9562/application-template-stibuild.json"
    And I run the :create client command with:
      | filename | application-template-stibuild.json |
    Then the step should succeed
    And I run the :new_app client command with:
      | template | ruby-helloworld-sample-ocp9562 |
    Then the step should fail

    # Due to bug 1245528, the output is not stable, do fuzzy check about the info for now.
    And the output should contain:
      | error |

  # @author cryan@redhat.com
  # @case_id OCP-12466
  # @bug_id 1330323
  Scenario: Add arbitrary labels to all objects during template processing
    Given I have a project
    Given I obtain test data file "build/ruby22rhel7-template-sti.json"
    Given an 8 characters random string of type :dns is stored into the :lbl1 clipboard
    Given I replace lines in "ruby22rhel7-template-sti.json":
      | "template": "application-template-stibuild" | "<%= cb.lbl1 %>": "application-template-stibuild" |
    When I process and create "ruby22rhel7-template-sti.json"
    Then the step should succeed
    Given the "ruby-sample-build-1" build completes
    When I run the :get client command with:
      | resource | services |
      | l | <%= cb.lbl1 %>=application-template-stibuild |
    Then the output should contain:
      | database |
      | frontend |
    When I run the :get client command with:
      | resource | buildconfigs |
      | l | <%= cb.lbl1 %>=application-template-stibuild |
    Then the output should contain:
      | ruby-sample-build |
    When I run the :get client command with:
      | resource | deploymentconfigs |
      | l | <%= cb.lbl1 %>=application-template-stibuild |
    Then the output should contain:
      | database |
      | frontend |
    When I run the :get client command with:
      | resource | builds |
      | l | <%= cb.lbl1 %>=application-template-stibuild |
    Then the output should contain:
      | ruby-sample-build-1 |
    When I run the :get client command with:
      | resource | is |
      | l | <%= cb.lbl1 %>=application-template-stibuild |
    Then the output should contain:
      | origin-ruby-sample |
    When I run the :get client command with:
      | resource | routes |
      | l | <%= cb.lbl1 %>=application-template-stibuild |
    Then the output should contain:
      | route-edge |
    Given I replace lines in "ruby22rhel7-template-sti.json":
      | "<%= cb.lbl1 %>": "application-template-stibuild" | "label!!": "value1" |
    When I process and create "ruby22rhel7-template-sti.json"
    Then the step should fail
    Given I replace lines in "ruby22rhel7-template-sti.json":
      | "label!!": "value1" | "-test": "value2" |
    When I process and create "ruby22rhel7-template-sti.json"
    Then the step should fail
    Given I replace lines in "ruby22rhel7-template-sti.json":
      | "-test": "value2" | "test/one/two": "value3" |
    When I process and create "ruby22rhel7-template-sti.json"
    Then the step should fail
    Given I replace lines in "ruby22rhel7-template-sti.json":
      | "test/one/two": "value3" | "test-/one": "value4" |
    When I process and create "ruby22rhel7-template-sti.json"
    Then the step should fail

  # @author cryan@redhat.com
  # @case_id OCP-10929
  Scenario: Do not show user getting start info after processing a template without Message defined
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    When I get project templates
    Then the output should contain "ruby-helloworld-sample"
    When I run the :describe client command with:
      | resource | template               |
      | name     | ruby-helloworld-sample |
    Then the output should match "Message:\s+<none>"
    When I run the :process client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    And the output should not contain "message:"
    When I run the :patch client command with:
      | resource      | template                  |
      | resource_name | ruby-helloworld-sample    |
      | p             | {"message":"TestString1"} |
    Then the step should succeed
    Given I get project template named "ruby-helloworld-sample" as JSON
    Then the output should match ""message": "TestString1""
    When I run the :process client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    Then the output should not match ""message": "TestString1""

  # @author cryan@redhat.com
  # @case_id OCP-11337
  Scenario: Show multi user getting start info after new-app multi templates with Message defined
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/jenkins-ephemeral-template.json |
    Then the step should succeed
    When I run the :process client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    And the output should not contain "message:"
    When I run the :patch client command with:
      | resource      | template                  |
      | resource_name | ruby-helloworld-sample    |
      | p             | {"message":"Your admin credentials are ${ADMIN_USERNAME}:${ADMIN_PASSWORD}"} |
    Then the step should succeed
    Given I get project template named "ruby-helloworld-sample" as JSON
    Then the output should contain "Your admin credentials are"
    When I run the :new_app client command with:
      | template | jenkins-ephemeral,ruby-helloworld-sample |
    Then the step should succeed
    And the output should contain:
      | Your admin credentials are |

  # @author cryan@redhat.com
  # @case_id OCP-11627
  Scenario: Show user getting start info after new-app a template with message defined
    Given I have a project
    Given I obtain test data file "templates/application-template-stibuild.json"
    When I run the :create client command with:
      | f | application-template-stibuild.json |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | template                  |
      | resource_name | ruby-helloworld-sample    |
      | p             | {"message":"Your admin credentials are ${ADMIN_USERNAME}:${ADMIN_PASSWORD}"} |
    Then the step should succeed
    Given I get project template named "ruby-helloworld-sample" as JSON
    Then the output should contain "Your admin credentials are"
    When I run the :describe client command with:
      | resource | template               |
      | name     | ruby-helloworld-sample |
    Then the output should match "Message:\s+Your admin credentials are"
    When I run the :new_app client command with:
      | template | ruby-helloworld-sample |
    Then the step should succeed
    And the output should contain:
      | Your admin credentials are |

  # @author cryan@redhat.com
  # @case_id OCP-11822
  Scenario: Show user getting start info after processing a template with message defined
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | template                  |
      | resource_name | ruby-helloworld-sample    |
      | p             | {"message":"Your admin credentials are ${ADMIN_USERNAME}:${ADMIN_PASSWORD}"} |
    Then the step should succeed
    Given I get project template named "ruby-helloworld-sample" as JSON
    Then the output should contain "Your admin credentials are"
    When I run the :describe client command with:
      | resource | template               |
      | name     | ruby-helloworld-sample |
    Then the output should match "Message:\s+Your admin credentials are"
    When I run the :process client command with:
      | template | ruby-helloworld-sample |
    Then the output should not match:
      | [m\|M]essage:              |
      | Your admin credentials are |

  # @author cryan@redhat.com
  # @case_id OCP-10223
  # @bug_id 1248362
  Scenario: new-app with template/imagestream from the exact namespace
    Given I have a project
    When I run the :tag client command with:
      | source      | openshift/hello-openshift |
      | dest        | mongodb:latest            |
      | source_type | docker                    |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | template           |
      | resource_name | mongodb-persistent |
      | n             | openshift          |
      | export        | true               |
      | output        | yaml               |
    Then the step should succeed
    Given I save the output to file> newtemplate.yaml
    When I run the :create client command with:
      | f | newtemplate.yaml |
    Then the step should succeed
    # imagestream from exact namespace
    When I run the :new_app client command with:
      | app_repo | openshift/mongodb:latest |
      | dry_run  | true                     |
    Then the step should succeed
    And the output should contain "openshift"
    When I run the :new_app client command with:
      | app_repo | <%= project.name %>/mongodb:latest |
      | dry_run  | true                               |
    Then the step should succeed
    And the output should contain "<%= project.name %>"
    # template from exact namespace
    When I run the :new_app client command with:
      | app_repo | openshift/mongodb-persistent |
      | dry_run  | true                         |
    Then the step should succeed
    And the output should contain "openshift"
    When I run the :new_app client command with:
      | app_repo | <%= project.name %>/mongodb-persistent |
      | dry_run  | true                                   |
    Then the step should succeed
    And the output should contain "<%= project.name %>"

  # @author xiuwang@redhat.com
  # @case_id OCP-23251
  Scenario: Deal with crd resources with new-app
    Given I have a project
    Given I obtain test data file "build/OCP-23251/template-with-crd.yaml"
    And I run the :new_app client command with:
      | source_spec | template-with-crd.yaml |
    And the output should contain:
      | oc process -f <template> \| oc create |
    Then the step should fail
    Given I obtain test data file "build/OCP-23251/template-with-crd.yaml"
    And I run the :new_app client command with:
      | file | template-with-crd.yaml |
    Then the step should fail
    And the output should contain:
      | oc process -f <template> \| oc create |
