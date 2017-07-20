Feature: functions about resource limits on pod
  # @author yanpzhan@redhat.com
  # @case_id OCP-11225
  Scenario: Pod template should contain cpu/memory limits when resources are set on pod

    Given I have a project
    When I run the :run client command with:
      | name         | mytest                    |
      | image        |<%= project_docker_repo %>aosqe/hello-openshift |
      | -l           | label=test |
      | limits       | cpu=300m,memory=300Mi|
      | requests     | cpu=150m,memory=250Mi|
    Then the step should succeed
    Given a pod becomes ready with labels:
      | label=test |

    When I perform the :check_limits_on_dc_page web console action with:
      | project_name   | <%= project.name%> |
      | dc_name        | mytest             |
      | container_name | mytest             |
      | cpu_range      | 150 millicores to 300 millicores |
      | memory_range   | 250 MiB to 300 MiB |
    Then the step should succeed

    When I perform the :check_limits_on_rc_page web console action with:
      | project_name   | <%= project.name%> |
      | dc_name        | mytest             |
      | dc_number      | 1 |
      | container_name | mytest             |
      | cpu_range      | 150 millicores to 300 millicores |
      | memory_range   | 250 MiB to 300 MiB |
    Then the step should succeed

    When I perform the :check_limits_on_pod_page web console action with:
      | project_name   | <%= project.name%>       |
      | pod_name       | <%= pod.name%>           |
      | container_name | mytest                   |
      | cpu_range      | 150 millicores to 300 millicores |
      | memory_range   | 250 MiB to 300 MiB       |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-10773
  @admin
  Scenario: Specify resource constraints for standalone rc and dc in web console with project limits already set
    Given I create a new project
    # create limits and DC
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/518638/limits.yaml |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/dc-with-two-containers.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    # wait #1 deployment complete
    And I wait until the status of deployment "dctest" becomes :complete
    # go to set resource limit page
    When I perform the :goto_set_resource_limits_for_dc web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | dctest              |
    Then the step should succeed
    # set container 'dctest-1' memory limit amount < memory min limit amount
    When I perform the :set_resource_limit web console action with:
      | container_name  | dctest-1   |
      | resource_type   | memory     |
      | sequence_id     | 1          |
      | limit_type      | Limit      |
      | amount_unit     | MiB        |
      | resource_amount | 4          |
    Then the step should succeed
    When I perform the :check_resource_limit_error_info web console action with:
      | error_info_for_resource_limit_setting | Can't be less than 5 MiB |
    Then the step should succeed
    # set container 'dctest-1' memory limit in valid range, others keep as default
    When I perform the :set_resource_limit web console action with:
      | container_name  | dctest-1   |
      | resource_type   | memory     |
      | sequence_id     | 1          |
      | limit_type      | Limit      |
      | amount_unit     | MiB        |
      | resource_amount | 118        |
    Then the step should succeed
    # save changes
    When I run the :click_save_button web console action
    Then the step should succeed
    # wait #2 deployment is complete
    Given I wait for the pod named "dctest-2-deploy" to die
    And a pod becomes ready with labels:
      | deployment=dctest-2     |
    # check pod resources
    When I perform the :check_limits_on_pod_page web console action with:
      | project_name   | <%= project.name %>              |
      | pod_name       | <%= pod.name %>                  |
      | container_name | dctest-1                         |
      | cpu_range      | 110 millicores to 130 millicores |
      | memory_range   | 118 MiB to 118 MiB               |
    Then the step should succeed
    When I perform the :check_limits_on_pod_page web console action with:
      | project_name   | <%= project.name %>              |
      | pod_name       | <%= pod.name %>                  |
      | container_name | dctest-2                         |
      | cpu_range      | 110 millicores to 130 millicores | 
      | memory_range   | 256 MiB to 256 MiB               |
    Then the step should succeed

    # create standalone rc with multi containers
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/rc-with-two-containers.yaml" replacing paths:
      | ["spec"]["replicas"] | 0 |
    Then the step should succeed
    # set resource limits for standalone rc
    When I perform the :goto_set_resource_limits_for_rc web console action with:
      | project_name | <%= project.name %> |
      | rc_name      | rctest              |
    Then the step should succeed
    When I perform the :check_warn_info_for_rc_resource_setting web console action with:
      | rc_resource_setting_warn_info |  Changes will only apply to new pods |
    Then the step should succeed
    # set Container hello-openshift-fedora memory request amount > memory max limit amount in different units
    When I perform the :set_resource_limit web console action with:
      | container_name  | hello-openshift-fedora |
      | resource_type   | memory     |
      | sequence_id     | 1          |
      | limit_type      | Request    |
      | amount_unit     | MB         |
      | resource_amount | 786.44     |
    Then the step should succeed
    When I perform the :check_resource_limit_error_info web console action with:
      | error_info_for_resource_limit_setting | Can't be greater than 750 MiB |
    Then the step should succeed
    When I perform the :check_resource_limit_error_info web console action with:
      | error_info_for_resource_limit_setting | Limit can't be less than request (786.44 MB) |
    Then the step should succeed
    When I perform the :check_resource_limit_error_info web console action with:
      | error_info_for_resource_limit_setting | Memory request total for all containers is greater than pod maximum (750 MiB) |
    Then the step should succeed
    # set Container hello-openshift-fedora memory limit in valid range, others keep as default
    When I perform the :set_resource_limit web console action with:
      | container_name  | hello-openshift-fedora |
      | resource_type   | memory     |
      | sequence_id     | 1          |
      | limit_type      | Request    |
      | amount_unit     | MiB        |
      | resource_amount | 97         |
    Then the step should succeed
    # save changes
    When I run the :click_save_button web console action
    Then the step should succeed
    # scale rc 'rctest' to generate new pods
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | rctest                 |
      | replicas | 1                      |
    Then the step should succeed
    # wait new pod generated for rctest
    Given a pod becomes ready with labels:
      | run=rctest  |
    # check new pod resource limit info
    When I perform the :check_limits_on_pod_page web console action with:
      | project_name   | <%= project.name %>              |
      | pod_name       | <%= pod.name %>                  |
      | container_name | hello-openshift                  |
      | cpu_range      | 110 millicores to 130 millicores |
      | memory_range   | 256 MiB to 256 MiB               |
    Then the step should succeed
    When I perform the :check_limits_on_pod_page web console action with:
      | project_name   | <%= project.name %>              |
      | pod_name       | <%= pod.name %>                  |
      | container_name | hello-openshift-fedora           |
      | cpu_range      | 110 millicores to 130 millicores |
      | memory_range   | 97 MiB to 256 MiB                |
    Then the step should succeed

  # @author xxing@redhat.com
  # @case_id OCP-11554
  Scenario: Specify resource constraints when creating new app in web console with project limits not set
    When I create a new project via web
    Then the step should succeed
    When I perform the :create_app_from_image web console action with:
      | project_name   | <%= project.name %>                        |
      | image_name     | python                                     |
      | image_tag      | latest                                     |
      | namespace      | openshift                                  |
      | app_name       | python-limit-demo                          |
      | source_url     | https://github.com/openshift/django-ex.git |
      | cpu_request    | e<%= rand_str(3, :dns) %>                  |
      | cpu_limit      | -<%= rand_str(3, :num) %>                  |
      | memory_request | -<%= rand_str(3, :num) %>                  |
      | memory_limit   | e<%= rand_str(3) %>                        |
    Then the step should fail
    When I get the visible text on web html page
    Then the output should contain 2 times:
      | Must be a number  |
      | Can't be negative |
    When I get the "disabled" attribute of the "button" web element:
      | text  | Create      |
      | class | btn-primary |
    Then the output should contain "true"
    When I perform the :create_app_from_image web console action with:
      | project_name   | <%= project.name %>                        |
      | image_name     | python                                     |
      | image_tag      | latest                                     |
      | namespace      | openshift                                  |
      | app_name       | python-limit-demo                          |
      | source_url     | https://github.com/openshift/django-ex.git |
      | cpu_request    | 130                                        |
      | cpu_limit      | 500                                        |
      | memory_request | 120                                        |
      | memory_limit   | 750                                        |
    Then the step should succeed
    Given the "python-limit-demo-1" build was created
    Given the "python-limit-demo-1" build completed
    Given I wait for the "python-limit-demo" service to become ready
    When I perform the :check_limits_on_pod_page web console action with:
      | project_name   | <%= project.name %>              |
      | pod_name       | <%= pod.name %>                  |
      | container_name | python-limit-demo                |
      | cpu_range      | 130 millicores to 500 millicores |
      | memory_range   | 120 MiB to 750 MiB               |
    Then the step should succeed

  # @author xxing@redhat.com
  # @case_id OCP-11229
  @admin
  Scenario: Specify resource constraints when creating new app in web console with project limits already set
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/518638/limits.yaml |
      | n | <%= project.name %>                                                                          |
    Then the step should succeed
    When I perform the :create_app_from_image_check_default_resource_limit web console action with:
      | project_name       | <%= project.name %>                         |
      | image_name         | php                                         |
      | image_tag          | latest                                      |
      | namespace          | openshift                                   |
      | app_name           | php-limit                                   |
      | source_url         | https://github.com/openshift/cakephp-ex.git |
      | cpu_limit_range    | 10 millicores min to 400 millicores max     |
      | default_cpu_req    | 110                                         |
      | default_cpu_lim    | 130                                         |
      | memory_limit_range | 5 MiB min to 750 MiB max                    |
      | default_memory_req | 100                                         |
      | default_memory_lim | 120                                         |
    Then the step should succeed
    # Set CPU Limit/Request ratio > defined CPU maxLimitRequestRatio
    When I perform the :create_app_from_image_set_cpu_resource_request web console action with:
      | cpu_request | 30 |
    Then the step should succeed
    When I perform the :create_app_from_image_set_cpu_resource_limit web console action with:
      | cpu_limit | 330 |
    Then the step should succeed
    When I run the :create_app_from_image_submit web console action
    Then the step should fail
    When I get the visible text on web html page
    Then the output should contain:
      | Limit cannot be more than 10 times request value  |
    When I get the "disabled" attribute of the "button" web element:
      | text  | Create      |
      | class | btn-primary |
    Then the output should contain "true"
    When I perform the :create_app_from_image web console action with:
      | project_name   | <%= project.name %>                         |
      | image_name     | php                                         |
      | image_tag      | latest                                      |
      | namespace      | openshift                                   |
      | app_name       | php-limit                                   |
      | source_url     | https://github.com/openshift/cakephp-ex.git |
      | cpu_request    | 110                                         |
      | cpu_limit      | 400                                         |
      | memory_request | 100                                         |
      | memory_limit   | 750                                         |
    Then the step should succeed
    Given the "php-limit-1" build was created
    Given the "php-limit-1" build completed
    Given I wait for the "php-limit" service to become ready
    When I perform the :check_limits_on_pod_page web console action with:
      | project_name   | <%= project.name %>              |
      | pod_name       | <%= pod.name %>                  |
      | container_name | php-limit                        |
      | cpu_range      | 110 millicores to 400 millicores |
      | memory_range   | 100 MiB to 750 MiB               |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-12178
  Scenario: Set Resource Limits for k8s deployment
    Given the master version >= "3.4"
    Given I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/tc536600/hello-deployment-1.yaml |
    Then the step should succeed
    When I perform the :check_latest_k8s_deployment_version web console action with:
      | project_name                  | <%= project.name %> |
      | k8s_deployment_name           | hello-openshift     |
      | latest_k8s_deployment_version | 1                   |
    Then the step should succeed
    # set resource limits for k8s deployment
    When I perform the :goto_set_resource_limits_for_k8s_deployment web console action with:
      | project_name        | <%= project.name %>   |
      | k8s_deployment_name | hello-openshift       |
    Then the step should succeed
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | cpu        |
      | limit_type      | Request    |
      | amount_unit     | millicores |
      | resource_amount | 100        |
    Then the step should succeed
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | cpu        |
      | limit_type      | Limit      |
      | amount_unit     | cores      |
      | resource_amount | 1          |
    Then the step should succeed
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | memory     |
      | limit_type      | Request    |
      | amount_unit     | MiB        |
      | resource_amount | 1000       |
    Then the step should succeed
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | memory     |
      | limit_type      | Limit      |
      | amount_unit     | MB         |
      | resource_amount | 1100       |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    # check resource limits on web console
    When I perform the :check_limits_on_k8s_deployment_page web console action with:
      | project_name        | <%= project.name %>      |
      | k8s_deployment_name | hello-openshift          |
      | container_name      | hello-openshift          |
      | cpu_range           | 100 millicores to 1 core |
      | memory_range        | 1000 MiB to 1100 MB      |
    Then the step should succeed
    # wait for new replica sets generated
    When I perform the :check_latest_k8s_deployment_version web console action with:
      | project_name                  | <%= project.name %> |
      | k8s_deployment_name           | hello-openshift     |
      | latest_k8s_deployment_version | 2                   |
    Then the step should succeed
    When I perform the :check_limits_on_specific_replica_set_page web console action with:
      | project_name        | <%= project.name %>      |
      | k8s_deployment_name | hello-openshift          |
      | container_name      | hello-openshift          |
      | spe_ver_of_rs       | 2                        |
      | cpu_range           | 100 millicores to 1 core |
      | memory_range        | 1000 MiB to 1100 MB      |
    Then the step should succeed
    When I perform the :check_limits_on_specific_replica_set_page web console action with:
      | project_name        | <%= project.name %>      |
      | k8s_deployment_name | hello-openshift          |
      | container_name      | hello-openshift          |
      | spe_ver_of_rs       | 1                        |
      | cpu_range           | 100 millicores to 1 core |
      | memory_range        | 1000 MiB to 1100 MB      |
    Then the step should fail
    When I perform the :goto_set_resource_limits_for_k8s_deployment web console action with:
      | project_name        | <%= project.name %>   |
      | k8s_deployment_name | hello-openshift       |
    Then the step should succeed
    # set Memory Limit < Memory Request
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | memory     |
      | limit_type      | Limit      |
      | amount_unit     | MB         |
      | resource_amount | 1000       |
    Then the step should succeed
    When I perform the :check_resource_limit_error_info web console action with:
      | error_info_for_resource_limit_setting | Limit can't be less than request (1000 MiB) |
    Then the step should succeed
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | memory     |
      | limit_type      | Request    |
      | amount_unit     | MiB        |
      | resource_amount | 900.8      |
    Then the step should succeed
    # set CPU Request to character
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | cpu        |
      | limit_type      | Request    |
      | amount_unit     | millicores |
      | resource_amount | eee        |
    Then the step should succeed
    When I perform the :check_resource_limit_error_info web console action with:
      | error_info_for_resource_limit_setting | Must be a number |
    Then the step should succeed
    # set CPU Request to negative number
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | cpu        |
      | limit_type      | Request    |
      | amount_unit     | millicores |
      | resource_amount | -9         |
    Then the step should succeed
    When I perform the :check_resource_limit_error_info web console action with:
      | error_info_for_resource_limit_setting | Can't be negative |
    Then the step should succeed
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | cpu        |
      | limit_type      | Request    |
      | amount_unit     | millicores |
      | resource_amount | 900        |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    # check resource limits after update
    When I perform the :check_limits_on_k8s_deployment_page web console action with:
      | project_name        | <%= project.name %>      |
      | k8s_deployment_name | hello-openshift          |
      | container_name      | hello-openshift          |
      | cpu_range           | 900 millicores to 1 core |
      | memory_range        | 944557260800 mB to 1 GB  |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-12228
  Scenario: Set Resource Limits for k8s replicaset
    Given the master version >= "3.4"
    Given I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/replicaSet/tc536589/replica-set.yaml |
    Then the step should succeed
    When I perform the :goto_set_resource_limits_for_k8s_replicaset web console action with:
      | project_name        | <%= project.name %>   |
      | k8s_replicaset_name | frontend              |
    Then the step should succeed
    # set CPU Limit < CPU Request
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | cpu        |
      | limit_type      | Limit      |
      | amount_unit     | millicores |
      | resource_amount | 50         |
    Then the step should succeed
    When I perform the :check_resource_limit_error_info web console action with:
      | error_info_for_resource_limit_setting | Limit can't be less than request (100 millicores) |
    Then the step should succeed
    # set CPU Limit with invalid charcter
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | cpu        |
      | limit_type      | Limit      |
      | amount_unit     | cores      |
      | resource_amount | Tx2        |
    Then the step should succeed
    When I perform the :check_resource_limit_error_info web console action with:
      | error_info_for_resource_limit_setting | Must be a number |
    Then the step should succeed
    # set CPU Limit with negative number
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | cpu        |
      | limit_type      | Limit      |
      | amount_unit     | cores      |
      | resource_amount | -7         |
    Then the step should succeed
    When I perform the :check_resource_limit_error_info web console action with:
      | error_info_for_resource_limit_setting | Can't be negative |
    Then the step should succeed
    # set correct resource limit
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | cpu        |
      | limit_type      | Limit      |
      | amount_unit     | cores      |
      | resource_amount | 0.2        |
    Then the step should succeed
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | memory     |
      | limit_type      | Limit      |
      | amount_unit     | MB         |
      | resource_amount | 110        |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_limits_on_k8s_replicaset_page web console action with:
      | project_name        | <%= project.name %>              |
      | k8s_replicaset_name | frontend                         |
      | container_name      | hello-openshift                  |
      | cpu_range           | 100 millicores to 200 millicores |
      | memory_range        | 100 MiB to 110 MB                |
    Then the step should succeed
