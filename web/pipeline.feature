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
