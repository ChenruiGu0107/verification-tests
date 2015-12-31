Feature: resouces related scenarios
  # @author pruan@redhat.com
  # @case_id 474088
  Scenario: Display resources in different formats
    Given I have a project
    When I create a new application with:
      | docker image | openshift/mysql-55-centos7                             |
      | code         | https://github.com/openshift/ruby-hello-world          |
    Then the step should succeed
    Given the pod named "mysql-55-centos7-1-deploy" becomes ready
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should contain:
      | mysql-55-centos7-1-deploy |
    When I run the :get client command with:
      | resource | pods |
      | o        | json |
    And the output is parsed as JSON
    Then the expression should be true> @result[:parsed]['items'].any? {|p| p['metadata']['name'].include? 'mysql-55-centos7-1-deploy'}
    When I run the :get client command with:
      | resource | pods |
      | o        | yaml |
    And the output is parsed as YAML
    Then the expression should be true> @result[:parsed]['items'].any? {|p| p['metadata']['name'].include? 'mysql-55-centos7-1-deploy'}
    When I run the :get client command with:
      | resource | pods |
      | o        | invalid-format |
    Then the output should contain:
      | error: output format "invalid-format" not recognized |

  # @author cryan@redhat.com
  # @case_id 474089
  Scenario: Display resources with multiple options
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/openshift/origin/e21d95cedad8f0ce06ff5d04ae9b978ce3d04d87/examples/sample-app/application-template-stibuild.json"
    And I run the :process client command with:
      |f|application-template-stibuild.json|
    And the step should succeed
    And I save the output to file> processed-stibuild.json
    When I run the :create client command with:
      |f|processed-stibuild.json|
    Then the step should succeed
    Given the pod named "ruby-sample-build-1-build" becomes ready
    #the w (watch) flag is set to false. Please set to true once timeouts are
    #implemented in steps.
    When I run the :get client command with:
      | resource   | pods  |
      | no_headers | false |
      | w          | false |
      | l          |       |
    Then the step should succeed
    Then the output should match "ruby-sample-build-1-build\s+1/1\s+Running\s+0"

  # @author xxia@redhat.com
  # @case_id 512023
  Scenario: oc replace with miscellaneous options
    Given I have a project
    And I run the :run client command with:
      | name         | mydc                      |
      | image        | openshift/hello-openshift |
      | -l           | label=mydc                |
    Then the step should succeed

    Given I wait until the status of deployment "mydc" becomes :running
    And I run the :get client command with:
      | resource      | dc                 |
      | resource_name | mydc               |
      | output        | yaml               |
    Then the step should succeed
    When I save the output to file>dc.yaml
    And I run the :replace client command with:
      | f     | dc.yaml |
      | force |         |
    Then the step should succeed
    And the output should contain:
      | "mydc" deleted  |
      | "mydc" replaced |

    Given a pod becomes ready with labels:
      | label=mydc |
    And evaluation of `pod.name` is stored in the :pod_name clipboard
    When I run the :replace client command with:
      | f       | dc.yaml |
      | force   |         |
      | cascade |         |
    Then the step should succeed
    When I wait for the resource "pod" named "<%= cb.pod_name %>" to disappear
    And I run the :get client command with:
      | resource | pod     |
      | l        | dc=mydc |
    Then the step should succeed
    And the output should not contain "<%= cb.pod_name %>"

    When I run the :run client command with:
      | name         | mypod                     |
      | image        | openshift/hello-openshift |
      | generator    | run-pod/v1                |
    Then the step should succeed
    Given the pod named "mypod" becomes ready
    And I run the :get client command with:
      | resource      | pod                |
      | resource_name | mypod              |
      | output        | yaml               |
    Then the step should succeed
    When I save the output to file>pod.yaml
    And I run the :replace client command with:
      | f            | pod.yaml |
      | force        |          |
      | grace-period | 100      |
    # Currently, there is a bug https://bugzilla.redhat.com/show_bug.cgi?id=1285702 that makes the step *fail*
    Then the step should succeed

  # @author xxia@redhat.com
  # @case_id 510404
  Scenario: Delete resources with cascade selectors
    Given I have a project
    And I run the :run client command with:
      | name      | test              |
      | image     | <%= project_docker_repo %>openshift/hello-openshift |
      | generator | run-controller/v1 |
      | -l        | run=test          |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | run=test |
    When I run the :delete client command with:
      | object_type       | rc    |
      | object_name_or_id | test  |
      | cascade           | true  |
    Then the step should succeed
    And I wait for the resource "pod" named "<%= pod.name %>" to disappear

    When I run the :run client command with:
      | name      | test              |
      | image     | <%= project_docker_repo %>openshift/hello-openshift |
      | generator | run-controller/v1 |
      | -l        | run=test          |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | rc    |
      | object_name_or_id | test  |
      | cascade           | false |
    Then the step should succeed
    And a pod becomes ready with labels:
      | run=test |

    When I run the :run client command with:
      | name      | test-a            |
      | image     | <%= project_docker_repo %>openshift/hello-openshift |
      | generator | run-controller/v1 |
      | -l        | label=same        |
    Then the step should succeed
    When I run the :run client command with:
      | name      | test-b            |
      | image     | <%= project_docker_repo %>openshift/hello-openshift |
      | generator | run-controller/v1 |
      | -l        | label=same,label2=test-b |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | rc      |
      | object_name_or_id | test-a  |
      | object_name_or_id | test-b  |
    Then the step should fail
    And the output should contain "overlapping controllers"
    When I run the :delete client command with:
      | object_type       | rc      |
      | object_name_or_id | test-a  |
      | object_name_or_id | test-b  |
      | cascade           | false   |
    Then the step should succeed

  # @author xxia@redhat.com
  # @case_id 470421
  Scenario: Return description of resources with cli describe
    Given I have a project
    And I create a new application with:
      | file     | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    And I wait until the status of deployment "database" becomes :running
    When I run the :describe client command with:
      | resource     | svc           |
      | name         | database      |
    Then the step should succeed
    And the output should match:
      | Name:\\s+database            |
      | Selector:\\s+name=database   |
    When I run the :export client command with:
      | resource     | svc           |
      | name         | database      |
      | o            | yaml          |
    Then the step should succeed
    Given I save the output to file>svc.yaml
    When I run the :describe client command with:
      | resource     | :false        |
      | name         | :false        |
      | f            | svc.yaml      |
    Then the step should succeed
    And the output should match:
      | Name:\\s+database            |
    When I run the :describe client command with:
      | resource     | svc           |
      | name         | :false        |
      | l            | app           |
    Then the step should succeed
    And the output should match:
      | Name:\\s+database            |
    When I run the :describe client command with:
      | resource     | svc           |
      | name         | databa        |
    Then the step should succeed
    And the output should match:
      | Name:\\s+database            |
    # The following steps shorten the multiple steps of the TCMS case
    When I run the :describe client command with:
      | resource     | :false        |
      | name         | rc/database-1                     |
      | name         | is/origin-ruby-sample             |
      | name         | dc/frontend                       |
    Then the step should succeed
    And the output should match:
      | Name:\\s+database-1                  |
      | Pods Status:                         |
      | Name:\\s+origin-ruby-sample          |
      | Tags:                                |
      | Name:\\s+frontend                    |
      | Template:                            |

  # @author xiaocwan@redhat.com
  # @case_id 500003
  @admin
  Scenario: Cluster admin can get resources in all namespaces

    Given I switch to the first user
    Given a 5 characters random string of type :dns is stored into the :proj1 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.proj1 %> |
    Then the step should succeed
    When I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby20rhel7-template-sti.json"
    Then the step should succeed

    Given I switch to the second user
    Given a 5 characters random string of type :dns is stored into the :proj2 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.proj2 %> |
    Then the step should succeed
    When I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby20rhel7-template-sti.json"
    Then the step should succeed


    When I run the :get admin command with:
      | resource         | build |
      | all_namespace    | true |
    Then the output should contain:
      | <%= cb.proj1 %> |
      | <%= cb.proj2 %> |

    When I run the :get admin command with:
      | resource         | pod |
      | all_namespace    | true |
    Then the output should contain:
      | <%= cb.proj1 %> |
      | <%= cb.proj2 %> |

    When I run the :get admin command with:
      | resource         | service |
      | all_namespace    | true |
    Then the output should contain:
      | <%= cb.proj1 %> |
      | <%= cb.proj2 %> |

    When I run the :get admin command with:
      | resource         | bc |
      | all_namespace    | true |
    Then the output should contain:
      | <%= cb.proj1 %> |
      | <%= cb.proj2 %> |

    When I run the :get admin command with:
      | resource         | rc |
      | all_namespace    | true |
    Then the output should contain:
      | <%= cb.proj1 %> |
      | <%= cb.proj2 %> |

    When I run the :get admin command with:
      | resource         | template |
      | all_namespace    | true |
    Then the output should contain:
      | openshift       |

    When I run the :get admin command with:
      | resource         | is |
      | all_namespace    | true |
    Then the output should contain:
      | <%= cb.proj1 %> |
      | <%= cb.proj2 %> |

    When I run the :get admin command with:
      | resource         | route |
      | all_namespace    | true |
    Then the output should contain:
      | <%= cb.proj1 %> |
      | <%= cb.proj2 %> |

    When I run the :get admin command with:
      | resource         | dc |
      | all_namespace    | true |
    Then the output should contain:
      | <%= cb.proj1 %> |
      | <%= cb.proj2 %> |

    When I run the :get admin command with:
      | resource         | all |
      | all_namespace    | true |
    Then the output should contain 15 times:
      | default |
