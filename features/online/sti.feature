Feature: ONLY ONLINE STI related scripts in this file

  # @author etrott@redhat.com
  # @case_id 530022
  # @case_id 530007
  # @case_id 530005
  Scenario Outline: Private Repository can be used to providing dependency caching for STI builds
    Given I have a project
    Given I perform the :create_app_from_image_with_bc_env_and_sample_repo web console action with:
      | project_name | <%= project.name %>                               |
      | image_name   | <image>                                           |
      | image_tag    | <image_tag>                                       |
      | namespace    | openshift                                         |
      | app_name     | sti-sample                                        |
      | bc_env_key   | <env_name>                                        |
      | bc_env_value | https://mirror.openshift.com/mirror/non-existing/ |
    Then the step should succeed
    When I perform the :wait_latest_build_to_status web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | sti-sample          |
      | build_status | failed              |
    Then the step should succeed
    When I perform the :check_build_log_tab web console action with:
      | project_name      | <%= project.name %>     |
      | bc_and_build_name | sti-sample/sti-sample-1 |
      | build_status_name | Failed                  |
    Then the step should succeed
    When I perform the :check_build_log_content web console action with:
      | build_log_context | <error_message> https://mirror.openshift.com/mirror/non-existing/ |
    Then the step should succeed
    Given I perform the :change_env_vars_on_buildconfig_edit_page web console action with:
      | project_name      | <%= project.name %>                             |
      | bc_name           | sti-sample                                      |
      | env_variable_name | <env_name>                                      |
      | new_env_value     | https://mirror.openshift.com/mirror/<env_value> |
    Then the step should succeed
    When I run the :save_buildconfig_changes web console action
    Then the step should succeed
    When I click the following "button" element:
      | text  | Start Build |
      | class | btn-default |
    Then the step should succeed
    When I run the :check_build_has_started_message web console action
    Then the step should succeed
    When I perform the :wait_latest_build_to_status web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | sti-sample          |
      | build_status | complete            |
    Then the step should succeed
    When I perform the :check_build_log_tab web console action with:
      | project_name      | <%= project.name %>     |
      | bc_and_build_name | sti-sample/sti-sample-2 |
      | build_status_name | Complete                |
    Then the step should succeed

    Examples: Python
      | image  | image_tag | env_name      | env_value          | error_message               |
      | python | 2.7       | PIP_INDEX_URL | python/web/simple/ | Cannot fetch index base URL |
      | python | 3.3       | PIP_INDEX_URL | python/web/simple/ | Cannot fetch index base URL |
      | python | 3.4       | PIP_INDEX_URL | python/web/simple/ | Cannot fetch index base URL |
      | python | 3.5       | PIP_INDEX_URL | python/web/simple/ | Cannot fetch index base URL |

    Examples: Ruby
      | image | image_tag | env_name       | env_value | error_message              |
      # ruby 2.0 has no environment variable for mirror url.
      | ruby  | 2.2       | RUBYGEM_MIRROR | ruby/     | Could not fetch specs from |
      | ruby  | 2.3       | RUBYGEM_MIRROR | ruby/     | Could not fetch specs from |

    Examples: Perl
      | image | image_tag | env_name    | env_value  | error_message |
      | perl  | 5.16      | CPAN_MIRROR | perl/CPAN/ | Fetching      |
      | perl  | 5.20      | CPAN_MIRROR | perl/CPAN/ | Fetching      |
