Feature: filter on create page
  # @author: yapei@redhat.com
  # @case_id: 470357
  Scenario: search and filter for things on the create page
    When I create a new project via web
    Then the step should succeed
    
    # filter by tag instant-app
    When I perform the :filter_by_tags web console action with:
      | tag_name | instant-app |
    Then the step should succeed
    When I get the html of the web page
    Then the output should match:
      | Instant Apps |
    # filter by tag xPaas
    When I perform the :filter_by_tags web console action with:
      | tag_name | xpaas |
    Then the step should succeed
    When I get the html of the web page
    Then the output should match:
      | xPaaS |
      | jboss |
      | amq62 |
    # filter by tag java
    When I perform the :filter_by_tags web console action with:
      | tag_name | java |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not contain:
      | Python |
      | Instant Apps |
      | NodeJS |
      | PHP |
      | Other |
      | Ruby |
      | Perl |
      | Databases |
    # filter by tag ruby
    When I perform the :filter_by_tags web console action with:
      | tag_name | ruby |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not contain:
      | Python |
      | NodeJS |
      | Other |
      | xPaaS |
      | Perl |
      | Databases |
      | PHP |
    # filter by tag perl
    When I perform the :filter_by_tags web console action with:
      | tag_name | perl |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not contain:
      | Python |
      | NodeJS |
      | Other |
      | Ruby |
      | Databases |
      | xPaaS |
      | PHP |
    # filter by tag python
    When I perform the :filter_by_tags web console action with:
      | tag_name | python |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not contain:
      | NodeJS |
      | Perl |
      | Other |
      | Ruby |
      | Databases |
      | xPaaS |
      | PHP |
    # filter by tag nodejs
    When I perform the :filter_by_tags web console action with:
      | tag_name | nodejs |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not contain:
      | Perl |
      | Other |
      | Python |
      | Ruby |
      | Databases |
      | xPaaS |
      | PHP |
    # filter by tag database
    When I perform the :filter_by_tags web console action with:
      | tag_name | database |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | Databases |
      | mongodb |
      | mysql |
      | xPaaS |
      | eap64 |
    # filter by tag messaging
    When I perform the :filter_by_tags web console action with:
      | tag_name | messaging |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | xPaaS |
      | amq |
    # filter by tag php
    When I perform the :filter_by_tags web console action with:
      | tag_name | php |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not contain:
      | Python |
      | NodeJS |
      | Other |
      | xPaaS |
      | Ruby |
      | Perl |
      | Databases |
    When I run the :clear_tag_filters web console action
    Then the step should succeed
    # filter by partial keyword
    When I perform the :filter_by_keywords web console action with:
      | keyword | ph |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | php |
      | ephemeral |
    When I run the :clear_keyword_filters web console action
    Then the step should succeed
    When I perform the :filter_by_keywords web console action with:
      | keyword | php |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | Instant Apps |
      | PHP |
    When I run the :clear_keyword_filters web console action
    Then the step should succeed
    # filter by multi-keywords
    When I perform the :filter_by_keywords web console action with:
      | keyword | instant-app perl |
    Then the step should succeed
    When I get the html of the web page
    Then the output should match:
      | dancer-example |
      | dancer-.+-example |
    When I run the :clear_keyword_filters web console action
    Then the step should succeed
    # filter by non-exist keyword
    When I perform the :filter_by_keywords web console action with:
      | keyword | hello |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | All builder images and templates are hidden by the current filter |
    When I run the :clear_keyword_filters web console action
    Then the step should succeed
    # filter by invalid character keyword
    When I perform the :filter_by_keywords web console action with:
      | keyword | $#@ |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | All builder images and templates are hidden by the current filter |
    # Clear filter link
    When I click the following "a" element:
      | text | Clear filter |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not contain:
      | All builder images and templates are hidden by the current filter |
    # filter by keyword and tag 
    When I perform the :filter_by_keywords web console action with:
      | keyword | nodejs |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | Instant Apps |
      | NodeJS |
    When I perform the :filter_by_tags web console action with:
      | tag_name | instant-app |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not contain:
      | NodeJS |


  # @author yanpzhan@redhat.com
  # @case_id 470358
  Scenario: Filter resources by labels under Browse page
    When I create a new project via web 
    Then the step should succeed
    When I perform the :create_app_from_template web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | nodejs-example |
      | namespace     | openshift      |
      | param_one     | :null  |
      | param_two     | :null  |
      | param_three   | :null  |
      | param_four    | :null  |
      | param_five    | :null  |
      | label_key     | label1 |
      | label_value   | test1  |
    Then the step should succeed
    Given the "nodejs-example-1" build was created
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
      | nodejs-example |
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
      | nodejs-example |
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
      | nodejs-example |
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
      | nodejs-example-1-build |

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
      | nodejs-example |
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
      | nodejs-example |
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
    When I get the html of the web page
    Then the output should contain:
      | nodejs-example |
    And the output should not contain:
      | The active filters are hiding all |
    
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
      | nodejs-example |
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
      | nodejs-example |

    When I run the :clear_all_filters web console action
    Then the step should succeed

    When I perform the :filter_resources_with_exists_option web console action with:
      | label_key     | label1 |
      | filter_action | exists |
    Then the step should succeed

    When I get the html of the web page
    Then the output should contain:
      | nodejs-example |
    And the output should not contain:
      | nodejs-sample |

