Feature: environment related

  # @author yapei@redhat.com
  # @case_id OCP-19858
  Scenario: Add Build envs from ConfigMaps and Secrets
    Given the master version >= "3.11"
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap-example.yaml   |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap.json           |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/secrets/OCP-11410/mysecret-1.yaml  |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/secrets/OCP-11410/mysecret-2.yaml  |
    Then the step should succeed
    When I run the :new_app client command with:
      | image_stream | openshift/python:latest                    |
      | code         | https://github.com/sclorg/django-ex.git |
      | name         | python-sample                              |
    Then the step should succeed
    And I open admin console in a browser

    # Add env from ConfigMap and Secret
    When I perform the :goto_one_buildconfig_page web action with:
      | project_name | <%= project.name %>  |
      | bc_name      | python-sample        |
    Then the step should succeed
    When I perform the :click_tab web action with:
      | tab_name | Environment |
    Then the step should succeed
    When I run the :check_env_editor_loaded web action
    Then the step should succeed
    When I run the :click_add_value_from_configmap_or_secret web action
    Then the step should succeed
    When I perform the :add_env_vars web action with:
      | env_var_name    | ENV_FROM_CM        |
      | env_source_name | example-config     |
      | env_source_key  | example.property.2 |
    Then the step should succeed
    When I run the :click_add_value_from_configmap_or_secret web action
    Then the step should succeed
    When I perform the :add_env_vars web action with:
      | env_var_name    | ENV_FROM_SEC       |
      | env_source_name | mysecret1          |
      | env_source_key  | password           |
    Then the step should succeed
    When I run the :submit_changes web action
    Then the step should succeed
    When I run the :get client command with:
      | resource      | bc            |
      | resource_name | python-sample |
      | o             | yaml          |
    Then the step should succeed
    Then the output by order should match:
      | ENV_FROM_CM             |
      | configMapKeyRef         |
      | key.*example.property.2 |
      | name.*example-config    |
      | ENV_FROM_SEC            |
      | secretKeyRef            |
      | key.*password           |
      | name.*mysecret1         |

    # update secret source name
    When I perform the :goto_one_buildconfig_page web action with:
      | project_name | <%= project.name %>  |
      | bc_name      | python-sample        |
    Then the step should succeed
    When I perform the :click_tab web action with:
      | tab_name | Environment |
    Then the step should succeed
    When I run the :check_env_editor_loaded web action
    Then the step should succeed
    When I perform the :update_env_vars web action with:
      | env_var_name    | ENV_FROM_SEC       |
      | env_source_name | mysecret2          |
      | env_source_key  | city               |
    Then the step should succeed
    When I run the :submit_changes web action
    Then the step should succeed
    When I run the :get client command with:
      | resource      | bc            |
      | resource_name | python-sample |
      | o             | yaml          |
    Then the step should succeed
    And the output should contain:
      | mysecret2 |
      | city      |
    And the output should not contain:
      | mysecret1 |
      | password  |

  # @author yapei@redhat.com
  # @case_id OCP-20183
  Scenario: Check environment variable editor for resource
    Given the master version >= "4.1"
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/dc-with-two-containers.yaml |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | run=dctest |
    
    # add env var key/value
    And I open admin console in a browser
    When I perform the :goto_resource_environment_page web action with:
      | project_name  | <%= project.name %>  |
      | resource_type | deploymentconfigs    |
      | resource_name | dctest               |
    Then the step should succeed
    When I perform the :choose_container web action with:
      | item | dctest-1 |
    Then the step should succeed
    When I perform the :add_env_vars web action with:
      | env_var_name  | c1     |
      | env_var_value | value1 |
    Then the step should succeed
    When I perform the :choose_container web action with:
      | item | dctest-2 |
    Then the step should succeed
    When I perform the :add_env_vars web action with:
      | env_var_name  | PATH_TO    |
      | env_var_value | /home/test |
    Then the step should succeed
    When I run the :submit_changes web action
    Then the step should succeed

    Given 1 pods become ready with labels:
      | run=dctest          |
      | deployment=dctest-2 |
    When I run the :set_env client command with:
      | resource | pod/<%= pod.name %> |
      | list     | true                |
    Then the step should succeed
    And the output by order should match:
      | container.*dctest-1 |
      | c1=value1           |
      | container.*dctest-2 |
      | PATH_TO=/home/test  |

    # delete env var key/value
    When I perform the :goto_resource_environment_page web action with:
      | project_name  | <%= project.name %>  |
      | resource_type | deploymentconfigs    |
      | resource_name | dctest               |
    Then the step should succeed
    When I perform the :choose_container web action with:
      | item | dctest-1 |
    Then the step should succeed
    When I perform the :remove_env_vars web action with:
      | env_var_name  | c1 |
    Then the step should succeed
    When I run the :submit_changes web action
    Then the step should succeed

    Given 1 pods become ready with labels:
      | run=dctest          |
      | deployment=dctest-3 |
    When I run the :set_env client command with:
      | resource | pod/<%= pod.name %> |
      | list     | true                |
    Then the step should succeed
    And the output should not match:
      | c1=value1 |

  # @author hasha@redhat.com
  # @case_id OCP-20954
  Scenario: Check environment editor for init container	 
    Given the master version >= "4.1"
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/initcontainer.yaml    |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap-example.yaml |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | app=hello-openshift |
    And I open admin console in a browser
    When I perform the :goto_resource_environment_page web action with:
      | project_name  | <%= project.name %>  |
      | resource_type | deployments          |
      | resource_name | initcontainer        |
    Then the step should succeed
    When I perform the :choose_container web action with:
      | item | wait |
    Then the step should succeed
    When I perform the :add_env_vars web action with:
      | env_var_name  | env1   |
      | env_var_value | value1 |
    Then the step should succeed
    When I run the :click_add_value_from_configmap_or_secret web action
    Then the step should succeed
    When I perform the :add_env_vars web action with:
      | env_var_name    | ENV_FROM_CM        |
      | env_source_name | example-config     |
      | env_source_key  | example.property.2 |
    Then the step should succeed
    When I run the :submit_changes web action
    Then the step should succeed
    Given 1 pods become ready with labels:
      |  app=hello-openshift |
    When I run the :get client command with:
      | resource      | pod             |
      | resource_name | <%= pod.name %> |
      | o             | yaml            |
    Then the step should succeed
    Then the output by order should match:
      | initContainers          |
      | name.*env1              |
      | value.*value1           |
      | name.*ENV_FROM_CM       |
      | valueFrom               |
      | configMapKeyRef         |
      | key.*example.property.2 |
      | name.*example-config    |
    When I perform the :goto_one_pod_page web action with:
      | project_name  | <%= project.name %>  |
      | resource_name | <%= pod.name %>      |
    Then the step should succeed
    And I wait up to 10 seconds for the steps to pass:
    """
    When I perform the :click_initcontainer_in_detail_page web action with:
      | container_name | wait |
    Then the step should succeed
    """

    When I run the :check_sections_on_container_details web action
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | Ports                                         |
      | Mounted Volumes                               |
      | Environment Variables                         |
      | env1                                          |
      | value1                                        |
      | ENV_FROM_CM                                   |
      | config-map: example-config/example.property.2 |

  # @author hasha@redhat.com
  # @case_id OCP-21085
    Scenario: Check environment variables editor on Deploy from Image flow page
    Given the master version >= "4.2"
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap-example.yaml   |
    Then the step should succeed
    And I open admin console in a browser
    When I perform the :goto_deploy_image_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :search_image web action with:
      | search_content | openshift/hello-openshift |
    Then the step should succeed
    When I run the :open_env_edit_for_dc web action
    Then the step should succeed
    When I perform the :add_env_vars web action with:
      | env_var_name  | del1     |
      | env_var_value | deltest1 |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text | Delete |
    Then the step should succeed
    When I perform the :add_env_vars web action with:
      | env_var_name  | env1   |
      | env_var_value | value1 |
    Then the step should succeed
    When I run the :click_add_value_from_configmap_or_secret web action
    Then the step should succeed
    When I perform the :add_env_vars web action with:
      | env_var_name    | ENV_FROM_CM        |
      | env_source_name | example-config     |
      | env_source_key  | example.property.2 |
    Then the step should succeed
    When I run the :click_create_button web action
    Then the step should succeed
    Given I wait until the status of deployment "hello-openshift" becomes :complete
    When I run the :set_env client command with:
      | resource | dc/hello-openshift |
      | list     | true               |
    And the step should succeed
    Then the output by order should match:
      | env1=value1 |
      | # ENV_FROM_CM from configmap example-config, key example.property.2 |

  # @author hasha@redhat.com
  # @case_id OCP-25203
    Scenario:  Check environment variables editor on DC creation page
    Given the master version == "4.1"
    Given I have a project
    And I open admin console in a browser
    When I perform the :goto_deploy_image_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :search_image web action with:
      | search_content | openshift/hello-openshift |
    Then the step should succeed
    When I perform the :add_env_vars web action with:
      | env_var_name  | del1     |
      | env_var_value | deltest1 |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text | Delete |
    Then the step should succeed
    When I perform the :add_env_vars web action with:
      | env_var_name  | env1   |
      | env_var_value | value1 |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text | Deploy |
    Then the step should succeed
    Given I wait until the status of deployment "hello-openshift" becomes :complete
    When I run the :set_env client command with:
      | resource | dc/hello-openshift |
      | list     | true               |
    And the step should succeed
    Then the output by order should match:
      | env1=value1 |
    And the output should not match:
      | del1=deltest1 |

