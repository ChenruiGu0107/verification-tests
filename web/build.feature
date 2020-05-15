Feature: build related feature on web console
  # @author xxia@redhat.com
  # @case_id OCP-12476, OCP-12486
  Scenario Outline: Check build trigger info about webhook on web
    Given I have a project
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json |
    Then the step should succeed

    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/pkg/build/webhook/<path><file>"
    And I replace lines in "<file>":
      | 9bdc3a26ff933b32f3e558636b58aea86a69f051 | e79d8870be808a7abb4ab304e94c8bee69d909c6 |
      | <url_before>                             | <url_after>                              |
    Then the step should succeed

    # Wait build #1 is created first
    Given the "ruby-sample-build-1" build was created
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-sample-build/webhooks/secret101/<type>
    :method: post
    :headers:
      :content-type: application/json
      :<header1>: <header2>
    :payload: <%= File.read("<file>").to_json %>
    """
    Then the step should succeed

    # Check build #2
    Given the "ruby-sample-build-2" build was created
    When I perform the :check_build_trigger web console action with:
      | project_name      | <%= project.name %>                     |
      | bc_and_build_name | ruby-sample-build/ruby-sample-build-2   |
      | trigger_info      | <trigger_info>                          |
    Then the step should succeed

    When I perform the :check_build_hidden_secret web console action with:
      | project_name      | <%= project.name %>                     |
      | bc_and_build_name | ruby-sample-build/ruby-sample-build-2   |
      | hidden_text       | secr                                    |
    Then the step should succeed

    # Following checkpoint is only from the TC about generic webhook.
    # Because the script uses Examples Table, the TC about github webhook
    # has to also include it.
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-sample-build/webhooks/secret101/generic
    :method: post
    :headers:
      :content-type: application/json
    """
    Then the step should succeed

    # Check build #3
    Given the "ruby-sample-build-3" build was created
    When I perform the :check_build_trigger web console action with:
      | project_name      | <%= project.name %>                      |
      | bc_and_build_name | ruby-sample-build/ruby-sample-build-3    |
      | trigger_info      | Generic webhook: no revision information |
    Then the step should succeed

    Examples:
      # Check build trigger info when the trigger is generic webhook on web
      | type    | path              | file              | header1 | header2 | url_before                   | url_after                                       | trigger_info |
      | generic | generic/testdata/ | push-generic.json |         |         | git://mygitserver/myrepo.git | git://github.com/openshift/ruby-hello-world.git | Generic webhook: Random act of kindness e79d887 authored by Jon Doe |

    Examples:
      # Check build trigger info when the trigger is github webhook on web
      | type    | path              | file           | header1        | header2 | url_before | url_after | trigger_info |
      | github  | github/testdata/  | pushevent.json | X-Github-Event | push    |            |           | GitHub webhook: Added license e79d887 authored by Anonymous User |

  # @author yapei@redhat.com
  # @case_id OCP-14629
  Scenario: Check Gitlab and Bitbucket webhooks in the BC editor
    Given the master version >= "3.6"
    Given I have a project
    When I run the :new_build client command with:
      | code         | https://github.com/openshift/ruby-hello-world |
      | image        | openshift/ruby:latest                         |
    Then the step should succeed
    Given I wait for the :add_webhook_type_on_bc_edit_page web console action to succeed with:
      | project_name  | <%= project.name %> |
      | bc_name       | ruby-hello-world    |
      | webhook_type  | GitLab              |
    When I run the :describe client command with:
      | resource | bc/ruby-hello-world |
    Then the step should succeed
    And evaluation of `@result[:response].scan(/https.*gitlab$/)` is stored in the :gitlab_webhook clipboard
    Given I wait for the :add_webhook_type_on_bc_edit_page web console action to succeed with:
      | project_name  | <%= project.name %> |
      | bc_name       | ruby-hello-world    |
      | webhook_type  | Bitbucket           |
    When I run the :describe client command with:
      | resource | bc/ruby-hello-world |
    Then the step should succeed
    And evaluation of `@result[:response].scan(/https.*bitbucket$/)` is stored in the :bitbucket_webhook clipboard
    # Check GitLab and Bitbucket webhook on web
    When I perform the :check_bc_webhook_trigger_in_configuration web console action with:
      | project_name    | <%= project.name %>                              |
      | bc_name         | ruby-hello-world                                 |
      | webhook_trigger | <%= cb.bitbucket_webhook[0].scan(/oapi.*/)[0] %> |
    Then the step should succeed
    When I perform the :check_bc_webhook_trigger_in_configuration web console action with:
      | project_name    | <%= project.name %>                            |
      | bc_name         | ruby-hello-world                               |
      | webhook_trigger | <%= cb.gitlab_webhook[0].scan(/oapi.*/)[0] %>  |
    Then the step should succeed
    When I perform the :check_bc_webhook_trigger_on_bc_edit_page web console action with:
      | project_name    | <%= project.name %>                              |
      | bc_name         | ruby-hello-world                                 |
      | webhook_trigger | <%= cb.bitbucket_webhook[0].scan(/oapi.*/)[0] %> |
    Then the step should succeed
    When I perform the :check_bc_webhook_trigger_on_bc_edit_page web console action with:
      | project_name    | <%= project.name %>                            |
      | bc_name         | ruby-hello-world                               |
      | webhook_trigger | <%= cb.gitlab_webhook[0].scan(/oapi.*/)[0] %>  |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-17073
  Scenario: Support add ConfigMap/Secret as build env on web console
    Given the master version >= "3.9"
    Given I have a project
    # create configmap and secret
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap.json          |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap-example.yaml  |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/secrets/secret.yaml               |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/secrets/tc519256/testsecret1.json |
    Then the step should succeed
    # check configmap/secret support during create app from image
    When I perform the :create_app_from_image_with_advanced_options web console action with:
      | primary_catagory | Languages  |
      | sub_catagory     | PHP        |
      | service_item     | PHP        |
      | app_name         | php-sample |
    Then the step should succeed
    When I perform the :add_env_var_using_configmap_or_secret_for_build web console action with:
      | env_var_key   | env_from_sec |
      | resource_name | test-secret  |
      | resource_key  | data-1       |
    Then the step should succeed
    When I perform the :add_env_var_using_configmap_or_secret_for_build web console action with:
      | env_var_key   | env_from_conmap |
      | resource_name | special-config  |
      | resource_key  | special.type    |
    Then the step should succeed
    When I run the :click_create_button web console action
    Then the step should succeed
    When I perform the :goto_buildconfig_environment_tab web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | php-sample          |
    Then the step should succeed
    When I perform the :check_configmap_or_secret_env_var web console action with:
      | env_var_key   | env_from_sec  |
      | resource_name | test-secret   |
      | resource_key  | data-1        |
    Then the step should succeed
    When I perform the :check_configmap_or_secret_env_var web console action with:
      | env_var_key   | env_from_conmap |
      | resource_name | special-config  |
      | resource_key  | special.type    |
    Then the step should succeed
    # check configmap/secret support on buildconfig Environment tab
    When I perform the :add_env_var_using_configmap_or_secret web console action with:
      | env_var_key   | env_from_sec2 |
      | resource_name | test-secret   |
      | resource_key  | data-2        |
    Then the step should succeed
    When I perform the :add_env_var_using_configmap_or_secret web console action with:
      | env_var_key   | env_from_conmap2 |
      | resource_name | special-config   |
      | resource_key  | special.type     |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    Given 5 seconds have passed
    # check configmap/secret support on buildconfig edit page
    When I perform the :check_buildconfig_edit_page_loaded_completely web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | php-sample          |
    Then the step should succeed
    When I perform the :add_env_var_using_configmap_or_secret web console action with:
      | env_var_key   | env_from_sec3 |
      | resource_name | testsecret1   |
      | resource_key  | secret1       |
    Then the step should succeed
    When I perform the :add_env_var_using_configmap_or_secret web console action with:
      | env_var_key   | env_from_conmap3   |
      | resource_name | example-config     |
      | resource_key  | example.property.1 |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :goto_buildconfig_environment_tab web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | php-sample          |
    Then the step should succeed
    When I perform the :check_configmap_or_secret_env_var web console action with:
      | env_var_key   | env_from_sec3 |
      | resource_name | testsecret1   |
      | resource_key  | secret1       |
    Then the step should succeed
    When I perform the :check_configmap_or_secret_env_var web console action with:
      | env_var_key   | env_from_conmap3   |
      | resource_name | example-config     |
      | resource_key  | example.property.1 |
