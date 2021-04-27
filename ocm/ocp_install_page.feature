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
      | provider         | AWS                        |
      | provider_context | Run on Amazon Web Services |
      | provider_href    | aws                        |
    Then the step should succeed
    When I perform the :check_provider_card web action with:
      | provider         | Azure                  |
      | provider_context | Run on Microsoft Azure |
      | provider_href    | azure                  |
    Then the step should succeed
    When I perform the :check_provider_card web action with:
      | provider         | GCP                          |
      | provider_context | Run on Google Cloud Platform |
      | provider_href    | gcp                          |
    Then the step should succeed
    When I perform the :check_provider_card web action with:
      | provider         | vSphere                  |
      | provider_context | Run on VMware vSphere    |
      | provider_href    | vsphere/user-provisioned |
    Then the step should succeed
    When I perform the :check_provider_card web action with:
      | provider         | OpenStack                |
      | provider_context | Run on Red Hat OpenStack |
      | provider_href    | openstack                |
    Then the step should succeed
    When I perform the :check_provider_card web action with:
      | provider         | Red Hat Virtualization        |
      | provider_context | Run on Red Hat Virtualization |
      | provider_href    | rhv                           |
    Then the step should succeed
    When I perform the :check_provider_card web action with:
      | provider         | Bare Metal        |
      | provider_context | Run on Bare Metal |
      | provider_href    | metal             |
    Then the step should succeed
    When I perform the :check_provider_card web action with:
      | provider         | IBM                   |
      | provider_context | Run on IBM Z          |
      | provider_href    | ibmz/user-provisioned |
    Then the step should succeed
    When I perform the :check_provider_card web action with:
      | provider         | Power Systems          |
      | provider_context | Run on Power           |
      | provider_href    | power/user-provisioned |
    Then the step should succeed
    When I perform the :check_provider_card web action with:
      | provider         | CRC                       |
      | provider_context | Run on Laptop             |
      | provider_href    | crc/installer-provisioned |
    Then the step should succeed
    # When I run the :check_preview_bar web action
    # Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-24068
  Scenario: Check elements on the OCP install page - AWS IPI - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_aws_ipi_install_page web action
    Then the step should succeed
    When I perform the :check_aws_ipi_install_page web action with:
      | title | Install OpenShift on AWS with installer-provisioned infrastructure |
    Then the step should succeed
    When I perform the :check_breadcrumbs_include_infrastructure_in_install_page web action with:
      | provider_link  | aws                                  |
      | provider_name  | Amazon Web Services                  |
      | infrastructure | Installer-provisioned infrastructure |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-24069
  Scenario: Check elements on the OCP install page - AWS UPI - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_aws_upi_install_page web action
    Then the step should succeed
    When I perform the :check_aws_upi_install_page web action with:
      | title | Install OpenShift on AWS with user-provisioned infrastructure |
    Then the step should succeed
    When I perform the :check_breadcrumbs_include_infrastructure_in_install_page web action with:
      | provider_link  | aws                             |
      | provider_name  | Amazon Web Services             |
      | infrastructure | User-provisioned infrastructure |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-24071
  Scenario: Check elements on the OCP install page - Azure - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_azure_ipi_install_page web action
    Then the step should succeed
    When I perform the :check_azure_ipi_install_page web action with:
      | title | Install OpenShift on Azure with installer-provisioned infrastructure |
    Then the step should succeed
    When I perform the :check_breadcrumbs_include_infrastructure_in_install_page web action with:
      | provider_link  | azure                                |
      | provider_name  | Microsoft Azure                      |
      | infrastructure | Installer-provisioned infrastructure |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-28794
  Scenario: Check elements on the OCP install page - Azure UPI - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_azure_upi_install_page web action
    Then the step should succeed
    When I perform the :check_azure_upi_install_page web action with:
      | title | Install OpenShift on Azure with user-provisioned infrastructure |
    Then the step should succeed
    When I perform the :check_breadcrumbs_include_infrastructure_in_install_page web action with:
      | provider_link  | azure                           |
      | provider_name  | Microsoft Azure                 |
      | infrastructure | User-provisioned infrastructure |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-25176
  Scenario: Check elements on the OCP install page - GCP IPI - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_gcp_ipi_install_page web action
    Then the step should succeed
    When I perform the :check_gcp_ipi_install_page web action with:
      | title | Install OpenShift on GCP with installer-provisioned infrastructure |
    Then the step should succeed
    When I perform the :check_breadcrumbs_include_infrastructure_in_install_page web action with:
      | provider_link  | gcp                                  |
      | provider_name  | Google Cloud Platform                |
      | infrastructure | Installer-provisioned infrastructure |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-28796
  Scenario: Check elements on the OCP install page - GCP UPI - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_gcp_upi_install_page web action
    Then the step should succeed
    When I perform the :check_gcp_upi_install_page web action with:
      | title | Install OpenShift on GCP with user-provisioned infrastructure |
    Then the step should succeed
    When I perform the :check_breadcrumbs_include_infrastructure_in_install_page web action with:
      | provider_link  | gcp                             |
      | provider_name  | Google Cloud Platform           |
      | infrastructure | User-provisioned infrastructure |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-41209
  Scenario: Check elements on the OCP install page - vSphere IPI- UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_vsphere_ipi_install_page web action
    Then the step should succeed
    When I perform the :check_vsphere_ipi_install_page web action with:
      | title | Install OpenShift on vSphere with installer-provisioned infrastructure |
    Then the step should succeed
    When I perform the :check_breadcrumbs_include_infrastructure_in_install_page web action with:
      | provider_link  | vsphere                              |
      | provider_name  | VMware vSphere                       |
      | infrastructure | Installer-provisioned infrastructure |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-24072
  Scenario: Check elements on the OCP install page - vSphere - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_vsphere_install_page web action
    Then the step should succeed
    When I perform the :check_vsphere_install_page web action with:
      | title | Install OpenShift on vSphere with user-provisioned infrastructure |
    Then the step should succeed
    When I perform the :check_breadcrumbs_include_infrastructure_in_install_page web action with:
      | provider_link  | vsphere                         |
      | provider_name  | VMware vSphere                  |
      | infrastructure | User-provisioned infrastructure |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-25174
  Scenario: Check elements on the OCP install page - Openstack - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_openstack_ipi_install_page web action
    Then the step should succeed
    When I perform the :check_openstack_ipi_install_page web action with:
      | title | Install OpenShift on Red Hat OpenStack Platform with installer-provisioned infrastructure |
    Then the step should succeed
    When I perform the :check_breadcrumbs_include_infrastructure_in_install_page web action with:
      | provider_link  | openstack                            |
      | provider_name  | Red Hat OpenStack Platform           |
      | infrastructure | Installer-provisioned infrastructure |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-28795
  Scenario: Check elements on the OCP install page - Openstack UPI - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_openstack_upi_install_page web action
    Then the step should succeed
    When I perform the :check_openstack_upi_install_page web action with:
      | title | Install OpenShift on Red Hat OpenStack Platform with user-provisioned infrastructure |
    Then the step should succeed
    When I perform the :check_breadcrumbs_include_infrastructure_in_install_page web action with:
      | provider_link  | openstack                       |
      | provider_name  | Red Hat OpenStack Platform      |
      | infrastructure | User-provisioned infrastructure |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-27839
  Scenario: Check elements on the OCP install page - Red Hat Virtualization - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_rhv_ipi_install_page web action
    Then the step should succeed
    When I perform the :check_rhv_ipi_install_page web action with:
      | title | Install OpenShift on Red Hat Virtualization with installer-provisioned infrastructure |
    Then the step should succeed
    When I perform the :check_breadcrumbs_include_infrastructure_in_install_page web action with:
      | provider_link  | rhv                                  |
      | provider_name  | Red Hat Virtualization               |
      | infrastructure | Installer-provisioned infrastructure |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-36001
  Scenario: Check elements on the OCP install page - Red Hat Virtualization UPI - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_rhv_upi_install_page web action
    Then the step should succeed
    When I perform the :check_rhv_upi_install_page web action with:
      | title | Install OpenShift on Red Hat Virtualization with user-provisioned infrastructure |
    Then the step should succeed
    When I perform the :check_breadcrumbs_include_infrastructure_in_install_page web action with:
      | provider_link  | rhv                             |
      | provider_name  | Red Hat Virtualization          |
      | infrastructure | User-provisioned infrastructure |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-36034
  Scenario: Check elements on the OCP install page - Bare Metal IPI - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_bare_metal_ipi_install_page web action
    Then the step should succeed
    When I perform the :check_bare_metal_ipi_install_page web action with:
      | title | Install OpenShift on Bare Metal with installer-provisioned infrastructure |
    Then the step should succeed
    When I perform the :check_breadcrumbs_include_infrastructure_in_install_page web action with:
      | provider_link  | metal                                |
      | provider_name  | Bare Metal                           |
      | infrastructure | Installer-provisioned infrastructure |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-24070
  Scenario: Check elements on the OCP install page - Bare Metal UPI - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_bare_metal_upi_install_page web action
    Then the step should succeed
    When I perform the :check_bare_metal_upi_install_page web action with:
      | title | Install OpenShift on Bare Metal with user-provisioned infrastructure |
    Then the step should succeed
    When I perform the :check_breadcrumbs_include_infrastructure_in_install_page web action with:
      | provider_link  | metal                           |
      | provider_name  | Bare Metal                      |
      | infrastructure | User-provisioned infrastructure |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-26297
  Scenario: Check elements on the OCP install page - IBM Z - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_ibm_z_install_page web action
    Then the step should succeed
    When I perform the :check_ibm_z_install_page web action with:
      | title | Install OpenShift on IBM Z with user-provisioned infrastructure |
    Then the step should succeed
    When I perform the :check_breadcrumbs_exclude_infrastructure_in_install_page web action with:
      | provider_name | IBM Z |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-30121
  Scenario: Check elements on the OCP install page - Power UPI - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_power_upi_install_page web action
    Then the step should succeed
    When I perform the :check_power_upi_install_page web action with:
      | title | Install OpenShift on Power with user-provisioned infrastructure |
    Then the step should succeed
    When I perform the :check_breadcrumbs_exclude_infrastructure_in_install_page web action with:
      | provider_name | Power |
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

  # @author tzhou@redhat.com
  # @case_id OCP-26380
  Scenario: Check elements on the pre-release page - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_pre_release_page web action
    Then the step should succeed
    When I run the :check_pre_release_page web action
    Then the step should succeed
    When I perform the :check_breadcrumbs_exclude_infrastructure_in_install_page web action with:
      | provider_name | Pre-Release Builds |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-29426
  Scenario: Check elements on ARO pull secret page - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_aro_pull_secret_page web action
    Then the step should succeed
    When I run the :check_aro_pull_secret_page web action
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-29428
  Scenario: Check elements on pull secret page - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_pull_secret_page web action
    Then the step should succeed
    When I run the :check_pull_secret_page web action
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-38887
  Scenario: Check elements on the Datacenter tab on create page - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_creation_page_datacenter_tab web action
    Then the step should succeed
    When I run the :check_creation_page_datacenter_tab web action
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-38888
  Scenario: Check elements on the Cloud tab on create page with quota - UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :go_to_creation_page_cloud_tab web action
    Then the step should succeed
    When I run the :check_creation_page_cloud_tab_with_quota web action
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-38889
  Scenario: Check elements on the Cloud tab on create page without quota - UI
    Given I open ocm portal as an noAnyQuotaUser user
    Then the step should succeed
    When I run the :go_to_creation_page_cloud_tab web action
    Then the step should succeed
    When I run the :check_creation_page_cloud_tab_without_quota web action
    Then the step should succeed
    When I run the :check_creation_page_cloud_tab_specific_part_with_quota web action
    Then the step should fail
