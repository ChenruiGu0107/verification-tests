Feature: motd related scenarios
  # @author xiyuan@redhat.com
  # @case_id OCP-25862
  @admin
  @destructive
  Scenario: the "oc login" command displays the legal notice on both successful and unsuccessful logins
    Given admin ensures "motd" configmap is deleted from the "openshift" project after scenario
    When a 5 characters random string of type :dns is stored into the :crole clipboard
    And admin ensures "<%= cb.crole %>" clusterrole is deleted after scenario

    When I run the :create_configmap admin command with:
      | name         | motd                             |
      | from_literal | message="This is a legal notice" |
      | namespace    | openshift                        |
    Then the step should succeed
    When I run the :create_clusterrole admin command with:
      | name          | <%= cb.crole %> |
      | resource      | configmap       |
      | resource-name | motd            |
      | verb          | get             |
    Then the step should succeed
    Given cluster role "<%= cb.crole %>" is added to the "system:unauthenticated" group

    When I switch to the first user
    And I run the :login client command with:
      | u               | <%= @user.name %>           |
      | p               | <%= @user.password %>       |
      | config          | test.kubeconfig             |
      | server          | <%= env.api_endpoint_url %> |
      | skip_tls_verify | true                        |
    Then the step should succeed
    And the output should contain:
      | Login successful       |
      | This is a legal notice |
    When I run the :login client command with:
      | token           | <%= user.cached_tokens.first %> |
      | config          | test.kubeconfig                 |
      | server          | <%= env.api_endpoint_url %>     |
      | skip_tls_verify | true                            |
    Then the step should succeed
    And the output should contain:
      | Logged into            |
      | This is a legal notice |

    When I switch to cluster admin pseudo user
    And I run the :login client command with:
      | u | system:admin |
    Then the step should succeed
    And the output should contain:
      | Logged into            |
      | This is a legal notice |

    When I run the :patch admin command with:
      | resource      | configmap                                                |
      | n             | openshift                                                |
      | resource_name | motd                                                     |
      | p             | {"data": {"message": "This is a legal notice !@#$%^*&"}} |
    Then the step should succeed

    When I switch to the first user
    And I run the :login client command with:
      | u               | <%= @user.name %>           |
      | p               | <%= @user.password %>       |
      | config          | test.kubeconfig             |
      | server          | <%= env.api_endpoint_url %> |
      | skip_tls_verify | true                        |
    Then the step should succeed
    And the output should contain:
      | Login successful       |
      | This is a legal notice |
      | !@#$%^*&               |

    Given I have a project
    When I run the :serviceaccounts_get_token client command with:
      | serviceaccount_name | default             |
      | n                   | <%= project.name %> |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :token clipboard
    When I run the :login client command with:
      | token           | <%= cb.token %>             |
      | config          | test.kubeconfig             |
      | server          | <%= env.api_endpoint_url %> |
      | skip_tls_verify | true                        |
    Then the step should succeed
    And the output should contain:
      | Logged into            |
      | This is a legal notice |
      | !@#$%^*&               |

    When I run the :login client command with:
      | u               | <% user.name %>             |
      | p               | <% @cb[:rand_str %>         |
      | config          | test.kubeconfig             |
      | server          | <%= env.api_endpoint_url %> |
      | skip_tls_verify | true                        |
    Then the step should fail
    And the output should contain:
      | This is a legal notice |
      | !@#$%^*&               |
      | Login failed           |
    When I run the :login client command with:
      | token           | <% @cb[rand_str %>          |
      | config          | test.kubeconfig             |
      | server          | <%= env.api_endpoint_url %> |
      | skip_tls_verify | true                        |
    Then the step should fail
    And the output should contain:
      | This is a legal notice                   |
      | !@#$%^*&                                 |
      | The token provided is invalid or expired |

  # @author xiyuan@redhat.com
  # @case_id OCP-25872
  @admin
  @destructive
  Scenario: the "oc login" command will not display the legal notice when ConfigMap empty or user has no permission to motd config
    Given admin ensures "motd" configmap is deleted from the "openshift" project after scenario
    And admin ensures "moto" configmap is deleted from the "openshift" project after scenario
    When a 5 characters random string of type :dns is stored into the :crole clipboard
    And admin ensures "<%= cb.crole %>" clusterrole is deleted after scenario

    When I run the :create_configmap admin command with:
      | name         | motd                             |
      | from_literal | message="This is a legal notice" |
      | namespace    | openshift                        |
    Then the step should succeed
    When I run the :create_clusterrole admin command with:
      | name          | <%= cb.crole %> |
      | resource      | configmap       |
      | resource-name | motd            |
      | verb          | get             |
    Then the step should succeed
    Given cluster role "<%= cb.crole %>" is added to the "system:unauthenticated" group

    When I run the :patch admin command with:
      | resource      | configmap                 |
      | n             | openshift                 |
      | resource_name | motd                      |
      | p             | {"data": {"message": ""}} |
    Then the step should succeed
    When I switch to the first user
    And I run the :login client command with:
      | u               | <%= @user.name %>           |
      | p               | <%= @user.password %>       |
      | config          | test.kubeconfig             |
      | server          | <%= env.api_endpoint_url %> |
      | skip_tls_verify | true                        |
    Then the step should succeed
    And the output should not contain:
      | This is a legal notice |
    When I switch to the second user
    And I run the :login client command with:
      | u               | <%= @user.name %>           |
      | p               | <% @cb[:rand_str %>         |
      | config          | test.kubeconfig             |
      | server          | <%= env.api_endpoint_url %> |
      | skip_tls_verify | true                        |
    Then the step should fail
    And the output should not contain:
      | This is a legal notice |

    Given admin ensures "motd" configmap is deleted from the "openshift" project
    When I run the :create_configmap admin command with:
      | name         | moto                             |
      | from_literal | message="This is a legal notice" |
      | namespace    | openshift                        |
    Then the step should succeed
    When I switch to the third user
    And I run the :login client command with:
      | u               | <%= @user.name %>           |
      | p               | <%= @user.password %>       |
      | config          | test.kubeconfig             |
      | server          | <%= env.api_endpoint_url %> |
      | skip_tls_verify | true                        |
    Then the step should succeed
    And the output should not contain:
      | This is a legal notice |
    When I switch to the second user
    And I run the :login client command with:
      | u               | <%= @user.name %>           |
      | p               | <% @cb[:rand_str %>         |
      | config          | test.kubeconfig             |
      | server          | <%= env.api_endpoint_url %> |
      | skip_tls_verify | true                        |
    Then the step should fail
    And the output should not contain:
      | This is a legal notice |

    Given admin ensures "moto" configmap is deleted from the "openshift" project
    When I run the :create_configmap admin command with:
      | name         | motd                             |
      | from_literal | message="This is a legal notice" |
      | namespace    | openshift                        |
    Then the step should succeed

    When I run the :patch admin command with:
      | resource      | clusterrole.rbac.authorization.k8s.io                                                                   |
      | resource_name | <%= cb.crole %>                                                                                         |
      | p             | {"rules": [{"apiGroups": [""],"resourceNames": ["moto"],"resources": ["configmaps"],"verbs": ["get"]}]} |
    Then the step should succeed
    When I switch to the first user
    And I run the :login client command with:
      | u               | <%= @user.name %>           |
      | p               | <%= @user.password %>       |
      | config          | test.kubeconfig             |
      | server          | <%= env.api_endpoint_url %> |
      | skip_tls_verify | true                        |
    Then the step should succeed
    And the output should contain:
      | This is a legal notice |
    When I run the :login client command with:
      | u               | <%= @user.name %>           |
      | p               | <% @cb[:rand_str %>         |
      | config          | test.kubeconfig             |
      | server          | <%= env.api_endpoint_url %> |
      | skip_tls_verify | true                        |
    Then the step should fail
    And the output should not contain:
      | This is a legal notice |
