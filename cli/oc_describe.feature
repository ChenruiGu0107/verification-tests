Feature: Return description with cli

  # @author wewang@redhat.com
  # @case_id OCP-12021
  Scenario: Return description with cli describe with invalid parameter
    Given I have a project
    Given I obtain test data file "build/application-template-stibuild.json"
    When I run the :new_app client command with:
      | file  | application-template-stibuild.json |
    Then the step should succeed
    Given the "ruby-sample-build-1" build was created
    Given the "ruby-sample-build-1" build completed
    And a pod becomes ready with labels:
      |name=frontend|
    And a pod becomes ready with labels:
      |name=database|

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
      | URL:			https://github.com/openshift/ruby-hello-world.git |
      | From Image:		ImageStreamTag openshift/ruby:latest          |  
      | Output to:		ImageStreamTag origin-ruby-sample:latest      |

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
     #Then the output should contain:
    Then the output should match "buildconfigs.* "abc" not found"
     # | buildconfigs "abc" not found |

    When  I run the :describe client command with:
      | resource | replicationControllers |
      | name | abc |
    Then the output should contain:
      | replicationcontrollers "abc" not found |

    When  I run the :describe client command with:
      | resource | builds |
      | name | abc |
      #Then the output should contain:
    Then the output should match "builds.* "abc" not found"
      #| builds "abc" not found |

    When  I run the :describe client command with:
      |resource| :false|
      |name| :false|
    Then the output should match "error: Required resource not specified|You must specify the type of resource to describe"
      #Use incorrect argument
    When  I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg |des |
    Then the output should contain:
      | unknown command "des" for "oc" |

  # @author xiaocwan@redhat.com
  # @case_id OCP-10491
  Scenario: oc describe event should not duplicate same output for no description
    Given I log the message>  this scenario is only for oc 3.4+
    Given I have a project
    Given I obtain test data file "templates/ui/application-template-stibuild-without-customize-route.json"
    When I run the :new_app client command with:
      | file | application-template-stibuild-without-customize-route.json |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | event    |
    And the output should not match:
      | no description.* [Ee]vent.*\n\s+no description.* [Ee]vent |
