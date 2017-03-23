Feature: oc build related scenarios
  # @author xiaocwan@redhat.com
  # @case_id OCP-10189
  Scenario: oc start-build with output flag
    Given I have a project
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc470422/application-template-stibuild.json |
    Then the step should succeed
    Given the "ruby-22-centos7" image stream becomes ready
    And the "origin-ruby-sample" image stream becomes ready
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build   |
      | o           | name                |
    Then the step should succeed
    And the output should contain:
      | ruby-sample-build-2               |
    And the output should not match:
      | build .* started                  |
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build   |
      | from_build  | ruby-sample-build-1 |
      | o           | name                |   
    And the output should contain:
      | ruby-sample-build-3               |
    And the output should not match:
      | build .* started                  |
    ## negative flag
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build   |
      | o           | invalidname         |
    Then the step should fail 
    And the output should match:
      | error.*[Uu]nsupported.*invalidname |   

  # @author xiuwang@redhat.com
  # @case_id OCP-10963
  Scenario: Explicit pull of base image for docker builds	
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | git://github.com/openshift/ruby-hello-world.git | 
      | strategy | docker                                          |
    Then the step should succeed
    And the "ruby-hello-world-1" build completed
    When I run the :logs client command with:
      | resource_name | build/ruby-hello-world-1 |
      | f             ||
    Then the step should succeed
    And the output should not contain:
      | Downloading |
    When I run the :delete client command with:
      | all_no_dash ||
      | all         ||
    Then the step should succeed

    When I run the :new_build client command with:
      | app_repo    | https://github.com/openshift/ruby-hello-world.git | 
      | strategy    | docker                                            |
      | image_stream| ruby:2.2                                          |
      | name        | forcepullapp                                      |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | bc                                                          |
      | resource_name | forcepullapp                                                |
      | p             | {"spec":{"strategy":{"dockerStrategy":{"forcePull":true}}}} | 
    Then the step should succeed
    And I git clone the repo "https://github.com/openshift/ruby-hello-world.git"
    And I run the :start_build client command with:
      | buildconfig | forcepullapp     |
      | from_dir    | ruby-hello-world |
    Then the step should succeed
    And the "forcepullapp-2" build completed
    When I run the :logs client command with:
      | resource_name | build/forcepullapp-2 |
      | f             |                      |
    Then the step should succeed
    And the output should contain:
      | Pulling image  |
      | Already exists |
    When I run the :delete client command with:
      | all_no_dash ||
      | all         ||
    Then the step should succeed

    When I run the :new_build client command with:
      | D    | FROM centos:7\nFROM centos:6 | 
      | name | multifrom                    |
    Then the step should succeed
    And the "multifrom-1" build completed
    When I run the :logs client command with:
      | resource_name | build/multifrom-1 |
      | f             |                   |
    Then the step should succeed
    And the output should not contain:
      | Downloading |
