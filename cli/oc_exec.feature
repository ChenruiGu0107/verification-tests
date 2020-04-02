Feature: containers related features
  # @author pruan@redhat.com
  Scenario Outline: Choose container to execute command on with '-c' flag
    Given I have a project
    And evaluation of `"doublecontainers"` is stored in the :pod_name clipboard
    When I run the :create client command with:
      | filename | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/pod_with_two_containers.json|
    Then the step should succeed
    And the pod named "doublecontainers" becomes ready
    When I run the :exec client command with:
      | _tool            | <tool>               |
      | pod              | <%= cb.pod_name %>   |
      | exec_command     | cat                  |
      | exec_command_arg | /etc/redhat-release  |
    Then the output should contain:
      | CentOS Linux release 7.0.1406 (Core) |
    When I run the :exec client command with:
      | _tool            | <tool>                 |
      | pod              | <%= cb.pod_name %>     |
      | c                | hello-openshift-fedora |
      | exec_command     | cat                    |
      | exec_command_arg | /etc/redhat-release    |
    Then the output should contain:
      | Fedora release 21 (Twenty One) |
    # cover bug #1517212
    When I run the :exec client command with:
      | _tool            | <tool>              |
      | pod              | <%= cb.pod_name %>  |
      | t                |                     |
      | i                |                     |
      | exec_command     | cat                 |
      | exec_command_arg | /etc/redhat-release |
    Then the output should contain:
      | CentOS Linux release 7.0.1406 (Core) |

    Examples:
      | tool     |
      | oc       | # @case_id OCP-10579
      | kubectl  | # @case_id OCP-21058

  # @author xxing@redhat.com
  Scenario Outline: Dumps logs from a given Pod container
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/hello-pod.json |
    Then the step should succeed
    Given the pod named "hello-openshift" becomes ready
    When I run the :logs client command with:
      | _tool         | <tool>          |
      | resource_name | hello-openshift |
    Then the output should contain:
      | serving on 8081 |
      | serving on 8888 |

    Examples:
      | tool     |
      | oc       | # @case_id OCP-12378
      | kubectl  | # @case_id OCP-21062

  # @author xxing@redhat.com
  # @case_id OCP-11501
  Scenario: Add env variables to postgresql-92-centos7 image
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/image/db-templates/postgresql-92-centos7-env-test.json |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=database-1 |
    When I run the :get client command with:
      | resource | pods |
    Then the output should contain:
      | NAME            |
      | <%= pod.name %> |
    When I run the :describe client command with:
      | resource | pod             |
      | name     | <%= pod.name %> |
    Then the output should match:
      | Status:\\s+Running                        |
      | Image:\\s+openshift/postgresql-92-centos7 |
      | Ready\\s+True                             |
    When I execute on the pod:
      | bash                |
      | -c                  |
      | env \| grep POSTGRE |
    Then the output should contain:
      | POSTGRESQL_SHARED_BUFFERS=64MB |
      | POSTGRESQL_MAX_CONNECTIONS=42  |
    When I execute on the pod:
      | bash                           |
      | -c                             |
      | psql -c 'show shared_buffers;' |
    Then the output should contain:
      | shared_buffers |
      | 64MB           |
    And I execute on the pod:
      | bash                            |
      | -c                              |
      | psql -c 'show max_connections;' |
    Then the output should contain:
      | max_connections |
      | 42              |

  # @author pruan@redhat.com
  # @case_id OCP-11704
  Scenario: Executing commands in a container that isn't running
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/tc472859/hello-pod.json|
    And the pod named "hello-openshift" status becomes :pending
    And I run the :exec client command with:
      | pod | hello-openshift |
      | container | hello-openshift |
      | exec_command | ls      |
    Then the step should fail
    And the output should match:
      | [Ee]rror.*not |

  # @author chaoyang@redhat.com
  # @case_id OCP-11451
  Scenario: Executing command in inexistent containers
    When I have a project
    And I run the :create client command with:
      | filename |<%= BushSlicer::HOME %>/features/tierN/testdata/pods/hello-pod.json |
    Then the step should succeed
    And the pod named "hello-openshift" becomes ready
    When I execute on the "hello-openshift_notexist" pod:
      | date |
    Then the step should fail
    Then the output should match:
      | [Ee]rror.*pods.*hello-openshift_notexist.*not found |
    When I run the :exec client command with:
      | pod          | hello-openshift          |
      | c            | hello-openshift-notexist |
      | exec_command | date                     |
    Then the step should fail
    Then the output should match:
      |[Ee]rror.*container hello-openshift-notexist.*not valid|

  # @author xiaocwan@redhat.com
  # @case_id OCP-11083
  @smoke
  Scenario: [origin_infra_311] Executing a command in container
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json"
    And I replace lines in "hello-pod.json":
      | "openshift/hello-openshift" | <%= project_docker_repo %>"aosqe/hello-openshift"|
    Then the step should succeed
    When I run the :create client command with:
      | f       | hello-pod.json |
    Then the step should succeed
    Given the pod named "hello-openshift" becomes ready
    When I run the :exec client command with:
      | pod          | hello-openshift |
      | c                | hello-openshift |
      | i            |       |
      | t            |       |
      | oc_opts_end  |       |
      | exec_command | sh    |
      | exec_command_arg | -il    |
    Then the step should succeed
    When I execute on the pod:
      | sh                     |
      | -c                     |
      | env \| grep KUBERNETES |
    Then the output should contain:
      | KUBERNETES_PORT |

  # @author xxia@redhat.com
  Scenario Outline: oc exec, rsh and port-forward should work behind authenticated proxy
    Given I have a project
    And I have an authenticated proxy configured in the project
    And evaluation of `rand(5000..7999)` is stored in the :port1 clipboard
    When I run the :port_forward background client command with:
      | _tool     | <tool>                                 |
      | pod       | <%= cb[:proxy_pod].name %>             |
      | port_spec | <%= cb[:port1] %>:<%= cb.proxy_port %> |
    Then the step should succeed

    # Prepare pod for following CLI executions behind proxy
    When I run the :run client command with:
      | _tool     | <tool>                 |
      | name      | mypod                  |
      | image     | aosqe/hello-openshift  |
      | restart   | Never                  |
    Then the step should succeed
    And the pod named "mypod" becomes ready

    # CLI executions behind proxy
    When I run the :exec client command with:
      | _tool            | <tool>                                                |
      | pod              | mypod                                                 |
      | exec_command     | ls                                                    |
      | exec_command_arg | /etc                                                  |
      | _env             | https_proxy=tester:redhat@127.0.0.1:<%= cb[:port1] %> |
    Then the step should succeed
    And the output should contain "hosts"

    When I run the :rsh client command with:
      | pod     | mypod                                                 |
      | command | ls                                                    |
      | command | /etc                                                  |
      | _env    | https_proxy=tester:redhat@127.0.0.1:<%= cb[:port1] %> |
    Then the step should succeed

    Given evaluation of `rand(5000..7999)` is stored in the :port2 clipboard
    When I run the :port_forward background client command with:
      | _tool     | <tool>                                                |
      | pod       | mypod                                                 |
      | port_spec | <%= cb[:port2] %>:8081                                |
      | _env      | https_proxy=tester:redhat@127.0.0.1:<%= cb[:port1] %> |
    Then the step should succeed
    Given I wait up to 120 seconds for the steps to pass:
    """
    When I open web server via the "127.0.0.1:<%= cb[:port2] %>" url
    Then the step should succeed
    And the output should contain "Hello OpenShift"
    """
    Then I terminate last background process

    # CLI executions with wrong authentication behind proxy
    When I run the :rsh client command with:
      | pod     | mypod                                                |
      | command | ls                                                   |
      | command | /etc                                                 |
      | _env    | https_proxy=tester:wrong@127.0.0.1:<%= cb[:port1] %> |
    Then the step should fail

    Examples:
      | tool     |
      | oc       | # @case_id OCP-11564
      | kubectl  | # @case_id OCP-21060
