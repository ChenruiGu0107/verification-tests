Feature: Group sync related scenarios

  # @author wjiang@redhat.com
  # @case_id 509125,509126,509127
  @admin
  Scenario Outline: Sync ldap groups to openshift groups from ldap server
    Given I have a project
    Given I have LDAP service in my project
 
    Given the first user is cluster-admin
    When I download a file from "<file>"
    Then the step should succeed
    And I register clean-up steps:
    """
    I run the :delete admin command with:
      | object_type       | groups      |
      | object_name_or_id | <group1>    |
      | object_name_or_id | <group2>    |
      | object_name_or_id | <group3>    |
    the step succeeded
    """
    And I replace lines in "<file_name>":
      |LDAP_SERVICE_IP:389|127.0.0.1:3389|
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
