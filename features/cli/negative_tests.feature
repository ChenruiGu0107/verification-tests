Feature: negative tests

  # @author pruan@redhat.com
  # @case_id OCP-10688
  Scenario: Add automatic suggestions when "unknown command" errors happen in the CLI
    When I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg | labels |
    Then the step should fail
    And the output should contain:
      | unknown command "labels" for "oc" |
      | Did you mean this                 |
      | label                             |
    When I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg | creaet |
    Then the step should fail
    And the output should contain:
      | unknown command "creaet" for "oc" |
      | Did you mean this                 |
      | create                            |
    When I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg | teg |
    Then the step should fail
    And the output should contain:
      | unknown command "teg" for "oc" |
      | Did you mean this              |
      | tag                            |
  
  # @author xiaocwan@redhat.com
  # @case_id OCP-10190
  Scenario: Check output for resource idle command and negative commands
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/rc/idle-rc-1.yaml |
    Then the step should succeed
    When I run the :idle client command with:
      | svc_name | svc/hello-idle |
      | dry-run  | true           |
    Then the step should fail
    And the output should match:
      | no valid.*resources.*specify endpoints |
    When I run the :idle client command with:
      | svc_name | rc/hello-idle  |
      | dry-run  | true           |
    Then the step should fail
    And the output should match:     
      | no valid.*resources.*specify endpoints |
    ## idle again
    Given I wait until number of replicas match "2" for replicationController "hello-idle"
    And 2 pods become ready with labels:
      | name=hello-idle |
    When I run the :idle client command with:
      | all | true      |
    Then the step should succeed
    When I run the :idle client command with:
      | all | true      |
    Then the step should fail
    # drop the check for error message since the output is different from other version, refer to Bug#1402356

  # @author xiaocwan@redhat.com
  # @case_id OCP-11365
  Scenario: Improved CLI command guide
    Given I log the message>  this scenario is only for oc 3.4+
    When I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg             | abcd           |
    Then the step should fail
    And the output should match:
      | unknown command |
      | oc --help       |

    # oc status negative
    When I run the :status client command
    Then the step should fail
    And the output should match:
      | cannot get projects in project.*default |   
    Given I have a project
    When I run the :status client command
    Then the step should succeed
    And the output should match:
      | [Yy]ou have no  |
      | oc new-app      |  
    # follow output instruction to test `oc new-app`
    
    # oc new-app negative/positive oc status positive
    When I run the :new_app client command
    Then the step should fail
    And the output should match:
      | [Ee]rror.*[Yy]ou must specify    |
      | oc new-app -L                    |
      | oc new-app -S                    |
      | oc new-app -h                    |
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    When I run the :status client command
    Then the step should succeed
    And the output should match:
      | use.*oc status -v                |
    When I run the :status client command with:
      | v     |                          |
    Then the step should succeed
    And the output should contain:
      | oc describe <resource>/<name>    |
      | oc get all                       |
    # follow output instruction to test `oc describe` and `oc get`
    
    # oc describe negative
    When I run the :describe client command with:
      | resource | :false |
    Then the step should fail
    And the output should match:
      | type of resource.*include        |
      | buildconfigs.*bc                 |
      | [Ee]rror.*[Rr]equired resource   |
      | oc describe -h                   |
    # oc get negative
    When I run the :get client command with:
      | resource | :false |
    Then the step should fail
    And the output should match:
      | type of resource.*include        |
      | buildconfigs.*bc                 |
      | [Ee]rror.*[Rr]equired resource   |
      | oc get -h                        |
      | oc explain <resource>            |
    # follow output instruction to test `oc explain`

    # oc explain negative
    When I run the :explain client command
    Then the step should fail
    And the output should match:
      | type of resource.*include        |
      | buildconfigs.*bc                 |
      | [Ee]rror.*[Rr]equired resource   |
      | oc explain -h                    |

    # oc start-build negative
    When I run the :start_build client command
    Then the step should fail
    And the output should match:  
      | [Ee]rror.*build config           |
      | specify build name.*--from-build |
      | oc get bc                        |
      | oc start-build -h                |

    # oc deploy negative
    When I run the :deploy client command with:
      | deployment_config | :false |
    Then the step should fail
    And the output should match:   
      | [Ee]rror.*deployment config.*required |
      | oc get dc                        |
      | oc deploy -h                     |

    # oc expose negative
    When I run the :expose client command with:
      | resource         | :false        |
      | resource_name    | :false        |
    Then the step should fail
    And the output should match: 
      | [Ee]rror.*must provide.*resource |
      | [Ee]xample resource.*include     |
      | oc expose -h                     |

    # oc logs should not only prompt message about pod
    # there is bug: #https://bugzilla.redhat.com/show_bug.cgi?id=1391838
    When I run the :logs client command with:
      | resource_name | :false |
    Then the step should fail
    And the output should contain:
      | bc              |
      | dc              |
    