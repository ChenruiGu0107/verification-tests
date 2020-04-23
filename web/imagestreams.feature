Feature: check image streams page
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

