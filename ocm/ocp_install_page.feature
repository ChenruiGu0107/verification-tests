Feature: Only about install page

  # @author tzhou@redhat.com
  # @case_id OCP-21338
  Scenario: Check OCM console common part
    Given I open ocm portal as an orgAdmin user
    Then the step should succeed
    When I perform the :check_common_part web action with:
    | username | UItesting |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-21209
  Scenario: Check elements on the OCP install page - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_install_page web action
    Then the step should succeed
    When I run the :check_install_page web action
    Then the step should succeed
    When I perform the :check_provider_card web action with:
    | provider         | AWS                             |
    | provider_context | Run on Amazon Web Services      |
    | provider_href    | aws                             |
    Then the step should succeed
    When I perform the :check_provider_card web action with:
    | provider         | Azure                           |
    | provider_context | Run on Microsoft Azure          |
    | provider_href    | azure/installer-provisioned     |
    Then the step should succeed
    When I perform the :check_provider_card web action with:
    | provider         | GCP                             |
    | provider_context | Run on Google Cloud Platform    |
    | provider_href    | gcp/installer-provisioned       |
    Then the step should succeed
    When I perform the :check_provider_card web action with:
    | provider         | vSphere                         |
    | provider_context | Run on VMware vSphere           |
    | provider_href    | vsphere/user-provisioned        |
    Then the step should succeed
    When I perform the :check_provider_card web action with:
    | provider         | OpenStack                       |
    | provider_context | Run on Red Hat OpenStack        |
    | provider_href    | openstack/installer-provisioned |
    Then the step should succeed
    When I perform the :check_provider_card web action with:
    | provider         | Red Hat Virtualization          |
    | provider_context | Run on Red Hat Virtualization   |
    | provider_href    | rhv/installer-provisioned       |
    Then the step should succeed
    When I perform the :check_provider_card web action with:
    | provider         | Bare Metal                      |
    | provider_context | Run on Bare Metal               |
    | provider_href    | metal/user-provisioned          |
    Then the step should succeed
    When I perform the :check_provider_card web action with:
    | provider         | IBM                             |
    | provider_context | Run on IBM Z                    |
    | provider_href    | ibmz/user-provisioned           |
    Then the step should succeed
    When I perform the :check_provider_card web action with:
    | provider         | CRC                             |
    | provider_context | Run on Laptop                   |
    | provider_href    | crc/installer-provisioned       |
    Then the step should succeed
    When I run the :check_preview_bar web action
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-24068
  Scenario: Check elements on the OCP install page - AWS IPI - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_aws_ipi_install_page web action
    Then the step should succeed
    When I run the :check_aws_ipi_install_page web action
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-24069
  Scenario: Check elements on the OCP install page - AWS UPI - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_aws_upi_install_page web action
    Then the step should succeed
    When I run the :check_aws_upi_install_page web action
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-24071
  Scenario: Check elements on the OCP install page - Azure - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_azure_install_page web action
    Then the step should succeed
    When I run the :check_azure_install_page web action
    Then the step should succeed
    When I perform the :check_breadcrumbs_in_install_page web action with:
    | provider_name | Microsoft Azure |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-25176
  Scenario: Check elements on the OCP install page - Google Cloud - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_gcp_install_page web action
    Then the step should succeed
    When I run the :check_gcp_install_page web action
    Then the step should succeed
    When I perform the :check_breadcrumbs_in_install_page web action with:
    | provider_name | Google Cloud Platform |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-24072
  Scenario: Check elements on the OCP install page - vSphere - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_vsphere_install_page web action
    Then the step should succeed
    When I run the :check_vsphere_install_page web action
    Then the step should succeed
    When I perform the :check_breadcrumbs_in_install_page web action with:
    | provider_name | VMware vSphere |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-24070
  Scenario: Check elements on the OCP install page - Bare Metal - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_bare_metal_install_page web action
    Then the step should succeed
    When I run the :check_bare_metal_install_page web action
    Then the step should succeed
    When I perform the :check_breadcrumbs_in_install_page web action with:
    | provider_name | Bare Metal |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-26297
  Scenario: Check elements on the OCP install page - IBM Z - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_ibm_z_install_page web action
    Then the step should succeed
    When I run the :check_ibm_z_install_page web action
    Then the step should succeed
    When I perform the :check_breadcrumbs_in_install_page web action with:
    | provider_name | IBM Z |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-25174
  Scenario: Check elements on the OCP install page - Openstack - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_openstack_install_page web action
    Then the step should succeed
    When I run the :check_openstack_install_page web action
    Then the step should succeed
    When I perform the :check_breadcrumbs_in_install_page web action with:
    | provider_name | Red Hat OpenStack Platform |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-27839
  Scenario: Check elements on the OCP install page - Red Hat Virtualization - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_rhv_install_page web action
    Then the step should succeed
    When I run the :check_rhv_install_page web action
    Then the step should succeed
    When I perform the :check_breadcrumbs_in_install_page web action with:
    | provider_name | Red Hat Virtualization |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-25175
  Scenario: Check elements on the OCP install page - CodeReady - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_codeready_install_page web action
    Then the step should succeed
    When I run the :check_codeready_install_page web action
    Then the step should succeed
    When I perform the :check_breadcrumbs_in_install_page web action with:
    | provider_name | Code Ready Containers |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-26380
  Scenario: Check elements on the pre-release page - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_pre_release_page web action
    Then the step should succeed
    When I run the :check_pre_release_page web action
    Then the step should succeed
    When I perform the :check_breadcrumbs_in_install_page web action with:
    | provider_name | Pre-Release Builds |
    Then the step should succeed
