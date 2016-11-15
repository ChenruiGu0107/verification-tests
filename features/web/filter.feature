Feature: filter on create page

  # @author: yapei@redhat.com
  # @case_id: 507525
  Scenario: search and filter for things on the create page
    When I create a new project via web
    Then the step should succeed

    # filter by tag instant-app
    When I perform the :filter_by_tags web console action with:
      | tag_name | instant-app |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | instant-app |
    Then the step should succeed
    # filter by tag quickstart
    When I perform the :filter_by_tags web console action with:
      | tag_name | quickstart |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | quickstart |
    Then the step should succeed
    # filter by tag xPaas
    When I perform the :filter_by_tags web console action with:
      | tag_name | xpaas |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | xpaas |
    Then the step should succeed
    # filter by tag java
    When I perform the :filter_by_tags web console action with:
      | tag_name | java |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | java |
    Then the step should succeed
    # filter by tag ruby
    When I perform the :filter_by_tags web console action with:
      | tag_name | ruby |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | ruby |
    Then the step should succeed
    # filter by tag perl
    When I perform the :filter_by_tags web console action with:
      | tag_name | perl |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | perl |
    Then the step should succeed
    # filter by tag python
    When I perform the :filter_by_tags web console action with:
      | tag_name | python |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | python |
    Then the step should succeed
    # filter by tag nodejs
    When I perform the :filter_by_tags web console action with:
      | tag_name | nodejs |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | nodejs |
    Then the step should succeed
    # filter by tag database
    When I perform the :filter_by_tags web console action with:
      | tag_name | database |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | database |
    Then the step should succeed
    # filter by tag messaging
    When I perform the :filter_by_tags web console action with:
      | tag_name | messaging |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | messaging |
    Then the step should succeed
    # filter by tag php
    When I perform the :filter_by_tags web console action with:
      | tag_name | php |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | php |
    Then the step should succeed
    When I run the :clear_tag_filters web console action
    Then the step should succeed
    # filter by partial keyword
    When I perform the :filter_by_keywords web console action with:
      | keyword | ph |
    Then the step should succeed
    When I perform the :check_all_resources_tags_contain web console action with:
      | tag_name | ph |
    Then the step should succeed
    When I run the :clear_keyword_filters web console action
    Then the step should succeed

    # filter by multi-keywords
    When I perform the :filter_by_keywords web console action with:
      | keyword | quickstart perl |
    Then the step should succeed
    When I perform the :check_all_resources_tags_contain web console action with:
      | tag_name | quickstart |
    Then the step should succeed
    When I perform the :check_all_resources_tags_contain web console action with:
      | tag_name | perl |
    Then the step should succeed
    When I run the :clear_keyword_filters web console action
    Then the step should succeed
    # filter by non-exist keyword
    When I perform the :filter_by_keywords web console action with:
      | keyword | hello |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I get the html of the web page
    Then the output should contain:
      | All builder images and templates are hidden by the current filter |
    """
    When I run the :clear_keyword_filters web console action
    Then the step should succeed
    # filter by invalid character keyword
    When I perform the :filter_by_keywords web console action with:
      | keyword | $#@ |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I get the html of the web page
    Then the output should contain:
      | All builder images and templates are hidden by the current filter |
    """
    # Clear filter link
    When I click the following "a" element:
      | text | Clear filter |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I get the html of the web page
    Then the output should not contain:
      | All builder images and templates are hidden by the current filter |
    """
    # filter by keyword and tag
    When I perform the :filter_by_keywords web console action with:
      | keyword | quickstart |
    Then the step should succeed
    When I perform the :check_all_resources_tags_contain web console action with:
      | tag_name | quickstart |
    Then the step should succeed
    When I perform the :filter_by_tags web console action with:
      | tag_name | nodejs |
    Then the step should succeed
    When I perform the :check_all_resources_tags_include web console action with:
      | tag_name | nodejs |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id 470358
  Scenario: Filter resources by labels under Browse page
    When I create a new project via web
    Then the step should succeed

    When I perform the :create_app_from_image_with_label_options web console action with:
      | project_name | <%= project.name %>                        |
      | image_name   | python                                     |
      | image_tag    | 3.4                                        |
      | namespace    | openshift                                  |
      | app_name     | python-sample                              |
      | source_url   | https://github.com/openshift/django-ex.git |
      | label_key    | label1                                     |
      | label_value  | test1                                      |
    Then the step should succeed
    Given the "python-sample-1" build was created
    When I perform the :create_app_from_image_with_label_options web console action with:
      | project_name | <%= project.name %>                        |
      | image_name   | nodejs                                     |
      | image_tag    | 0.10                                       |
      | namespace    | openshift                                  |
      | app_name     | nodejs-sample                              |
      | source_url   | https://github.com/openshift/nodejs-ex.git |
      | label_key    | label2                                     |
      | label_value  | test2                                      |
    Then the step should succeed
    Given the "nodejs-sample-1" build was created

    #Filter on Browse->Builds page
    When I perform the :goto_builds_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed
    When I perform the :filter_resources web console action with:
      | label_key     | label1 |
      | label_value   | test1  |
      | filter_action | in ... |
    Then the step should succeed

    When I get the html of the web page
    Then the output should contain:
      | python-sample |
    And the output should not contain:
      | nodejs-sample |

    #Filter on Browse->Deployments page
    When I perform the :goto_deployments_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed

    When I perform the :filter_resources web console action with:
      | label_key     | label1 |
      | label_value   | test1  |
      | filter_action | in ... |
    Then the step should succeed

    When I get the html of the web page
    Then the output should contain:
      | python-sample |
    And the output should not contain:
      | nodejs-sample |

    #Filter on Browse->Image Streams page
    When I perform the :goto_image_streams_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed

    When I perform the :filter_resources web console action with:
      | label_key     | label1 |
      | label_value   | test1  |
      | filter_action | in ... |
    Then the step should succeed

    When I get the html of the web page
    Then the output should contain:
      | python-sample |
    And the output should not contain:
      | nodejs-sample |

    #Filter on Browse->Pods page
    When I perform the :goto_pods_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed

    When I perform the :filter_resources web console action with:
      | label_key     | openshift.io/build.name |
      | label_value   | nodejs-sample-1 |
      | filter_action | in ... |
    Then the step should succeed

    When I get the html of the web page
    Then the output should contain:
      | nodejs-sample-1-build |
    And the output should not contain:
      | python-sample-1-build |

    #Filter on Browse->Routes page
    When I perform the :goto_routes_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed

    When I perform the :filter_resources web console action with:
      | label_key     | label1 |
      | label_value   | test1  |
      | filter_action | in ... |
    Then the step should succeed

    When I get the html of the web page
    Then the output should contain:
      | python-sample |
    And the output should not contain:
      | nodejs-sample |

    #Filter on Browse->Services page
    When I perform the :goto_services_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed

    When I perform the :filter_resources web console action with:
      | label_key     | label1 |
      | label_value   | test1  |
      | filter_action | in ... |
    Then the step should succeed

    When I get the html of the web page
    Then the output should contain:
      | python-sample |
    And the output should not contain:
      | nodejs-sample |

    #Filter with non-existing label
    When I perform the :filter_resources_with_non_existing_label web console action with:
      | label_key     | nolabel |
      | press_enter   | :enter  |
      | label_value   | novalue |
      | filter_action | in ...  |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | The active filters are hiding all |

    #Clear one filter
    When I perform the :clear_one_filter web console action with:
      | filter_name | nolabel in (novalue) |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the html of the web page
    Then the output should contain:
      | python-sample |
    And the output should not contain:
      | The active filters are hiding all |
    """

    When I perform the :filter_resources_with_non_existing_label web console action with:
      | label_key     | i*s#$$% |
      | press_enter   | :enter  |
      | label_value   | 1223$@@ |
      | filter_action | in ...  |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | The active filters are hiding all |

    #Clear all filters
    When I run the :clear_all_filters web console action
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | python-sample  |
      | nodejs-sample  |

     #Filter with other operator actions
    When I perform the :filter_resources web console action with:
      | label_key     | label1 |
      | label_value   | test1  |
      | filter_action | not in ... |
    Then the step should succeed

    When I get the html of the web page
    Then the output should contain:
      | nodejs-sample |
    And the output should not contain:
      | python-sample |

    When I run the :clear_all_filters web console action
    Then the step should succeed

    When I perform the :filter_resources_with_exists_option web console action with:
      | label_key     | label1 |
      | filter_action | exists |
    Then the step should succeed

    When I get the html of the web page
    Then the output should contain:
      | python-sample |
    And the output should not contain:
      | nodejs-sample |

  # @author: yanpzhan@redhat.com
  # @case_id: 470360
  Scenario: Display existing labels in label suggestion list according to different resources
    Given I have a project
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>                        |
      | image_name   | python                                     |
      | image_tag    | latest                                     |
      | namespace    | openshift                                  |
      | app_name     | python-sample                              |
      | source_url   | https://github.com/openshift/django-ex.git |
    Then the step should succeed
    Given the "python-sample-1" build was created

    # Check suggested labels on overview page.
    When I perform the :check_suggested_label_on_overview_page web console action with:
      | project_name | <%= project.name%> |
      | label        | app |
    Then the step should succeed

    # Check suggested labels on builds page.
    When I perform the :goto_builds_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed
    When I run the :click_filter_box web console action
    Then the step should succeed
    When I perform the :check_suggested_label web console action with:
      | label | app |
    Then the step should succeed

    # Check suggested labels on bc page.
    When I perform the :goto_one_buildconfig_page web console action with:
      | project_name | <%= project.name%> |
      | bc_name | python-sample |
    Then the step should succeed
    When I run the :click_filter_box web console action
    Then the step should succeed
    When I perform the :check_suggested_label web console action with:
      | label | app |
    Then the step should succeed
    When I perform the :check_suggested_label web console action with:
      | label | buildconfig |
    Then the step should succeed
    When I perform the :check_suggested_label web console action with:
      | label | openshift.io/build-config.name |
    Then the step should succeed

    # Check suggested labels on deployments page.
    When I perform the :goto_deployments_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed
    When I run the :click_filter_box web console action
    Then the step should succeed
    When I perform the :check_suggested_label web console action with:
      | label | app |
    Then the step should succeed

    # Check suggested labels on imagestreams page.
    When I perform the :goto_image_streams_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed
    When I run the :click_filter_box web console action
    Then the step should succeed
    When I perform the :check_suggested_label web console action with:
      | label | app |
    Then the step should succeed

    # Check suggested labels on pods page.
    When I perform the :goto_pods_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed
    When I run the :click_filter_box web console action
    Then the step should succeed
    When I perform the :check_suggested_label web console action with:
      | label | openshift.io/build.name |
    Then the step should succeed

    # Check suggested labels on routes page.
    When I perform the :goto_routes_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed
    When I run the :click_filter_box web console action
    Then the step should succeed
    When I perform the :check_suggested_label web console action with:
      | label | app |
    Then the step should succeed

    # Check suggested labels on services page.
    When I perform the :goto_services_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed
    When I run the :click_filter_box web console action
    Then the step should succeed
    When I perform the :check_suggested_label web console action with:
      | label | app |
    Then the step should succeed
