Feature: check image streams page
  # @author yapei@redhat.com
  # @case_id OCP-10738
  @smoke
  Scenario: check image stream page
    Given I have a project
    When I perform the :check_empty_image_streams_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    # create image streams via CLI
    Given I use the "<%= project.name %>" project
    Then I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-rhel7.json |
    When I run the :get client command with:
      | resource | is |
    Then the output should match:
      | jenkins |
      | mongodb |
      | mysql   |
      | nodejs  |
      | perl    |
      | php     |
      | postgresql |
      | python  |
      | ruby    |
    # check all image stream displayed well on web
    When I perform the :check_image_streams web console action with:
      | is_name | jenkins |
    Then the step should succeed
    When I perform the :check_image_streams web console action with:
      | is_name | mongodb |
    Then the step should succeed
    When I perform the :check_image_streams web console action with:
      | is_name | mysql |
    Then the step should succeed
    When I perform the :check_image_streams web console action with:
      | is_name | nodejs |
    Then the step should succeed
    When I perform the :check_image_streams web console action with:
      | is_name | perl |
    Then the step should succeed
    When I perform the :check_image_streams web console action with:
      | is_name | php |
    Then the step should succeed
    When I perform the :check_image_streams web console action with:
      | is_name | postgresql |
    Then the step should succeed
    When I perform the :check_image_streams web console action with:
      | is_name | python |
    Then the step should succeed
    When I perform the :check_image_streams web console action with:
      | is_name | ruby |
    Then the step should succeed
    # check one specific image
    When I perform the :check_one_image_stream web console action with:
      | project_name | <%= project.name %> |
      | image_name   |  nodejs |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not match:
      | openshift.io/image.dockerRepositoryCheck |
    # delete one image stream via CLI
    When I run the :delete client command with:
      | object_type | is |
      | object_name_or_id | php |
    Then the output should match:
      | imagestream "php" deleted |
    # check deleted image stream on web
    When I perform the :check_deleted_image_stream web console action with:
      | project_name | <%= project.name %> |
      | image_name   | php  |
    Then the step should succeed

  # @author etrott@redhat.com
  # @case_id OCP-10347
  Scenario: Check ImageStreamTag picker on BC edit page
    Given I have a project
    And I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/ui/application-template-stibuild-without-customize-route.json |
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
