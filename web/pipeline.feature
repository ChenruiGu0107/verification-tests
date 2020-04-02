Feature: pipeline related
  # @author yanpzhan@redhat.com
  # @case_id OCP-11028
  Scenario: Show jenkins job url in build trigger info when the build is triggered by jenkins
    Given the master version >= "3.5"
    Given I have a project
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/pipeline/samplepipeline.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=jenkins |

    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed

    Given the "sample-pipeline-1" build was created
    When I perform the :goto_one_pipeline_build_page web console action with:
      | project_name  | <%= project.name %> |
      | pipeline_name | sample-pipeline     |
      | build_number  | 1                   |
    Then the step should succeed
    When I perform the :check_build_trigger_info web console action with:
      | trigger_info | Manual build |
    Then the step should succeed

    Given the "sample-pipeline-1" build becomes :running
    # A fix, 'finished' is robuster
    And the "nodejs-mongodb-example-1" build finished
    When I perform the :check_pipeline_stage_appear web console action with:
      | stage_name | build |
    Then the step should succeed
    When I perform the :check_build_trigger web console action with:
      | project_name      | <%= project.name %>                             |
      | bc_and_build_name | nodejs-mongodb-example/nodejs-mongodb-example-1 |
      | trigger_info      | Jenkins job                                     |
    Then the step should succeed

  # @case_id OCP-10844
  Scenario: Modify buildconfig for JenkinsPipeline strategy
    Given the master version >= "3.5"
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    Given the "sample-pipeline-1" build was created

    # Check Pipeline BC Configurations
    When I perform the :goto_pipeline_configuration_tab web console action with:
      | project_name     | <%= project.name %> |
      | pipeline_name    | sample-pipeline     |
    Then the step should succeed
    When I perform the :check_build_strategy web console action with:
      | build_strategy  | Jenkins Pipeline |
    Then the step should succeed
    When I perform the :check_runPolicy web console action with:
      | run_policy      | Serial |
    Then the step should succeed

    # Change JenkinsPipeline BC configurations
    When I perform the :goto_pipeline_bc_edit_page web console action with:
      | project_name     | <%= project.name %> |
      | pipeline_name    | sample-pipeline     |
    Then the step should succeed
    When I perform the :set_ace_editor_content web console action with:
      | content          | AAAAAAA             |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    
    # check jenkinsfile content for build sample-pipeline-1 started before changes
    When I perform the :goto_one_pipeline_build_page web console action with:
      | project_name     | <%= project.name %> |
      | pipeline_name    | sample-pipeline     |
      | build_number     | 1                   |
    Then the step should succeed
    When I perform the :check_ace_editor_content_has web console action with:
      | content          | openshiftBuild  |
    Then the step should succeed

    # start a new build and check if changes take effect
    When I run the :start_build client command with:
      | buildconfig  | sample-pipeline |
    Then the step should succeed
    Given the "sample-pipeline-2" build was created
    When I perform the :goto_one_pipeline_build_page web console action with:
      | project_name     | <%= project.name %> |
      | pipeline_name    | sample-pipeline     |
      | build_number     | 2                   |
    Then the step should succeed
    When I perform the :check_ace_editor_content_has web console action with:
      | content | AAAAAAA         |
    Then the step should succeed
    When I perform the :check_ace_editor_content_has web console action with:
      | content | openshiftBuild  |
    Then the step should fail

