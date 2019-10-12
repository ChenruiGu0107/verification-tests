Feature: imagestream related

  # @author yanpzhan@redhat.com
  # @case_id OCP-24263
  Scenario: Check improve for image stream tag detail page
    Given the master version >= "4.2"
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image-streams/ui-netcore-is.json" replacing paths:
      | ["spec"]["tags"][3]["from"]["name"] | testis |
    Then the step should succeed

    Given I open admin console in a browser
    When I perform the :goto_one_imagestream_page web action with:
      | project_name     | <%= project.name %> |
      | imagestream_name | testdotnet          |
    Then the step should succeed

    When I perform the :click_tab web action with:
      | tab_name | History |
    Then the step should succeed

    When I perform the :check_resource_name_and_icon web action with:
      | imagestream_name | testdotnet |
    Then the step should succeed

    When I perform the :check_link_and_text web action with:
      | text     | testdotnet:1.1 |
      | link_url | /k8s/ns/<%= project.name %>/imagestreamtags/testdotnet:1.1 |
    Then the step should succeed

    When I perform the :goto_one_imagestream_page web action with:
      | project_name     | <%= project.name %> |
      | imagestream_name | testdotnet          |
    Then the step should succeed

    When I perform the :check_page_contains web action with:
      | content | There are 1 warning alerts |
    Then the step should succeed

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
