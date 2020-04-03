Feature: About cluster list page

# @author tzhou@redhat.com
# @case_id OCP-23574
Scenario: Check cluster summary page with the account who does not have available resource quota - UI
  Given I open ocm portal as an noAnyQuotaUser user
  Then the step should succeed
  When I run the :check_cluster_list_page_without_cluster web action
  Then the step should succeed
  When I run the :switch_to_creation_cards_page web action
  Then the step should succeed
  When I run the :check_creation_cards_page web action
  Then the step should succeed
  When I run the :check_osd_button_enable web action
  Then the step should fail
  When I run the :check_osd_button_disable web action
  Then the step should succeed

# @author tzhou@redhat.com
# @case_id OCP-21339
Scenario: Check cluster list in cluster summary page - UI
  Given I open ocm portal as an regularUser user
  Then the step should succeed
  When I run the :cluster_list_page_loaded web action
  Then the step should succeed
  When I run the :check_cluster_list_page web action
  Then the step should succeed
  When I perform the :check_clusters_list_info web action with:
  | cluster_name   | sdqe-ui-ocp                      |
  | cluster_status | disconnected                     |
  | cluster_type   | OCP                              |
  Then the step should succeed
  When I perform the :check_clusters_list_info web action with:
  | cluster_name   | sdqe-ui-disconn-vcpu-type        |
  | cluster_status | disconnected                     |
  | cluster_type   | OCP                              |
  Then the step should succeed
  When I perform the :check_clusters_list_info web action with:
  | cluster_name   | sdqe-ui-disconnected             |
  | cluster_status | disconnected                     |
  | cluster_type   | OCP                              |
  Then the step should succeed
  When I perform the :check_clusters_list_info web action with:
  | cluster_name   | sdqe-ui-default                  |
  | cluster_status | ready                            |
  | cluster_type   | OSD                              |
  Then the step should succeed
  When I perform the :check_clusters_list_info web action with:
  # known issue: https://issues.redhat.com/browse/SDB-825
  | cluster_name   | sdqe-ui-archive                  |
  | cluster_status | disconnected                     |
  | cluster_type   | OCP                              |
  Then the step should succeed
  When I perform the :check_clusters_list_info web action with:
  | cluster_name   | sdqe-ui-advanced                 |
  | cluster_status | ready                            |
  | cluster_type   | OSD                              |
  Then the step should succeed
  When I perform the :check_clusters_list_info web action with:
  | cluster_name   | sdaqe-ui-disconnected-adminowned |
  | cluster_status | disconnected                     |
  | cluster_type   | OCP                              |
  Then the step should succeed
  When I run the :check_hover_in_cluster_list web action
  Then the step should succeed
