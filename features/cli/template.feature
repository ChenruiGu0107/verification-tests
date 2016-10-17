Feature: template related scenarios:

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
      | template | ruby-helloworld-sample~git@github.com:openshift/ruby-hello-world.git |
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
      | error                   |
      | I_do_no_exist |
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
      | template | ruby-helloworld-sample-tc497538 |
    Then the step should fail

    # Due to bug 1245528, the output is not stable, do fuzzy check about the info for now.
    And the output should contain:
      | error |

  # @author akostadi@redhat.com
  # @case_id 476351
  Scenario Outline: Easy delete resources from template created
    Given I have a project
    And I process and create:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby20rhel7-template-sti.json|
      |l|<labels>|
    And the step succeeded

    When I get project services with labels:
      | <labels> |
    Then the step should succeed
    And the output should contain:
      | database                               |
      | frontend                               |

    # https://bugzilla.redhat.com/show_bug.cgi?id=1293973
    # Given 3 pods become ready with labels:
    #  | <labels> |
    # When I get project pods with labels:
    #  | <labels> |
    # Then the step should succeed
    # And the output should contain:
    #   |frontend-1|
    #   |database-1|

    When I get project deploymentconfig with labels:
      | <labels> |
    Then the step should succeed
    And the output should contain:
      | database     |
      | frontend     |
      | config       |
      | config,image |

    When I get project buildConfigs with labels:
      | <labels> |
    Then the step should succeed
    And the output should contain:
      | ruby-sample-build |
      | Source            |

    When I get project builds with labels:
      | <labels> |
    Then the step should succeed
    And the output should contain:
      | ruby-sample-build-1 |
      | Source              |

    When I get project imagestream with labels:
      | <labels> |
    Then the step should succeed
    And the output should contain:
      | origin-ruby-sample |

    When I get project route with labels:
      | <labels> |
    Then the step should succeed
    And the output should contain:
      | route-edge |

    When I delete all resources by labels:
      | <labels> |
    Then the project should be empty

    Examples:
      | labels                                                  |
      | redhat=rocks                                            |
      | label1=value1,label2=value2,label3=value3,label4=value4 |

  # @author xiuwang@redhat.com
  # @case_id 474042
  Scenario: Override/set/get values for multiple parameters
    Given I have a project
    When I run the :process client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json|
      |parameters|true|
    And the step succeeded
    And the output should match:
      |ADMIN_USERNAME\\s+administrator username\\s+expression\\s+<%= Regexp.escape("admin[A-Z0-9]{3}") %>|
      |ADMIN_PASSWORD\\s+administrator password\\s+expression\\s+<%= Regexp.escape("[a-zA-Z0-9]{8}") %> |
      |MYSQL_USER\\s+database username\\s+expression\\s+<%= Regexp.escape("user[A-Z0-9]{3}") %>|
      |MYSQL_PASSWORD\\s+database password\\s+expression\\s+<%= Regexp.escape("[a-zA-Z0-9]{8}") %>|
      |MYSQL_DATABASE\\s+database name\\s+\\s+root|

    When I run the :process client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json|
      |v|ADMIN_USERNAME=foo,ADMIN_PASSWORD=bar,MYSQL_USER=test,MYSQL_PASSWORD=cat,MYSQL_DATABASE=mine|
    And the step succeeded
    And the output should match:
      |"name": "ADMIN_USERNAME",\\s+"value": "foo" |
      |"name": "ADMIN_PASSWORD",\\s+"value": "bar" |
      |"name": "MYSQL_USER",\\s+"value": "test"    |
      |"name": "MYSQL_PASSWORD",\\s+"value": "cat" |
      |"name": "MYSQL_DATABASE",\\s+"value": "mine"|

    When I run the :process client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json|
      |v|ADMIN_USERNAME=foo,ADMIN_PASSWORD=bar,MYSQL_USER=test,MYSQL_PASSWORD=cat,MYSQL_DATABASE=mine|
      |parameters|true|
    And the step failed
    And the output should contain:
      |The --parameters flag does not process the template, can't be used with --value|

    Given oc major.minor version is stored in the clipboard
    When I run the :process client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json|
      |v|NONEXIST=abcd|
    Then the expression should be true> @result[:success] == (cb.oc_version.split(".").last.to_i < 3)
    #And the step failed
    And the output should contain:
      |unknown parameter name "NONEXIST"|

    And I process and create:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json|
      |v|ADMIN_USERNAME=foo,ADMIN_PASSWORD=bar,MYSQL_USER=test,MYSQL_PASSWORD=cat,MYSQL_DATABASE=mine|
    And the step succeeded
    Given the "ruby22-sample-build-1" build completed
    Given I wait for the "frontend" service to become ready
    When I run the :env client command with:
      | resource | pod/<%= pod.name %> |
      | list  | true |
    Then the step should succeed
    And the output should contain:
      |ADMIN_USERNAME=foo |
      |ADMIN_PASSWORD=bar |
      |MYSQL_USER=test    |
      |MYSQL_PASSWORD=cat |
      |MYSQL_DATABASE=mine|

  # @author cryan@redhat.com
  # @case_id 474056
  # @bug_id 1330323
  Scenario: Add arbitrary labels to all objects during template processing
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json"
    Given an 8 characters random string of type :dns is stored into the :lbl1 clipboard
    Given I replace lines in "ruby22rhel7-template-sti.json":
      | "template": "application-template-stibuild" | "<%= cb.lbl1 %>": "application-template-stibuild" |
    When I process and create "ruby22rhel7-template-sti.json"
    Then the step should succeed
    Given the "ruby22-sample-build-1" build completes
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
      | ruby22-sample-build |
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
      | ruby22-sample-build-1 |
    When I run the :get client command with:
      | resource | is |
      | l | <%= cb.lbl1 %>=application-template-stibuild |
    Then the output should contain:
      | origin-ruby22-sample |
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
  # @case_id 533273
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
  # @case_id 533274
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
      | The username/password are  |

  # @author cryan@redhat.com
  # @case_id 533275
  Scenario: Show user getting start info after new-app a template with message defined
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
    When I run the :new_app client command with:
      | template | ruby-helloworld-sample |
    Then the step should succeed
    And the output should contain:
      | Your admin credentials are |

  # @author cryan@redhat.com
  # @case_id 533276
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
  # @case_id 534517
  # @bug_id 1248362
  Scenario: new-app with template/imagestream from the exact namespace
    Given I have a project
    When I run the :tag client command with:
      | source      | openshift/hello-openshift |
      | dest        | mongodb:latest            |
      | source_type | docker                    |
    Then the step should succeed
    When I run the :export client command with:
      | resource    | is/mongodb         |
      | as_template | mongodb-persistent |
    Then the step should succeed
    Given I save the output to file> newtemplate.yaml
    When I run the :create client command with:
      | f | newtemplate.yaml |
    Then the step should succeed
    When I run the :new_app client command with:
      | app_repo | openshift/mongodb:latest |
      | dry_run  | true                     |
    Then the step should succeed
    And the output should contain ""mongodb" in project "openshift" under tag "latest""
    When I run the :new_app client command with:
      | app_repo | <%= project.name %>/mongodb:latest |
      | dry_run  | true                               |
    Then the step should succeed
    And the output should contain "mongodb under tag "latest" for "<%= project.name %>/mongodb:latest""
    When I run the :new_app client command with:
      | app_repo | openshift/mongodb-persistent |
      | dry_run  | true                         |
    Then the step should succeed
    And the output should contain ""mongodb-persistent" in project "openshift" for "openshift/mongodb-persistent""
    When I run the :new_app client command with:
      | app_repo | <%= project.name %>/mongodb-persistent |
      | dry_run  | true                                   |
    Then the step should succeed
    And the output should contain "mongodb-persistent for "<%= project.name %>/mongodb-persistent""
