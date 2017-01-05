Feature: functions about resourcequotas

  # @author yanpzhan@redhat.com
  # @case_id 521078 521120 521122
  @admin
  Scenario Outline: Check scopes of resourcequota on web console
    Given I have a project
    When I run the :create admin command with:
      | f | <quota_file> |
      | n | <%= project.name %> |
    Then the step should succeed

    When I perform the :check_quota_scope_type web console action with:
      | project_name | <%= project.name%> |
      | scope_type   | <scope_type> |
    Then the step should succeed

    #Check used quota when no pod exists
    When I perform the :check_used_value web console action with:
      | resource_type | CPU (Limit) |
      | used_value    | 0 cores     |
    Then the step should succeed
    When I perform the :check_used_value web console action with:
      | resource_type | Memory (Limit) |
      | used_value    | 0              |
    Then the step should succeed
    When I perform the :check_used_value web console action with:
      | resource_type | Pods |
      | used_value    | 0    |
    Then the step should succeed
    When I perform the :check_used_value web console action with:
      | resource_type | CPU (Request) |
      | used_value    | 0 cores       |
    Then the step should succeed
    When I perform the :check_used_value web console action with:
      | resource_type | Memory (Request) |
      | used_value    | 0                |
    Then the step should succeed

    When I run oc create with "<pod1_file>" replacing paths:
      | ["metadata"]["name"] | pod1 |
    Then the step should succeed

    #Check used quota when "pod1" exists
    When I perform the :goto_settings_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed
    When I perform the :check_used_value web console action with:
      | resource_type | CPU (Limit)    |
      | used_value    | 500 millicores |
    Then the step should succeed
    When I perform the :check_used_value web console action with:
      | resource_type | Memory (Limit) |
      | used_value    | 256 MiB        |
    Then the step should succeed
    When I perform the :check_used_value web console action with:
      | resource_type | Pods |
      | used_value    | 1    |
    Then the step should succeed
    When I perform the :check_used_value web console action with:
      | resource_type | CPU (Request) |
      | used_value    | 200 millicores|
    Then the step should succeed
    When I perform the :check_used_value web console action with:
      | resource_type | Memory (Request) |
      | used_value    | 256 MiB          |
    Then the step should succeed

    When I run the :delete client command with:
      | object_type       | pod |
      | object_name_or_id | pod1 |
    Then the step should succeed
    When I wait for the resource "pod" named "pod1" to disappear
    When I run the :create client command with:
      | f | <pod2_file> |
    Then the step should succeed

    #Check used quota when only "pod2" exists
    When I perform the :goto_settings_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed
    When I perform the :check_used_value web console action with:
      | resource_type | CPU (Limit) |
      | used_value    | 0 cores     |
    Then the step should succeed
    When I perform the :check_used_value web console action with:
      | resource_type | Memory (Limit) |
      | used_value    | 0              |
    Then the step should succeed
    When I perform the :check_used_value web console action with:
      | resource_type | Pods |
      | used_value    | 0    |
    Then the step should succeed
    When I perform the :check_used_value web console action with:
      | resource_type | CPU (Request) |
      | used_value    | 0 cores       |
    Then the step should succeed
    When I perform the :check_used_value web console action with:
      | resource_type | Memory (Request) |
      | used_value    | 0                |
    Then the step should succeed
    Examples:
      | scope_type | quota_file | pod1_file | pod2_file |
      | Not Best Effort | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/quota-notbesteffort.yaml | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-notbesteffort.yaml | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-besteffort.yaml |
      | Terminating | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/quota-terminating.yaml | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-terminating.yaml | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-notterminating.yaml |
      | Not Terminating | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/quota-notterminating.yaml | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-notterminating.yaml | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-terminating.yaml |

  # @author yanpzhan@redhat.com
  # @case_id 521080
  @admin
  Scenario: Check BestEffort scope of resourcequota on web console
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/quota-besteffort.yaml |
      | n | <%= project.name %> |
    Then the step should succeed

    When I perform the :check_quota_scope_type web console action with:
      | project_name | <%= project.name%> |
      | scope_type   | Best Effort |
    Then the step should succeed

    #Check used quota when no "besteffort" pod exists
    When I perform the :check_used_value web console action with:
      | resource_type | Pods |
      | used_value    | 0    |
    Then the step should succeed

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-besteffort.yaml |
    Then the step should succeed

    #Check used quota when "besteffort" pod exists
    When I perform the :goto_settings_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed
    When I perform the :check_used_value web console action with:
      | resource_type | Pods |
      | used_value    | 1    |
    Then the step should succeed

    When I run the :delete client command with:
      | object_type       | pod |
      | object_name_or_id | pod-besteffort |
    Then the step should succeed
    When I wait for the resource "pod" named "pod-besteffort" to disappear
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-notbesteffort.yaml |
    Then the step should succeed

    #Check used quota when only "notbesteffort" pod exists
    When I perform the :goto_settings_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed
    When I perform the :check_used_value web console action with:
      | resource_type | Pods |
      | used_value    | 0    |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id 536550
  @admin
  Scenario: Show warning info on overview page if quota is met
    Given I have a project
    When I run the :create_quota admin command with:
      | name | myquota                    |
      | hard | cpu=1,memory=1Gi,pods=5   |
      | n    | <%= project.name %>        |
    Then the step should succeed

    When I run the :run client command with:
      | name      | myrc                  |
      | image     | aosqe/hello-openshift |
      | limits    | cpu=20m,memory=50Mi   |
      | generator | run/v1                |
    Then the step should succeed

    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | myrc                   |
      | replicas | 5                      |
    Then the step should succeed

    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed

    When I run the :check_quota_warning_on_overview_page web console action
    Then the step should succeed

    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | myrc                   |
      | replicas | 8                      |
    Then the step should succeed

    When I perform the :check_quota_warning_for_scaling_on_overview_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id 536552
  @admin
  Scenario: Show warning/error info if quota exceeded when create resource by deploying image on web console
    Given I have a project
    When I run the :create_quota admin command with:
      | name | myquota                                 |
      | hard | cpu=50m,memory=80Mi,pods=5,services=3   |
      | n    | <%= project.name %>                     |
    Then the step should succeed

    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/limits.yaml |
      | n | <%= project.name %> |
    Then the step should succeed

    When I perform the :deploy_from_image_stream_tag_with_normal_is_and_change_name web console action with:
      | project_name          | <%= project.name %> |
      | namespace             | openshift           |
      | image_stream_name     | python              |
      | image_stream_tag      | 3.4                 |
      | new_deploy_image_name | python-dfi          |
      | image_name            | python-dfi          |
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota |
    Then the step should fail

    When I perform the :deploy_from_image_stream_name_with_env_label web console action with:
      | project_name          | <%= project.name %>   |
      | image_deploy_from     | aosqe/hello-openshift |
      | env_var_key           | myenv                 |
      | env_var_value         | my-env-value          |
      | label_key             | mylabel               |
      | label_value           | my-hello-openshift    |
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota |
    Then the step should fail 

    When I run the :run client command with:
      | name      | mypod                  |
      | image     | aosqe/hello-openshift  |
      | limits    | cpu=50m,memory=80Mi    |
      | generator | run-pod/v1             |
    Then the step should succeed

    When I perform the :deploy_from_image_stream_name_with_env_label web console action with:
      | project_name          | <%= project.name %>          |
      | image_deploy_from     | aosqe/hello-openshift-fedora |
      | env_var_key           | myenv                        |
      | env_var_value         | my-env-value                 |
      | label_key             | mylabel                      |
      | label_value           | my-hello-openshift           |
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota for CPU (request) on pods |
    Then the step should succeed
    And I run the :click_cancel web console action
    Then the step should succeed

    When I perform the :deploy_from_image_stream_tag_with_normal_is_and_change_name web console action with:
      | project_name          | <%= project.name %> |
      | namespace             | openshift           |
      | image_stream_name     | python              |
      | image_stream_tag      | 3.4                 |
      | new_deploy_image_name | pythontest          |
      | image_name            | pythontest          |
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota for CPU (request) on pods |
    Then the step should succeed
    And I run the :click_create_anyway web console action
    Then the step should succeed

    When I perform the :deploy_from_image_stream_name_with_env_label web console action with:
      | project_name          | <%= project.name %>   |
      | image_deploy_from     | aosqe/hello-openshift |
      | env_var_key           | myenv                 |
      | env_var_value         | my-env-value          |
      | label_key             | mylabel               |
      | label_value           | my-hello-openshift    |
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota of 3 services in this project |
    Then the step should succeed
    And I run the :click_cancel web console action
    Then the step should succeed

    And I wait for the steps to pass:
    """
    When I perform the :deploy_from_image_stream_tag_with_normal_is_and_change_name web console action with:
      | project_name          | <%= project.name %> |
      | namespace             | openshift           |
      | image_stream_name     | python              |
      | image_stream_tag      | 3.4                 |
      | new_deploy_image_name | pythontwo           |
      | image_name            | pythontwo           |
    Then the step should succeed
    """
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota of 3 services in this project |
    Then the step should succeed
    And I run the :click_cancel web console action
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id 536553
  @admin
  Scenario: Show warning/error info if quota exceeded when create resource from image/template on web console
    Given I have a project
    When I run the :create_quota admin command with:
      | name | myquota                                 |
      | hard | cpu=50m,memory=80Mi,pods=5,services=4   |
      | n    | <%= project.name %>                     |
    Then the step should succeed

    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/limits.yaml |
      | n | <%= project.name %> |
    Then the step should succeed

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed

    When I perform the :create_app_from_template_without_label web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
      | param_one     | :null  |
      | param_two     | :null  |
      | param_three   | :null  |
      | param_four    | :null  |
      | param_five    | :null  |
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota |
    Then the step should fail
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>   |
      | image_name   | nodejs                |
      | image_tag    | 0.10                  |
      | namespace    | openshift             |
      | app_name     | nodejs-sample1        |
      | source_url   | https://github.com/openshift/nodejs-ex |
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota |
    Then the step should fail

    When I run the :run client command with:
      | name      | mypod                  |
      | image     | aosqe/hello-openshift  |
      | limits    | cpu=50m,memory=80Mi    |
      | generator | run-pod/v1             |
    Then the step should succeed

    When I perform the :create_app_from_template_without_label web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
      | param_one     | :null  |
      | param_two     | :null  |
      | param_three   | :null  |
      | param_four    | :null  |
      | param_five    | :null  |
    Then the step should fail
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota for CPU (request) on pods |
    Then the step should succeed
    And I run the :click_cancel web console action
    Then the step should succeed

    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>   |
      | image_name   | nodejs                |
      | image_tag    | 0.10                  |
      | namespace    | openshift             |
      | app_name     | nodejs-sample2        |
      | source_url   | https://github.com/openshift/nodejs-ex |
    Then the step should fail
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota for CPU (request) on pods |
    Then the step should succeed
    And I run the :click_create_anyway web console action
    Then the step should succeed

    When I perform the :create_app_from_template_without_label web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
      | param_one     | :null  |
      | param_two     | :null  |
      | param_three   | :null  |
      | param_four    | :null  |
      | param_five    | :null  |
    Then the step should fail
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota of 4 services in this project |
    Then the step should succeed
    And I run the :click_cancel web console action
    Then the step should succeed

    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>   |
      | image_name   | nodejs                |
      | image_tag    | 0.10                  |
      | namespace    | openshift             |
      | app_name     | nodejs-sample3        |
      | source_url   | https://github.com/openshift/nodejs-ex |
    Then the step should fail
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota of 4 services in this project |
    Then the step should succeed
    And I run the :click_cancel web console action
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id 536551
  @admin
  Scenario: Show warning/error info if quota exceeded when create resource by importing yaml/json file on web console
    Given I have a project
    When I run the :create_quota admin command with:
      | name | myquota                                 |
      | hard | cpu=50m,memory=80Mi,pods=5,services=1   |
      | n    | <%= project.name %>                     |
    Then the step should succeed

    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/limits.yaml |
      | n | <%= project.name %> |
    Then the step should succeed

    When I run the :run client command with:
      | name      | mypod                  |
      | image     | aosqe/hello-openshift  |
      | limits    | cpu=50m,memory=80Mi    |
      | generator | run-pod/v1             |
    Then the step should succeed

    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json"
    Then the step should succeed

    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project.name %>                                     |
      | file_path        | <%= File.join(localhost.workdir, "deployment1.json") %> |
    Then the step should succeed

    And I wait for the steps to pass:
    """
    And I run the :click_create_button web console action
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota for CPU (request) on pods |
    Then the step should succeed
    """
    And I run the :click_cancel web console action
    Then the step should succeed

    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project.name %>                                     |
      | file_path        | <%= File.join(localhost.workdir, "deployment1.json") %> |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    And I run the :click_create_button web console action
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota for memory (request) on pods |
    Then the step should succeed
    """
    And I run the :click_create_anyway web console action
    Then the step should succeed

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed

    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/services/multi-portsvc.json"
    Then the step should succeed

    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project.name %>                                       |
      | file_path        | <%= File.join(localhost.workdir, "multi-portsvc.json") %> |
    Then the step should succeed

    And I wait for the steps to pass:
    """
    And I run the :click_create_button web console action
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota of 1 service in this project |
    Then the step should succeed
    """
    And I run the :click_cancel web console action
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id 536554
  @admin
  @destructive
  Scenario: Show warning/error info if quota exceeded when create resource on web console with both project quota and cluster quota set on project
    Given I have a project
    And I create a new project
    When I run the :label admin command with:
      | resource | namespace |
      | name     | <%= project.name %> |
      | name     | <%= project(0, switch: false).name %> |
      | key_val  | testcrq=one |
    Then the step should succeed

    #clusterquota is applied to projects
    And I register clean-up steps:
    """
    When I run the :delete admin command with:
      | object_type       | clusterresourcequota    |
      | object_name_or_id | crq-<%= project.name %> |
    Then the step should succeed
    """
    When I run the :create_clusterresourcequota admin command with:
      | name           | crq-<%= project.name %>                |
      | hard           | pods=3,memory=1Gi,cpu=800m,secrets=18  |
      | label-selector | testcrq=one                            |
    Then the step should succeed

    #project quota is set to the first project
    When I run the :create_quota admin command with:
      | name | myquota                                 |
      | hard | cpu=50m,memory=80Mi,pods=5,services=1   |
      | n    | <%= project.name %>                     |
    Then the step should succeed

    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/limits.yaml |
      | n | <%= project.name %> |
    Then the step should succeed

    # check quota warning info on overview page
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed

    When I run the :check_quota_warning_on_overview_page web console action
    Then the step should succeed

    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/secret.yaml"
    Then the step should succeed

    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project.name %>                                       |
      | file_path        | <%= File.join(localhost.workdir, "secret.yaml") %> |
    Then the step should succeed

    And I wait for the steps to pass:
    """
    And I run the :click_create_button web console action
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota of 18 secrets in this project |
    Then the step should succeed
    """
    And I run the :click_cancel web console action
    Then the step should succeed

    # check quota warning info in another project
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project(0, switch: false).name %> |
    Then the step should succeed
    When I run the :check_quota_warning_on_overview_page web console action
    Then the step should succeed

    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project(0, switch: false).name %>              |
      | file_path        | <%= File.join(localhost.workdir, "secret.yaml") %> |
    Then the step should succeed

    And I wait for the steps to pass:
    """
    And I run the :click_create_button web console action
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota of 18 secrets in this project |
    Then the step should succeed
    """
    And I run the :click_cancel web console action
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id 536555
  @admin
  Scenario Outline: Show warning/error info if quotas with scopes exceeded on web console
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc536555/quota-<type>.yaml |
      | n | <%= project.name %> |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc536555/pod-<type>.yaml" replacing paths:
      | ["metadata"]["name"]   | pod1 |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc536555/pod-<type>.yaml" replacing paths:
      | ["metadata"]["name"]   | pod2 |
    Then the step should succeed

    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed

    When I run the :check_quota_warning_on_overview_page web console action
    Then the step should succeed

    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc536555/pod-<type>.yaml"
    Then the step should succeed

    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project.name %>                                       |
      | file_path        | <%= File.join(localhost.workdir, "pod-<type>.yaml") %> |
    Then the step should succeed

    And I wait for the steps to pass:
    """
    And I run the :click_create_button web console action
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota of 2 pods in this project |
    Then the step should succeed
    """
    And I run the :click_cancel web console action
    Then the step should succeed

    Examples:
      | type           |
      | besteffort     |
      | notbesteffort  |
      | terminating    |
      | notterminating |
