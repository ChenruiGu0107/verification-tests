Feature: only about cluster access cases

  # @author yuwan@redhat.com
  Scenario Outline: Check the UI layout for configuring IDP-UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I run the :click_access_control_tab web action
    Then the step should succeed
    When I run the :click_add_identity_provider web action
    Then the step should succeed
    When I run the :check_idp_dialog_header web action
    Then the step should succeed
    When I run the :check_idp_steps_titles web action
    Then the step should succeed
    When I perform the :choose_and_check_ipd_info web action with:
      | idp_type | <idptype> |
    Then the step should succeed
    When I run the :check_idp_dialog_footer web action
    Then the step should succeed
    When I run the :click_idp_dialog_cancel_button web action
    Then the step should succeed
    When I run the :check_idp_hint web action
    Then the step should succeed

    Examples:
      | idptype  |
      | GitHub   | # @case_id OCP-23707
      | OpenID   | # @case_id OCP-24004
      | LDAP     | # @case_id OCP-24006
      | Google   | # @case_id OCP-24002

  # @author yuwan@redhat.com
  # @case_id OCP-26823
  Scenario: Check the IDP info on 'Access Control' TAB
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I run the :click_access_control_tab web action
    Then the step should succeed
    When I run the :check_empty_idp_info_in_tab web action
    Then the step should succeed
    When I run the :click_add_identity_provider web action
    Then the step should succeed
    When I perform the :configure_fake_idp web action with:
      | idp_type             | GitHub    |
      | github_name          | githubidp |
      | github_client_id     | ttttt     |
      | github_client_secret | ppppp     |
      | github_organizations | org       |
    Then the step should succeed
    When I run the :click_idp_confirm_button web action
    Then the step should succeed
    When I perform the :check_first_idp_item web action with:
      | idp_name | githubidp |
      | idp_type | GitHub    |
    Then the step should succeed
    When I perform the :delete_idp web action with:
      | idp_name | githubidp |
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-26633
  Scenario: The IDP banner and the access to add IDPs should be hidden if the org member user is not the cluster owner
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-admin |
    Then the step should succeed
    When I run the :check_idp_hint_missing web action
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-28661
  Scenario: Check the UI validation for the IDP configuration dialog
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I run the :click_access_control_tab web action
    Then the step should succeed
    When I run the :click_add_identity_provider web action
    Then the step should succeed
    When I perform the :choose_ipd web action with:
      | idp_type | GitHub |
    Then the step should succeed
    When I run the :check_github_idp_validations web action
    Then the step should succeed
    When I perform the :choose_ipd web action with:
      | idp_type | Google |
    Then the step should succeed
    When I run the :check_google_idp_validations web action
    Then the step should succeed
    When I perform the :choose_ipd web action with:
      | idp_type | LDAP |
    Then the step should succeed
    When I run the :check_ldap_idp_validations web action
    Then the step should succeed
    When I perform the :choose_ipd web action with:
      | idp_type | OpenID |
    Then the step should succeed
    When I perform the :check_openid_idp_validations web action with:
      | ldap_bind_dn | dn |
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-27994
  Scenario: Check the UI layout of the 'AWS infrastructure access' in the 'Access Control' tab
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I run the :click_access_control_tab web action
    Then the step should succeed
    When I run the :check_basic_elements_on_AWS_infrastructure_access_tab web action
    Then the step should succeed
    When I perform the :grant_AWS_infrastructure_role web action with:
      | aws_iam_arn | arn:aws:iam::301721915996:user/yuwan |
      | role        | Network management                   |
    Then the step should succeed
    And I register clean-up steps:
    """
    When I perform the :delete_AWS_infrastructure_role web action with:
      | aws_iam_arn | arn:aws:iam::301721915996:user/yuwan |
      | role        | Network management                   |
    Then the step should succeed
    """
    When I run the :check_AWS_infrastructure_role_list_structure web action
    Then the step should succeed
