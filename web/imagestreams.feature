Feature: check image streams page

  # @author etrott@redhat.com
  # @case_id OCP-10347
  Scenario: Check ImageStreamTag picker on BC edit page
    Given I have a project
    And I run the :new_app client command with:
      | app_repo | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json |
    Then the step should succeed
    Given the "ruby-sample-build-1" build was created
    When I perform the :check_buildconfig_edit_page_loaded_completely web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | ruby-sample-build   |
    Then the step should succeed
    When I perform the :check_image_configuration_on_bc_edit_page web console action with:
      | image_namespace | <%= project.name %> |
      | image_op        | Push To             |
      | image_type      | Image Stream Tag    |
      | image_stream    | origin-ruby-sample  |
      | tag             | latest              |
    Then the step should succeed
    When I perform the :edit_image_configuration_on_bc_edit_page web console action with:
      | image_op  | Push To |
      | image_tag | newtag1 |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_bc_succesfully_updated_message web console action with:
      | bc_name | ruby-sample-build |
    Then the step should succeed
    When I perform the :check_bc_output web console action with:
      | project_name | <%= project.name %>                            |
      | bc_name      | ruby-sample-build                              |
      | bc_output    | <%= project.name %>/origin-ruby-sample:newtag1 |
    Then the step should succeed
    And the "ruby-sample-build-1" build completed
    When I perform the :check_buildconfig_edit_page_loaded_completely web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | ruby-sample-build   |
    Then the step should succeed
    When I perform the :check_saved_tag_type_on_bc_edit_page web console action with:
      | image_op | Push To     |
      | tag_type | Current Tag |
      | tag      | latest      |
    Then the step should succeed
    When I perform the :check_saved_tag_type_on_bc_edit_page web console action with:
      | image_op | Push To |
      | tag_type | New Tag |
      | tag      | newtag1 |
    Then the step should succeed
    When I perform the :start_build_base_on_buildconfig web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | ruby-sample-build   |
    Then the step should succeed
    And the "ruby-sample-build-2" build completed
    When I perform the :check_buildconfig_edit_page_loaded_completely web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | ruby-sample-build   |
    Then the step should succeed
    When I perform the :check_saved_tag_type_on_bc_edit_page web console action with:
      | image_op | Push To     |
      | tag_type | Current Tag |
      | tag      | newtag1     |
    Then the step should succeed
    When I perform the :check_saved_tag_type_missing_on_bc_edit_page web console action with:
      | image_op | Push To |
      | tag_type | New Tag |
      | tag      | newtag1 |
    Then the step should succeed

    When I perform the :goto_one_image_stream_page web console action with:
      | project_name | <%= project.name %> |
      | image_name   | origin-ruby-sample  |
    Then the step should succeed
    When I perform the :check_is_tag_basic_page web console action with:
      | image_name | origin-ruby-sample |
      | istag      | newtag1            |
    Then the step should succeed

  # @author xxia@redhat.com
  # @case_id OCP-14740
  Scenario: Check imagestream page of atomic registry style
    Given I log the message> Case is not critical importance so no scripts for 3.6
    Given the master version >= "3.7"
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/image-streams/simple-is.json             |
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-centos7.json |
    Then the step should succeed
    And I wait for the "hello-openshift" is to appear
    And I wait for the "ruby:latest" istag to appear

    # empty imagestream
    When I perform the :goto_one_image_stream_page web console action with:
      | project_name | <%= project.name %> |
      | image_name   | hello-openshift     |
    Then the step should succeed
    When I perform the :check_image_stream_summaries web console action with:
      | pulling_repo   | /<%= project.name %>/hello-openshift     |
      | image_count    | 0                                        |
    Then the step should succeed
    When I run the :check_image_stream_tags_table_empty web console action
    Then the step should succeed

    When I perform the :goto_one_image_stream_page web console action with:
      | project_name | <%= project.name %> |
      | image_name   | ruby                |
    Then the step should succeed
    When I run the :check_image_stream_tags_table_head web console action
    Then the step should succeed
    When I perform the :check_image_stream_tags_table web console action with:
      | project_name | <%= project.name %>                            |
      | image_name   | ruby                                           |
      | image_tag    | latest                                         |
      | image_from   | <%= istag("ruby:latest").from(user: user) %>   |
    Then the step should succeed
    When I perform the :check_image_stream_tags_table web console action with:
      | project_name | <%= project.name %>                |
      | image_name   | ruby                               |
      | image_tag    | 2.4                                |
      | image_from   | centos/ruby-24-centos7:latest      |
    Then the step should succeed
    When I perform the :check_image_stream_instructions web console action with:
      | project_name | <%= project.name %> |
      | image_name   | ruby                |
    Then the step should succeed

