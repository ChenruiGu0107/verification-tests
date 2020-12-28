Feature: imagestream related

  # @author yanpzhan@redhat.com
  # @case_id OCP-24263
  Scenario: Check improve for image stream tag detail page
    Given the master version >= "4.2"
    Given I have a project
    Given I obtain test data file "image-streams/ui-netcore-is.json"
    When I run oc create over "ui-netcore-is.json" replacing paths:
      | ["spec"]["tags"][3]["from"]["name"] | testis |
    Then the step should succeed

    Given I open admin console in a browser
    And I wait up to 60 seconds for the steps to pass:
    """
    When I get project istag
    Then the output should contain "testdotnet:1.1"
    """
    When I perform the :goto_one_imagestream_page web action with:
      | project_name     | <%= project.name %> |
      | imagestream_name | testdotnet          |
    Then the step should succeed

    When I run the :click_history_tab web action
    Then the step should succeed

    When I perform the :check_resource_name_and_icon web action with:
      | imagestream_name | testdotnet |
    Then the step should succeed

    When I perform the :check_link_and_text web action with:
      | text     | testdotnet:1.1 |
      | link_url | /k8s/ns/<%= project.name %>/imagestreamtags/testdotnet |
    Then the step should succeed

    When I perform the :goto_one_imagestream_page web action with:
      | project_name     | <%= project.name %> |
      | imagestream_name | testdotnet          |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I perform the :check_page_contains web action with:
      | content | There are 1 warning alerts |
    Then the step should succeed
    """
    When I perform the :click_button web action with:
      | button_text | Show |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | Unable to sync image for tag testdotnet:1.0 |
    Then the step should succeed
    When I perform the :check_text_not_a_link web action with:
      | text | testdotnet:1.0 |
    Then the step should succeed
    When I perform the :check_istag_warning_info web action with:
      | istag_name | testdotnet:1.0 |
      | info       | There is no image associated with this tag |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-23880
  @admin
  @destructive
  Scenario: Show example docker commands for pushing and pulling image stream tags
    Given the master version >= "4.2"
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/python:latest                 |
      | code         | https://github.com/sclorg/django-ex.git |
      | name         | python-sample                           |
    Then the step should succeed
    Given I open admin console in a browser
    When I perform the :goto_one_imagestream_page web action with:
      | project_name     | <%= project.name %> |
      | imagestream_name | python-sample       |
    Then the step should succeed
    When I run the :wait_box_loaded web action
    Then the step should succeed
    When I run the :get admin command with:
      | resource | configs.imageregistry.operator.openshift.io/cluster |
      | o        | yaml |
    Then the step should succeed
    Given evaluation of `@result[:parsed]["spec"]["defaultRoute"]` is stored in the :defaultroute clipboard
    When I run the :patch admin command with:
      | resource | configs.imageregistry.operator.openshift.io/cluster |
      | type     | merge                                               |
      | p        | {"spec":{"defaultRoute": true}}                     |
    Then the step should succeed
    Given I register clean-up steps:
    """
    When I run the :patch admin command with:
      | resource | configs.imageregistry.operator.openshift.io/cluster |
      | type     | merge                                               |
      | p        | {"spec":{"defaultRoute": null}}                     |
    Then the step should succeed
    """

    Given I wait up to 120 seconds for the steps to pass:
    """
    When I perform the :goto_one_imagestream_page web action with:
      | project_name     | <%= project.name %> |
      | imagestream_name | python-sample       |
    Then the step should succeed
    When I run the :check_imagestream_help_link web action
    Then the step should succeed
    """
    When I run the :open_imagestream_help_modal web action
    Then the step should succeed
    When I run the :check_image_registry_command web action
    Then the step should succeed
