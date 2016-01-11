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

