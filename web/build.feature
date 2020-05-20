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
