Feature: Group sync related scenarios

  # @author wjiang@redhat.com
  # @case_id 509125,509126,509127
  @admin
  Scenario Outline: Sync ldap groups to openshift groups from ldap server
    Given I have a project
    Given I have LDAP service in my project
 
    Given I switch to cluster admin pseudo user
    When I download a file from "<file>"
    Then the step should succeed
    Given admin ensures "<group1>" group is deleted after scenario
    Given admin ensures "<group2>" group is deleted after scenario
    Given admin ensures "<group3>" group is deleted after scenario
    And I replace lines in "<file_name>":
      |LDAP_SERVICE_IP:389|127.0.0.1:<%= cb.ldap_port %>|
    When I run the :oadm_groups_sync admin command with:
      |sync_config  |<file_name>	|
      |confirm      |		        |
    Then the step should succeed
    And the output should match:
      |<sync_regex>	|
    When I run the :get admin command with:
      |resource| groups |
    Then the step should succeed
    And the output should match:
      |<get_regex>	|
    Examples:
      |file                                                                                                     |group1         |group2         |group3         |file_name          |sync_regex                                                         |get_regex                                                  |
      |https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/groups/ad/sync-config.yaml            |tc509126group1 |tc509126group2 |tc509126group3 |sync-config.yaml   |group/tc509126group1\sgroup/tc509126group2\sgroup/tc509126group3   |tc509126group1\s.*\stc509126group2\s.*\stc509126group3\s   |
      |https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/groups/rfc2307/sync-config.yaml       |tc509125group1 |tc509125group2 |tc509125group3 |sync-config.yaml   |group/tc509125group1\sgroup/tc509125group2\sgroup/tc509125group3   |tc509125group1\s.*\stc509125group2\s.*\stc509125group3\s   |
      |https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/groups/augmented-ad/sync-config.yaml  |tc509127group1 |tc509127group2 |tc509127group3 |sync-config.yaml   |group/tc509127group1\sgroup/tc509127group2\sgroup/tc509127group3   |tc509127group1\s.*\stc509127group2\s.*\stc509127group3\s   |


  # @author wjiang@redhat.com
  # @case_id 509128
  @admin
  Scenario: Sync openShift groups from ldap server with blacklist
    Given I have a project
    Given I have LDAP service in my project 

    Given I switch to cluster admin pseudo user
    Given admin ensures "tc509128group1" group is deleted after scenario
    Given admin ensures "tc509128group2" group is deleted after scenario
    Given admin ensures "tc509128group3" group is deleted after scenario
    Given a "blacklist_ldap" file is created with the following lines:
      |cn=group1,ou=groups,ou=rfc2307,dc=example,dc=com|
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/groups/rfc2307/sync-config-user-defined.yaml"
    Then the step should succeed
    And I replace lines in "sync-config-user-defined.yaml":
      |LDAP_SERVICE_IP:389|127.0.0.1:<%= cb.ldap_port %>|
    When I run the :oadm_groups_sync admin command with:
      |sync_config|sync-config-user-defined.yaml  |
      |confirm    |                               |
      |blacklist  |blacklist_ldap                 |
    Then the step should succeed
    And the output should not contain:
      |tc509128group1     |

    # Add users for group2 and group3
    When I run the :rsh client command with:
      |pod    |<%= cb.ldap_pod_name %>                                                                                                                                                                                                                                  |
      |_stdin |curl -Ss https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/groups/rfc2307/add-user-to-group.ldif > /tmp/add-user-to-group.ldif && ldapmodify -f /tmp/add-user-to-group.ldif -h 127.0.0.1 -p 389 -D cn=Manager,dc=example,dc=com -w admin |
      |n      |<%= project.name %>                                                                                                                                                                                                                                  |
    Then the step should succeed
    
    Given a "blacklist_openshift" file is created with the following lines:
      |tc509128group2|
    When I run the :oadm_groups_sync admin command with:
      |sync_config|sync-config-user-defined.yaml  |
      |confirm    |                               |
      |blacklist  |blacklist_openshift            |
      |type       |openshift                      |
    Then the step should succeed
    And the output should contain:
      |tc509128group3     |
    When I run the :get client command with:
      |resource   |groups/tc509128group2  |
    Then the step should succeed
    And the output should not contain:
      |person4    |
    When I run the :get client command with:
      |resource   |groups/tc509128group3  |
    Then the step should succeed
    And the output should contain:
      |person4    |


  # @author wjiang@redhat.com
  # @case_id 509129
  @admin
  Scenario: Sync openshift groups with ldap server for some specific groups 
    Given I have a project
    Given I have LDAP service in my project

    Given I switch to cluster admin pseudo user
    Given admin ensures "tc509129group1" group is deleted after scenario
    Given admin ensures "tc509129group2" group is deleted after scenario
    Given admin ensures "tc509129group3" group is deleted after scenario
    Given a "whitelist_ldap" file is created with the following lines:
      |cn=group2,ou=groups,ou=rfc2307,dc=example,dc=com|
      |cn=group3,ou=groups,ou=rfc2307,dc=example,dc=com|
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/groups/rfc2307/sync-config-partially-user-defined.yaml"
    Then the step should succeed
    And I replace lines in "sync-config-partially-user-defined.yaml":
      |LDAP_SERVICE_IP:389|127.0.0.1:<%= cb.ldap_port %>|
    When I run the :oadm_groups_sync admin command with:
      |sync_config  |sync-config-partially-user-defined.yaml|
      |confirm      |                                       |
      |whitelist    |whitelist_ldap                         |
    Then the step should succeed
    And the output should contain:
      |tc509129group2   |
      |tc509129group3   |
    And the output should not contain:
      |tc509129group1   |

    When I run the :rsh client command with:
      |pod    |<%= cb.ldap_pod_name %>                                                                                                                                                                                                                                         |
      |_stdin |curl -Ss https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/groups/rfc2307/add-user-to-group.ldif > /tmp/add-user-to-group.ldif && ldapmodify -f /tmp/add-user-to-group.ldif -h 127.0.0.1 -p 389 -D cn=Manager,dc=example,dc=com -w admin   |
      |n      |<%= project.name %>                                                                                                                                                                                                                                         |
    Then the step should succeed

    Given a "whitelist_openshift" file is created with the following lines:
      |tc509129group3   |
    When I run the :oadm_groups_sync admin command with:
      |sync_config  |sync-config-partially-user-defined.yaml|
      |confirm      |                                       |
      |whitelist    |whitelist_openshift                    |
      |type         |openshift                              |
    Then the step should succeed
    And the output should contain:
      |tc509129group3       |
    When I run the :get client command with:
      |resource     |groups/tc509129group2                  |
    Then the step should succeed
    And the output should not contain:
      |person4      |
    When I run the :get client command with:
      |resource     |groups/tc509129group3                  |
    Then the step should succeed
    And the output should contain:
      |person4      |

    When I run the :oadm_groups_sync admin command with:
      |sync_config  |sync-config-partially-user-defined.yaml|
      |confirm      |                                       |
      |group_names  |groups/tc509129group2                  |
      |type         |openshift                              |
    Then the step should succeed
    And the output should contain:
      |tc509129group2       |
    And the output should not contain:
      |tc509129group1       |
      |tc509129group3       |
    When I run the :get client command with:
      |resource     |groups/tc509129group2                  |
    Then the step should succeed
    And the output should contain:
      |person4      |

