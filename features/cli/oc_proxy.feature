Feature: oc proxy related scenarios
  # @author xxia@redhat.com
  # @case_id 528444
  Scenario: Simple usage of oc proxy as API server
    Given I have a project
    And evaluation of `rand(32000..64000)` is stored in the :port clipboard
    When I run the :proxy background client command with:
      | port      | <%= cb.port %>   |
    Then the step should succeed

    Given I wait for the "localhost:<%= cb.port %>" TCP server to start accepting connections
    And a "dummy.config" file is created with the following lines:
    """
    """

    # Select some oc commands tested against oc proxy
    # "get" command
    When I run the :get client command with:
    # Specify full args --server, -n, and use dummy.config rather than the config
    # enforced by current FW, so it really checks oc commands against oc proxy
      | resource | pod         |
      | server   | http://127.0.0.1:<%= cb.port %>     |
      | n        | <%= project.name %>                 |
      | config   | dummy.config|
    Then the step should succeed

    # "create" command
    When I run the :create client command with:
      | f        | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
      | server   | http://127.0.0.1:<%= cb.port %>     |
      | n        | <%= project.name %>                 |
      | config   | dummy.config|
    Then the step should succeed

  # @author xxia@redhat.com
  # @case_id 528446
  Scenario: Advanced usage of oc proxy as API server
    Given I have a project
    And evaluation of `rand(32000..64000)` is stored in the :port1 clipboard
    And evaluation of `rand(32000..64000)` is stored in the :port2 clipboard
    And evaluation of `rand(32000..64000)` is stored in the :port3 clipboard
    And a "dummy.config" file is created with the following lines:
    """
    """

    Given I create the "mydir" directory
    And a "mydir/index.html" file is created with the following lines:
    """
    Hello, this is oc proxy test
    """
    When I run the :proxy background client command with:
      | port        | <%= cb.port1 %>      |
      | www         | mydir     |
      | www_prefix  | /myprefix |
    Then the step should succeed

    Given I wait for the "localhost:<%= cb.port1 %>" TCP server to start accepting connections
    When I perform the HTTP request:
    """
    :url: http://127.0.0.1:<%= cb.port1 %>/myprefix/
    :method: get
    """
    Then the step should succeed
    And the output should contain "Hello, this is oc proxy test"

    When I run the :proxy background client command with:
      | port          | <%= cb.port2 %>     |
      | reject_paths  | ^/api/.*/pods.*     |
      | accept_paths  | ^/api.*,^/oapi.*,^/oauth.* |
    Then the step should succeed

    Given I wait for the "localhost:<%= cb.port2 %>" TCP server to start accepting connections
    When I run the :get client command with:
      | resource | dc,svc      |
      | server   | http://127.0.0.1:<%= cb.port2 %>    |
      | n        | <%= project.name %>                 |
      | config   | dummy.config|
    Then the step should succeed
    When I run the :get client command with:
      | resource | pod         |
      | server   | http://127.0.0.1:<%= cb.port2 %>    |
      | n        | <%= project.name %>                 |
      | config   | dummy.config|
    Then the step should fail
    And the output should contain "does not allow access to the requested resource"

    When I run the :proxy background client command with:
      | port          | <%= cb.port3 %>     |
      | api_prefix    | /my-api             |
    Then the step should succeed
    Given I wait for the "localhost:<%= cb.port3 %>" TCP server to start accepting connections
    When I perform the HTTP request:
    """
    :url: 127.0.0.1:<%= cb.port3 %>/my-api/api/v1/namespaces/<%= project.name %>/pods/
    :method: get
    """
    Then the step should succeed
