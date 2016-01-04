Feature: Return description with cli

  # @author wewang@redhat.com
  # @case_id 470422
  Scenario: Return description with cli describe with invalid parameter
    Given I have a project
    When I run the :new_app client command with:
     | file  | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    Given the "ruby-sample-build-1" build was created 
    Given the "ruby-sample-build-1" build completed
    And a pod becomes ready with labels:
      |name=frontend|
    And a pod becomes ready with labels:
      |name=database|
    #And all pods in the project are ready

    #Use blank parameter
    When I run the :describe client command with:
      | resource | services | 
      | name     | :false | 
    Then the step should succeed
    Then the output should contain:
      | name=database |
      | name=frontend |
 
     When I run the :describe client command with:
      | resource | pods |
      | name     | :false |
    Then the step should succeed
    Then the output should contain:
      | name=database |
      | name=frontend |

     When  I run the :describe client command with:
      | resource | dc |
      | name     | :false |
     Then the output should match:
      | database|
      | frontend |

      When  I run the :describe client command with:
      | resource | bc |
      | name     | :false |
     Then the output should contain:
      | URL:			https://github.com/openshift/ruby-hello-world.git|
      |From Image:		ImageStreamTag ruby-22-centos7:latest|
      |Output to:		ImageStreamTag origin-ruby-sample:latest|

      When  I run the :describe client command with:
      | resource | rc |
      | name     | :false |
     Then the output should contain:
      | database-1| 
      | frontend-1|

      When  I run the :describe client command with:
      | resource | build |
      | name     | :false |
     Then the output should contain:
      |ruby-sample-build-1|
      |Complete |
     #Use unexisted parameter:
      When  I run the :describe client command with:
      | resource | services |
      | name | abc |
     Then the output should contain:
      | services "abc" not found |
     
      When  I run the :describe client command with:
      | resource | pods |
      | name | abc |
     Then the output should contain:
      | pods "abc" not found |
 
      When  I run the :describe client command with:
      | resource | buildConfig |
      | name | abc |
     Then the output should contain:
      | buildconfig "abc" not found |

      When  I run the :describe client command with:
      | resource | replicationControllers |
      | name | abc |
     Then the output should contain:
      | replicationControllers "abc" not found |

      When  I run the :describe client command with:
      | resource | builds |
      | name | abc |
      Then the output should contain:
      | build "abc" not found |

      When  I run the :describe client command with:
      |resource| :false|
      |name| :false|
      Then the output should contain:
      | error: Required resource not specified |
      
      #Use incorrect argument
      When  I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg |des |
      Then the output should contain:
      | unknown command "des" for "oc" |

