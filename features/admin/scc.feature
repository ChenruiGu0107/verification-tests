    Feature: SCC policy related scenarios

      # @author xiacwan@redhat.com
      # @case_id 511817
      @admin
      Scenario: Cluster-admin can add & remove user or group to from scc

        Given a 5 characters random string of type :dns is stored into the :scc_name clipboard
        When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/scc_privileged.yaml"
        And I replace lines in "scc_privileged.yaml":
          | scc-pri | <%= cb.scc_name %> |
        And I switch to cluster admin pseudo user
        Given the following scc policy is created: scc_privileged.yaml
        Then the step should succeed

        When I run the :oadm_policy_add_scc_to_user admin command with:
          | scc   | <%= cb.scc_name %>  |
          | user_name  | <%= user(0, switch: false).name %>  |
        And I run the :oadm_policy_add_scc_to_user admin command with:
          | scc   | <%= cb.scc_name %>  |
          | user_name  | <%= user(1, switch: false).name %>  |
        And I run the :oadm_policy_add_scc_to_user admin command with:
          | scc       | <%= cb.scc_name %>  |
          | user_name |             |
          | serviceaccount | system:serviceaccount:default:default |
        And I run the :oadm_policy_add_scc_to_user admin command with:
          | scc       | <%= cb.scc_name %>  |
          | user_name | system:admin |
        And I run the :oadm_policy_add_scc_to_group admin command with:
          | scc       | <%= cb.scc_name %>  |
          | group_name | system:authenticated |
        When I run the :get admin command with:
          | resource | scc |
          | resource_name | <%= cb.scc_name %>  |
          | o        | yaml |
        Then the output should contain:
          |  <%= user(0, switch: false).name %>     |
          |  <%= user(1, switch: false).name %>     |
          |  system:serviceaccount:default:default  |
          |  system:admin  |
          |  system:authenticated |

        When I run the :oadm_policy_remove_scc_from_user admin command with:
          | scc        | <%= cb.scc_name %>  |
          | user_name  | <%= user(0, switch: false).name %>  |
        And I run the :oadm_policy_remove_scc_from_user admin command with:
          | scc        | <%= cb.scc_name %>  |
          | user_name  | <%= user(1, switch: false).name %>  |
        And I run the :oadm_policy_remove_scc_from_user admin command with:
          | scc        | <%= cb.scc_name %>  |
          | user_name  |             |
          | serviceaccount | system:serviceaccount:default:default |
        And I run the :oadm_policy_remove_scc_from_user admin command with:
          | scc        | <%= cb.scc_name %>  |
          | user_name  | system:admin |
        And I run the :oadm_policy_remove_scc_from_group admin command with:
          | scc        | <%= cb.scc_name %>  |
          | group_name | system:authenticated |
        When I run the :get admin command with:
          | resource | scc |
          | resource_name | <%= cb.scc_name %>  |
          | o        | yaml |
        Then the output should not contain:
          |  <%= user(0, switch: false).name %>  |
          |  <%= user(1, switch: false).name %>  |
          |  system:serviceaccount:default:default  |
          |  system:admin  |
          |  system:authenticated  |

    #@author bmeng@redhat.com
    #@case_id 495027
    @admin
    Scenario: Add/drop capabilities for container when SC matches the SCC
      Given I have a project
      And evaluation of `project.name` is stored in the :project_name clipboard
      When I run the :create client command with:
          |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_cap_kill.json|
      Then the step should fail
      And the output should contain "forbidden: unable to validate against any security context constraint"
      And the output should contain "invalid value 'KILL', Details: capability may not be added"
      Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/scc_capabilities.yaml"
      And I replace lines in "scc_capabilities.yaml":
          |system:serviceaccounts:default|system:serviceaccounts:<%= cb.project_name %>|
      Given the following scc policy is created: scc_capabilities.yaml
      When I run the :get admin command with:
          |resource|scc|
          |resource_name|scc-cap|
      Then the output should contain "[KILL]"
      When I run the :create client command with:
          |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_cap_kill.json|
      Then the step should succeed
      When I run the :create client command with:
          |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_cap_chown.json|
      Then the step should fail
      And the output should contain "invalid value 'CHOWN'"
