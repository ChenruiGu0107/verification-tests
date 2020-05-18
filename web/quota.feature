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
