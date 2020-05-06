Feature: proxybuild.feature
  # @author wewang@redhat.com
  # @case_id OCP-24347
  @admin
  Scenario: Build take proxy in buildconfig prior to global proxy
    Given I have a project
    When I run the :new_build client command with:
      | image_stream | openshift/ruby                                    |
      | app_repo     | https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    And the "ruby-hello-world-1" build completed
    When evaluation of `proxy_config_openshift_io('cluster')` is stored in the :proxies_name clipboard
    Then evaluation of `cb.proxies_name.http_proxy(user: admin)` is stored in the :http_proxy clipboard
    And evaluation of `cb.proxies_name.https_proxy(user: admin)` is stored in the :https_proxy clipboard
    When I run the :patch client command with:
      | resource      | bc                  |
      | resource_name | ruby-hello-world    |
      | p             | {"spec":{"source":{"git":{"httpProxy":"<%= cb.http_proxy %>","httpsProxy":"<%= cb.https_proxy %>","noProxy":"test.local"}}}} |
      | n             | <%= project.name %> |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world    |
      | n           | <%= project.name %> |
    Then the step should succeed
    And the "ruby-hello-world-2" build completed
    When I run the :patch client command with:
      | resource      | bc                  |
      | resource_name | ruby-hello-world    |
      | p             | {"spec":{"source":{"git":{"httpProxy":"invalid.rdu.redhat.com:3128","httpsProxy":"invalid.rdu.redhat.com:3128","noProxy":".local"}}}} |
      | n             | <%= project.name %> |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world    |
      | n           | <%= project.name %> |
    Then the step should succeed
    And the "ruby-hello-world-3" build failed
    And I run the :logs client command with:
      | resource_name | bc/ruby-hello-world  |
      | n             |  <%= project.name %> |
      | f             |                      |
    Then the output should contain:
      | Could not resolve proxy |

  # @author wewang@redhat.com
  # @case_id OCP-24339
  @admin
  @destructive
  Scenario: Build controller can consume global proxy setting
    Given I have a project
    When I run the :new_build client command with:
      | image_stream | openshift/ruby                                |
      | app_repo | https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    And the "ruby-hello-world-1" build completed
    When I run the :patch admin command with:
      | resource | build.config.openshift.io/cluster |
      | p        | {"spec":{"buildDefaults":{"gitProxy":{"httpProxy":"invalid.rdu.redhat.com:3128","httpsProxy":"invalid.rdu.redhat.com:3128","noProxy":"test.local"}}}} |
      | type     |  merge                            |
    Then the step should succeed
    And I register clean-up steps:
    """
    When I run the :patch admin command with:
      | resource | build.config.openshift.io/cluster |
      | p        | {"spec":{}}                       |
      | type     |  merge                            |
    Then the step should succeed
    """
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world    |
      | n           | <%= project.name %> |
    Then the step should succeed
    And the "ruby-hello-world-2" build failed
    And I run the :logs client command with:
      | resource_name | bc/ruby-hello-world |
      | n             | <%= project.name %> |
      | f             |                     |
    Then the output should contain:
      | Could not resolve proxy |
