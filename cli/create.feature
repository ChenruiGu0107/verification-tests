Feature: creating 'apps' with CLI
  # @author anli@redhat.com
  # @case_id OCP-11075
  Scenario: Project admin could not grant cluster-admin permission to other users
    When I have a project
    And I run the :oadm_policy_add_cluster_role_to_user client command with:
      | role_name | cluster-admin  |
      | user_name | <%= user(1).name %>  |
    Then the step should fail
    And the output should contain "User "<%= user(1).name %>" cannot"

  # @author pruan@redhat.com
  # @case_id OCP-11897
  Scenario: create app from existing template via CLI with parameter passed
    Given I have a project
    Given I obtain test data file "templates/ui/application-template-stibuild-without-customize-route.json"
    When I run the :create client command with:
      | f | application-template-stibuild-without-customize-route.json |
    Then the step should succeed
    And I run the :get client command with:
      | resource | template |
    Then the step should succeed
    And the output should contain:
      | ruby-helloworld-sample   This example shows how to create a simple ruby application in openshift |
    And I run the :new_app client command with:
      | template | ruby-helloworld-sample |
      | param    | MYSQL_DATABASE=db1     |
    Then the step should succeed
    When I get project dc named "frontend" as YAML
    Then the output by order should match:
      | name: MYSQL_DATABASE |
      | value: db1           |
    When I get project dc named "database" as YAML
    Then the output by order should match:
      | name: MYSQL_DATABASE |
      | value: db1           |

  # @author yinzhou@redhat.com
  # @case_id OCP-12148
  Scenario: Progress with invalid supplemental groups should not be run when using RunAsAny as the RunAsGroupStrategy
    Given I have a project
    Given I obtain test data file "pods/pod_with_special_supplementalGroups.json"
    When I run the :create client command with:
      | f       | pod_with_special_supplementalGroups.json |
    Then the step should fail
    And the output should contain:
      | Pod "hello-openshift" is invalid  |
      | Invalid value                     |
      | must be between 0 and 2147483647  |

  # @author yinzhou@redhat.com
  # @case_id OCP-11932
  Scenario: Process with special supplemental groups can be run when using RunAsAny as the RunAsGroupStrategy
    Given I have a project
    When I obtain test data file "pods/pod_with_special_supplementalGroups.json"
    And I replace lines in "pod_with_special_supplementalGroups.json":
      |4294967296|0|
    Then the step should succeed
    When I run the :create client command with:
      | f | pod_with_special_supplementalGroups.json |
    Then the step should succeed
    When the pod named "hello-openshift" becomes ready
    When I get project pod named "hello-openshift" as YAML
    Then the output by order should match:
      | securityContext:|
      | supplementalGroups: |
      | - 0 |

  # @author pruan@redhat.com
  # @case_id OCP-10722
  @admin
  @destructive
  Scenario: Process with default or manually defined supplemental groups in the range can be ran when using MustRunAs as the RunAsGroupStrategy
    Given I have a project
    Given scc policy "restricted" is restored after scenario
    Given as admin I replace resource "scc" named "restricted":
      | RunAsAny | MustRunAs |
    When I run the :get client command with:
      | resource      | project             |
      | resource_name | <%= project.name %> |
    And evaluation of `project.uid_range(user:user).begin` is stored in the :scc_limit clipboard
    When I run oc create over ERB test file: pods/510541/scc_rules.json
    Then the step should succeed
    When the pod named "hello-pod" status becomes :running

    Given I obtain test data file "pods/hello-pod.json"
    Given I run the :create client command with:
      | f | hello-pod.json |
    Then the step should succeed
    When I get project pods named "hello-pod"
    Then the expression should be true> pod.supplemental_groups(user:user)[0] == cb.scc_limit

  # @author pruan@redhat.com
  # @case_id OCP-11537
  @admin
  Scenario: Process with special FSGroup id can be ran when using custom defined rule of MustRunAs as the RunAsGroupStrategy
    Given I have a project
    When I run the :get client command with:
      | resource      | project             |
      | resource_name | <%= project.name %> |
    # create and save the invalid supplemental_group_id
    And evaluation of `project.supplemental_groups(user:user).begin - 1000` is stored in the :invalid_sgid clipboard
    When I obtain test data file "pods/ocp11537/special_fs_groupid.json"
    And I replace lines in "special_fs_groupid.json":
      | 1000 | <%= cb.invalid_sgid %> |
      | 1001 | <%= cb.invalid_sgid %> |
    Then I run the :create client command with:
      | f | special_fs_groupid.json |
    Then the step should not succeed
    And the output should contain:
      | unable to validate against any security context constraint |
      | <%= cb.invalid_sgid %> is not an allowed group             |
    # step 3 create new scc rule as cluster admin and add user to the new scc
    Given I obtain test data file "pods/ocp11537/scc.yaml"
    Given the following scc policy is created: scc.yaml
    Then the step should succeed
    Given SCC "scc-ocp11537" is added to the "first" user
    # step 4. create the pod again and it should succeed now with the new scc rule
    Given I obtain test data file "pods/ocp11537/special_fs_groupid.json"
    When I run the :create client command with:
      | f | special_fs_groupid.json |
    Then the step should succeed
    And the pod named "hello-pod" status becomes :running
    When I run the :exec client command with:
      | pod          | hello-pod |
      | exec_command | id        |
    Then the step should succeed
    And the output should contain:
      | uid=1000         |
      | groups=1000,1001 |

  # @author pruan@redhat.com
  # @case_id OCP-12053
  @admin
  @destructive
  Scenario: Process with supplemental groups out of the default range when using custom defined MustRunAs as the RunAsGroupStrategy
    Given I have a project
    When I run the :get client command with:
      | resource      | project             |
      | resource_name | <%= project.name %> |
    Given scc policy "restricted" is restored after scenario
    Given as admin I replace resource "scc" named "restricted":
      | RunAsAny | MustRunAs |
    Given I obtain test data file "pods/ocp12053/pod.json"
    Then I run the :create client command with:
      | f | pod.json |
    Then the step should fail
    And the output should contain:
      | unable to validate against any security context constraint |
      | 1000 is not an allowed group                               |
    # step 3 create new scc rule as cluster admin and add user to the new scc
    Given I obtain test data file "pods/ocp12053/scc.yaml"
    Given the following scc policy is created: scc.yaml
    Then the step should succeed
    Given SCC "scc-ocp12053" is added to the "first" user
    # step 4. create the pod again and it should succeed now with the new scc rule
    Given I obtain test data file "pods/ocp12053/pod.json"
    When I run the :create client command with:
      | f | pod.json |
    Then the step should succeed
    And the pod named "hello-pod" status becomes :running
    When I run the :exec client command with:
      | pod          | hello-pod |
      | exec_command | id        |
    Then the step should succeed
    When I get project pods named "hello-pod"
    Then the expression should be true> pod.supplemental_groups(user:user)[0] == 1000

  # @author cryan@redhat.com
  # @case_id OCP-12240
  Scenario: Create resources with multiple approach via cli
    Given I have a project
    Given I obtain test data dir "cli/hello-openshift"
    When I run the :create client command with:
      | f | hello-openshift/ |
    Then the step should succeed
    When I run the :expose client command with:
      | resource      | pods            |
      | resource_name | hello-openshift |
    Then the step should succeed
    When I expose the "hello-openshift" service
    Then the step should succeed
    Given the pod named "hello-openshift" status becomes :running
    Given I wait up to 30 seconds for a web server to become available via the "hello-openshift" route
    Then the output should contain "Hello OpenShift!"
    When I run the :delete client command with:
      | f | hello-openshift/ |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type | routes |
      | all         | true   |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type | services |
      | all         | true     |
    Then the step should succeed
    Given I get project routes
    Then the output should not contain "hello-openshift"
    Given all existing pods die with labels:
      | name=hello-openshift |
    When I run the :create client command with:
      | f | hello-openshift/hello-pod.json |
    Then the step should succeed
    When I run the :expose client command with:
      | resource      | pods            |
      | resource_name | hello-openshift |
    Then the step should succeed
    When I expose the "hello-openshift" service
    Then the step should succeed
    Given the pod named "hello-openshift" status becomes :running
    And I wait up to 30 seconds for a web server to become available via the "hello-openshift" route
    Then the output should contain "Hello OpenShift!"
    When I run the :delete client command with:
      | f | hello-openshift/hello-pod.json |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type | routes |
      | all         | true   |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type | services |
      | all         | true     |
    Then the step should succeed
    Given I get project routes
    Then the output should not contain "hello-openshift"
    Given all existing pods die with labels:
      | name=hello-openshift |
    #The following step relies on _stdin, thus satisfying the TC req for stdin
    When I run oc create with "hello-openshift/hello-pod.json" replacing paths:
      | ["metadata"]["name"] | hello-openshift |
    Then the step should succeed
    Given the pod named "hello-openshift" status becomes :running
    When I run the :delete client command with:
      | f | hello-openshift/hello-pod.json |
    Then the step should succeed
    Given all existing pods die with labels:
      | name=hello-openshift |
    Given I create the "jenkins" directory
    And I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/jenkins-ephemeral-template.json" into the "jenkins" dir
    #Change template name to distinguish itself from the default jenkins template
    And I replace lines in "jenkins/jenkins-ephemeral-template.json":
      | "name": "jenkins-ephemeral" | "name": "jenkins-ephemeral-tc474044" |
    When I run the :create client command with:
      | f | hello-openshift/ |
      | f | jenkins/         |
    Then the step should succeed
    Given the pod named "hello-openshift" status becomes :running
    Given I get project templates
    Then the output should contain "jenkins-ephemeral-tc474044"

  # @author xiaocwan@redhat.com
  # @case_id OCP-10210
  Scenario: oc create quota with --dry-run and -o
    Given I have a project
    When I run the :create_quota client command with:
      | name     | myquota             |
      | hard     | pods=10             |
      | n        | <%= project.name %> |
      | dry-run  | true                |
    Then the step should succeed
    And the output should match:
      | resourcequota.*myquota.*created.*dry run |
    When I run the :create_quota client command with:
      | name     | myquota             |
      | hard     | pods=10             |
      | n        | <%= project.name %> |
      | output   | yaml                |
      | dry-run  | true                |
    Then the step should succeed
    And the output should match:
      | pods.*10 |
    When I run the :create_quota client command with:
      | name     | myquota             |
      | hard     | pods=10             |
      | n        | <%= project.name %> |
      | output   | name                |
      | dry-run  | true                |
    Then the step should succeed
    And the output should contain:
      | resourcequota/myquota |

  # @author yinzhou@redhat.com
  # @case_id OCP-11577
  Scenario: Fail to create pod for podSpec.volumes if not in the volumes of matched scc
    Given I have a project
    Given I obtain test data file "authorization/scc/pod_requests_hostdir.json"
    When I run the :create client command with:
      | f | pod_requests_hostdir.json |
    Then the step should fail
    And the output should contain:
      | hostPath volumes are not allowed |
    Given I obtain test data file "deployment/hello-pod.json"
    When I run the :create client command with:
      | f | hello-pod.json |
    Then the step should succeed


  # @author xipang@redhat.com
  Scenario Outline: Show better output for syntax error
    Given I have a project
    Given a "template.json" file is created with the following lines:
    """
    {broken:}
    """
    Given I obtain test data file "cli/OCP-11049/invalid.json"
    When I run the :create client command with:
      | _tool    | <tool>   |
      | f        | invalid.json |
    Then the step should fail
    And the output should match:
      | error:.*json:.*line.*[0-9]+:.*invalid character.* |
    When I run the :create client command with:
      | _tool    | <tool>        |
      | f        | template.json |
    Then the step should fail
    And the output should match:
      | error:.*json:.*line.*[0-9]+:.*invalid character.* |
    When I run the :process client command with:
      | f | template.json |
    Then the step should fail
    And the output should match:
      | error:.*json:.*line.*[0-9]+:.*invalid character.* |
    When I run the :replace client command with:
      | _tool    | <tool>        |
      | f        | template.json |
    Then the step should fail
    And the output should match:
      | error:.*json:.*line.*[0-9]+:.*invalid character.* |
    Given I obtain test data file "cli/OCP-11049/invalid.yaml"
    When I run the :create client command with:
      | _tool    | <tool>        |
      | f        | invalid.yaml |
    Then the step should fail
    #And the output should match:
    #  | error:.*yaml:.*line.*[0-9]+:.*invalid character.* |
    Examples:
      | tool     |
      | oc       | # @case_id OCP-11049
      | kubectl  | # @case_id OCP-21055

  # @author geliu@redhat.com
  # @case_id OCP-16295
  Scenario: 3.7 User can expose the environment variables to pods
    Given the master version >= "3.7"
    Given I have a project
    Given I obtain test data file "templates/ocp16295/pod.yaml"
    When I run the :create client command with:
      | f | pod.yaml |
    Then the step should succeed
    Given the pod named "kubernetes-metadata-volume-example" becomes ready
    When I execute on the pod:
      | ls | -laR | /data/podinfo-dir |
    Then the step should succeed
    And the output should contain:
      | annotations -> |
      | labels -> |
