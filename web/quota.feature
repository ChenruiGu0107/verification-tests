Feature: functions about resourcequotas

  # @author yanpzhan@redhat.com
  # @case_id OCP-9886 OCP-9888 OCP-9889
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
    When I perform the :goto_quota_page web console action with:
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
    When I perform the :goto_quota_page web console action with:
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
      | Not Best Effort | <%= BushSlicer::HOME %>/features/tierN/testdata/quota/quota-notbesteffort.yaml | <%= BushSlicer::HOME %>/features/tierN/testdata/quota/pod-notbesteffort.yaml | <%= BushSlicer::HOME %>/features/tierN/testdata/quota/pod-besteffort.yaml |
      | Terminating | <%= BushSlicer::HOME %>/features/tierN/testdata/quota/quota-terminating.yaml | <%= BushSlicer::HOME %>/features/tierN/testdata/quota/pod-terminating.yaml | <%= BushSlicer::HOME %>/features/tierN/testdata/quota/pod-notterminating.yaml |
      | Not Terminating | <%= BushSlicer::HOME %>/features/tierN/testdata/quota/quota-notterminating.yaml | <%= BushSlicer::HOME %>/features/tierN/testdata/quota/pod-notterminating.yaml | <%= BushSlicer::HOME %>/features/tierN/testdata/quota/pod-terminating.yaml |

  # @author yanpzhan@redhat.com
  # @case_id OCP-9887
  @admin
  Scenario: Check BestEffort scope of resourcequota on web console
    Given I have a project
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/quota/quota-besteffort.yaml |
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
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/quota/pod-besteffort.yaml |
    Then the step should succeed

    #Check used quota when "besteffort" pod exists
    When I perform the :goto_quota_page web console action with:
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
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/quota/pod-notbesteffort.yaml |
    Then the step should succeed

    #Check used quota when only "notbesteffort" pod exists
    When I perform the :goto_quota_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed
    When I perform the :check_used_value web console action with:
      | resource_type | Pods |
      | used_value    | 0    |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-12098
  @admin
  Scenario Outline: Show warning/error info if quotas with scopes exceeded on web console
    Given I have a project
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/quota/tc536555/quota-<type>.yaml |
      | n | <%= project.name %> |
    Then the step should succeed

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/quota/tc536555/pod-<type>.yaml" replacing paths:
      | ["metadata"]["name"]   | pod1 |
    Then the step should succeed
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/quota/tc536555/pod-<type>.yaml" replacing paths:
      | ["metadata"]["name"]   | pod2 |
    Then the step should succeed

    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed

    When I run the :check_quota_warning_on_overview_page web console action
    Then the step should succeed

    When I obtain test data file "quota/tc536555/pod-<type>.yaml"
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

  # @author hasha@redhat.com
  # @case_id OCP-12988
  @admin
  Scenario: Show warning info when storage reaches the pvc number limits of project quota
    Given the master version >= "3.6"
    Given I have a project
    # Create quota for current project
    When I run the :create_quota admin command with:
      | name | myquota                                         |
      | hard | requests.storage=100Gi,persistentvolumeclaims=2 |
      | n    | <%= project.name %>                             |
    Then the step should succeed
    # Create the first pvc for project
    When I perform the :create_pvc_from_storage_page web console action with:
      | project_name    | <%= project.name %>       |
      | pvc_name        | pvc-1                     |
      | pvc_access_mode | ReadWriteMany             |
      | storage_size    | 1                         |
      | storage_unit    | GiB                       |
    Then the step should succeed
    # Create dc
    When I run the :run client command with:
      | name      | myrun                 |
      | image     | aosqe/hello-openshift |
    Then the step should succeed
    When I perform the :check_create_storage_link_on_add_storage_page web console action with:
      | project_name   | <%= project.name %>    |
      | dc_name        | myrun                  |
    Then the step should succeed
    # Create the second pvc
    When I perform the :create_pvc_from_storage_page web console action with:
      | project_name    | <%= project.name %>        |
      | pvc_name        | pvc-2                      |
      | pvc_access_mode | ReadWriteMany              |
      | storage_size    | 1                          |
      | storage_unit    | GiB                        |
    Then the step should succeed
    When I perform the :check_exceed_quota_warning_on_add_storage_page web console action with:
      | project_name   | <%= project.name %>    |
      | dc_name        | myrun                  |
    Then the step should succeed
    When I perform the :check_quota_warning_on_storage_page web console action with:
      | project_name   | <%= project.name %>    |
    Then the step should succeed

  # @author hasha@redhat.com
  # @case_id OCP-12990
  @admin
  Scenario: Show warning info when storage reaches the storage limits of project quota
    Given the master version >= "3.6"
    Given I have a project
    # Create quota for current project
    When I run the :create_quota admin command with:
      | name | myquota                |
      | hard | requests.storage=2Gi   |
      | n    | <%= project.name %>    |
    Then the step should succeed
    When I perform the :create_pvc_from_storage_page web console action with:
      | project_name    | <%= project.name %>       |
      | pvc_name        | pvc-1                     |
      | pvc_access_mode | ReadWriteMany             |
      | storage_size    | 1                         |
      | storage_unit    | GiB                       |
    Then the step should succeed
    When I perform the :create_larger_than_quota_pvc_from_storage_page web console action with:
      | project_name    | <%= project.name %>       |
      | pvc_name        | pvc-2                     |
      | pvc_access_mode | ReadWriteMany             |
      | storage_size    | 2                         |
      | storage_unit    | GiB                       |
    Then the step should succeed
    When I perform the :create_pvc_from_storage_page web console action with:
      | project_name    | <%= project.name %>       |
      | pvc_name        | pvc-3                     |
      | pvc_access_mode | ReadWriteMany             |
      | storage_size    | 1                         |
      | storage_unit    | GiB                       |
    Then the step should succeed
    When I perform the :check_quota_warning_on_storage_page web console action with:
      | project_name   | <%= project.name %>    |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-13487
  @admin
  Scenario: Check warning/error info when import template with special resource from json/yaml
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create_quota admin command with:
      | name | myquota             |
      | hard | pods=1,services=1   |
      | n    | <%= project.name %> |
    Then the step should succeed

    #check 2 kinds of warning info
    When I run the :run client command with:
      | name      | mypod                  |
      | image     | aosqe/hello-openshift  |
      | limits    | cpu=50m,memory=80Mi    |
      | generator | run-pod/v1             |
    Then the step should succeed

    When I obtain test data file "templates/OCP-13487/test-template.json"
    Then the step should succeed

    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project.name %>                             |
      | file_path        | <%= localhost.absolutize("test-template.json") %> |
    Then the step should succeed
    When I run the :click_create_button web console action
    Then the step should succeed
    When I perform the :process_and_save_template web console action with:
      | process_template | true  |
      | save_template    | false |
    Then the step should succeed

    When I run the :click_create_button web console action
    Then the step should succeed

    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | This will create resources that may have security or project behavior implications |
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota for pods |
    Then the step should succeed
    And I run the :click_cancel web console action
    Then the step should succeed

    #check 1 warning info and 1 error info
    When I run the :delete client command with:
      | object_type       | pod   |
      | object_name_or_id | mypod |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project.name %>                             |
      | file_path        | <%= localhost.absolutize("test-template.json") %> |
    Then the step should succeed
    When I run the :click_create_button web console action
    Then the step should succeed
    When I perform the :process_and_save_template web console action with:
      | process_template | true  |
      | save_template    | false |
    Then the step should succeed

    When I run the :click_create_button web console action
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | This will create resources that may have security or project behavior implications |
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | You are at your quota of 1 service in this project |
    Then the step should succeed
    And I run the :click_cancel web console action
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-13464
  @admin
  Scenario: Check warning info when create special resources from json/yaml
    Given the master version >= "3.6"
    Given I have a project

    #check warning info when create pv
    When I obtain test data file "storage/nfs/nfs-default.json"
    Then the step should succeed

    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project.name %>                         |
      | file_path        | <%= localhost.absolutize("nfs-default.json") %> |
    Then the step should succeed
    And I run the :click_create_button web console action
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | This will create resources outside of the project, which might impact all users of the cluster |
    Then the step should succeed

    And I run the :click_cancel web console action
    Then the step should succeed

    #check warning info when create quota
    When I obtain test data file "quota/myquota.yaml"
    Then the step should succeed

    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project.name %>                         |
      | file_path        | <%= localhost.absolutize("myquota.yaml") %> |
    Then the step should succeed
    And I run the :click_create_button web console action
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | This will create resources that may have security or project behavior implications |
    Then the step should succeed
    And I run the :click_create_anyway web console action
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | Unable to create the resource quota |
    Then the step should succeed

    #check warning info when create role
    When I obtain test data file "rbac/OCP-12989/role.json"
    Then the step should succeed

    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project.name %>                      |
      | file_path        | <%= localhost.absolutize("role.json") %> |
    Then the step should succeed
    And I run the :click_create_button web console action
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | This will create additional membership roles within the project |
    Then the step should succeed
    And I run the :click_create_anyway web console action
    Then the step should succeed
    When I run the :get client command with:
      | resource   | role |
    And the output should contain:
      | deleteservices |

    #check warning info when create rolebinding
    When I obtain test data file "rbac/OCP-12989/rolebinding.yaml"
    Then the step should succeed

    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project.name %>                             |
      | file_path        | <%= localhost.absolutize("rolebinding.yaml") %> |
    Then the step should succeed
    And I run the :click_create_button web console action
    Then the step should succeed
    And I perform the :check_quota_warning_info_when_submit_create web console action with:
      | prompt_info | This will grant permissions to your project |
    Then the step should succeed
    And I run the :click_cancel web console action
    Then the step should succeed
