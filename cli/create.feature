Feature: creating 'apps' with CLI

  # @author akostadi@redhat.com
  # @case_id OCP-10625
  @smoke
  Scenario: Create an application with overriding app name
    Given I have a project
    And I create a new application with:
      | image_stream | openshift/ruby:latest |
      | code         | https://github.com/openshift/ruby-hello-world |
      | name         | myapp                |
      # | namespace    | <%= project.name %>  |
    Then the step should succeed
    When I expose the "myapp" service
    Then the step should succeed
    And I wait for a web server to become available via the route
    And the project is deleted

    ## recreate project between each test because of
    #    https://bugzilla.redhat.com/show_bug.cgi?id=1233503
    ## create app with broken labels
    Given I have a project
    # test https://bugzilla.redhat.com/show_bug.cgi?id=1251601
    When I create a new application with:
      | docker image | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
      | name         | upperCase |
    Then the step should fail
    And the project is deleted

    # https://bugzilla.redhat.com/show_bug.cgi?id=1247680
    Given I have a project
    When I create a new application with:
      | image_stream | openshift/ruby~https://github.com/openshift/ruby-hello-world |
      | name         | <%= rand_str(59, :dns952) %> |
    Then the step should fail
    And the project is deleted

    Given I have a project
    When I create a new application with:
      | docker image      | centos/perl-524-centos7://github.com/sclorg/s2i-perl-container |
      | context dir       | 5.24/test/sample-test-app/                                     |
      | name              | 4igit-first                                                    |
      | insecure_registry | true                                                           |
    Then the step should fail
    And the project is deleted

    Given I have a project
    When I create a new application with:
      | docker image | centos/ruby-25-centos7~https://github.com/openshift/ruby-hello-world |
      | name         | with#chara                                                           |
    Then the step should fail
    And the project is deleted

    Given I have a project
    When I create a new application with:
      | image_stream | openshift/perl:5.26~https://github.com/sclorg/s2i-perl-container |
      | context dir  | 5.26/test/sample-test-app/            |
      | name         | with^char |
    Then the step should fail
    And the project is deleted

    Given I have a project
    When I create a new application with:
      | image_stream | openshift/ruby~https://github.com/openshift/ruby-hello-world |
      | name         | with@char |
    Then the step should fail
    And the project is deleted

  # @author xxing@redhat.com
  # @case_id OCP-11880
  Scenario: Create application from template via cli
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/build/ruby20rhel7-template-sti.json |
    And I create a new application with:
      | template | ruby-helloworld-sample   |
      | param    | MYSQL_USER=admin         |
      | param    | MYSQL_PASSWORD=admin     |
      | param    | MYSQL_DATABASE=xxingtest |
    Then the step should succeed
    When I expose the "frontend" service
    Then I wait for a web server to become available via the "frontend" route
    And the output should contain "Demo App"
    Given I wait for the "database" service to become ready up to 300 seconds
    And I get the service pods
    When I execute on the pod:
      | bash |
      | -c   |
      | mysql -h <%= service.ip %> -P5434 -uadmin -padmin -e 'show databases;'|
    Then the step should succeed
    And the output should contain "xxingtest"

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
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json |
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

  # @author cryan@redhat.com
  # @case_id OCP-11890
  Scenario: Easy delete resources of 'new-app' created
    Given I have a project
    Given a 5 characters random string of type :dns is stored into the :rand_label clipboard
    When I run the :new_app client command with:
      | code | https://github.com/sclorg/s2i-perl-container |
      | l | app=<%= cb.rand_label %> |
      | context_dir | 5.20/test/sample-test-app/ |
    Then the step should succeed
    And the "s2i-perl-container-1" build completed
    When I run the :delete client command with:
      | all_no_dash ||
      | l | app=<%= cb.rand_label %> |
    Then the step should succeed
    When I run the :get client command with:
      | resource | all |
    Then the project should be empty
    Given a 5 characters random string of type :dns is stored into the :rand_label2 clipboard
    Given a 5 characters random string of type :dns is stored into the :rand_label3 clipboard
    Given a 5 characters random string of type :dns is stored into the :rand_label4 clipboard
    When I run the :new_app client command with:
      | code | https://github.com/sclorg/s2i-perl-container |
      | l | app2=<%= cb.rand_label2 %>,app3=<%= cb.rand_label3 %>,app4=<%= cb.rand_label4 %> |
      | context_dir | 5.20/test/sample-test-app/ |
    Then the step should succeed
    And the "s2i-perl-container-1" build completed
    When I run the :get client command with:
      | resource | all |
      | l | app2=<%= cb.rand_label2 %> |
    Then the step should succeed
    And the output should contain "s2i-perl-container"
    When I run the :delete client command with:
      | all_no_dash ||
      | l | app2=<%= cb.rand_label2 %> |
    Then the step should succeed
    When I run the :get client command with:
      | resource | all |
    Then the project should be empty


  # @author chunchen@redhat.com
  # @case_id OCP-11118
  Scenario: Create an application from images
    Given I have a project
    When I create a new application with:
      | image_stream | openshift/python:3.6                        |
      | image_stream | openshift/mysql:latest                      |
      | code         | git://github.com/sclorg/s2i-python-container|
      | context_dir  | 3.6/test/standalone-test-app                |
      | group        | openshift/python:3.6+openshift/mysql:latest |
      | env          | MYSQL_USER=test                             |
      | env          | MYSQL_PASSWORD=test                         |
      | env          | MYSQL_DATABASE=ccytest                      |
      | name         | sti-python                                  |
    Then the step should succeed
    And the "sti-python-1" build completed
    And a pod becomes ready with labels:
      | deployment=sti-python-1      |
      | deploymentconfig=sti-python  |
    And I wait for the "sti-python" service to become ready up to 300 seconds
    And I get the service pods
    And I wait for the steps to pass:
    """
    When I run the :exec client command with:
      | pod              | <%= pod.name %>                       |
      | c                | sti-python-1                          |
      | oc_opts_end      |                                       |
      | exec_command     | /opt/rh/rh-mysql56/root/usr/bin/mysql |
      | exec_command_arg | -h<%= service.ip %>                   |
      | exec_command_arg | -utest                                |
      | exec_command_arg | -ptest                                |
      | exec_command_arg | -estatus                              |
    Then the step should succeed
    And the output should match "Uptime:\s+(\d+\s+min\s+)?\d+\s+sec"
    """

    When I create a new application with:
      | image_stream | openshift/python:3.4                         |
      | code         | git://github.com/sclorg/s2i-python-container |
      | context_dir  | 3.4/test/standalone-test-app                 |
      | name         | sti-python1                                  |
    Then the step should succeed
    And the "sti-python1-1" build completed
    When I create a new application with:
      | docker_image | openshift/python-34-centos7                  |
      | code         | git://github.com/sclorg/s2i-python-container |
      | context_dir  | 3.4/test/standalone-test-app                 |
      | name         | sti-python2                                  |
    Then the step should succeed
    And the "sti-python2-1" build completed
    Given I wait for the "sti-python2" service to become ready up to 300 seconds
    And I get the service pods
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      | curl | -sS | <%= service.url %> |
    Then the step should succeed
    """
    Given the project is deleted
    And I have a project
    When I create a new application with:
      | docker_image | openshift/python-34-centos7                            |
      | docker_image | openshift/mysql-55-centos7                             |
      | code         | git://github.com/sclorg/s2i-python-container           |
      | context_dir  | 3.4/test/standalone-test-app                           |
      | group        | openshift/python-34-centos7+openshift/mysql-55-centos7 |
      | env          | MYSQL_ROOT_PASSWORD=test                               |
      | name         | sti-python                                             |
    Then the step should succeed
    And the "sti-python-1" build completed
    And a pod becomes ready with labels:
      | deployment=sti-python-1      |
      | deploymentconfig=sti-python  |
    And I wait for the "sti-python" service to become ready up to 300 seconds
    And I get the service pods
    And I wait for the steps to pass:
    """
    When I run the :exec client command with:
      | pod              | <%= pod.name %>                    |
      | c                | sti-python-1                       |
      | oc_opts_end      |                                    |
      | exec_command     | /opt/rh/mysql55/root/usr/bin/mysql |
      | exec_command_arg | -h<%= service.ip %>                |
      | exec_command_arg | -uroot                             |
      | exec_command_arg | -ptest                             |
      | exec_command_arg | -estatus                           |
    Then the step should succeed
    And the output should match "Uptime:\s+(\d+\s+min\s+)?\d+\s+sec"
    """

  # @author pruan@redhat.com
  # @case_id OCP-11097
  Scenario: Create resources with labels --Negative test
    Given I have a project
    And I run the :new_app client command with:
      | docker_image | centos/ruby-25-centos7 |
      | labels | name#@=ruby-hello-world |
      | insecure_registry | true |
    Then the step should fail
    And the output should contain:
      | metadata.labels|
      | Invalid value|
      | name#@ |
    And I run the :new_app client command with:
      | docker_image | centos/ruby-25-centos7 |
      | labels | name=@#@ |
      | insecure_registry | true |
    Then the step should fail
    And the output should contain:
      | metadata.labels|
      | Invalid value|
      | @#@ |
    And I run the :new_app client command with:
      | docker_image | centos/ruby-25-centos7 |
      | labels | name=value1,name=value2,name=deadbeef010203 |
      | insecure_registry | true |
    Then the step should succeed
    When I run the :get client command with:
      | resource | all |
      | l | name=deadbeef010203 |
    Then the step should succeed
    And the output should contain:
      | ruby-25-centos7 |

  # @author xiaocwan@redhat.com
  # @case_id OCP-11758
  Scenario: [platformmanagement_public_523]Use the old version v1beta3 file to create resource
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/pod-with-v1beta3.json |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    When I get project pod named "hello-pod" as YAML
    Then the expression should be true> @result[:parsed]['apiVersion'] == 'v1'

  # @author yinzhou@redhat.com
  # @case_id OCP-12148
  Scenario: Progress with invalid supplemental groups should not be run when using RunAsAny as the RunAsGroupStrategy
    Given I have a project
    When I run the :create client command with:
      | f       | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/pod_with_special_supplementalGroups.json |
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

  # @author cryan@redhat.com
  # @case_id OCP-12379
  Scenario: User can expose the environment variables to pods
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/tc467937/pod467937.yaml |
    Then the step should succeed
    Given the pod named "kubernetes-metadata-volume-example" becomes ready
    When I execute on the pod:
      | ls | -laR | /etc |
    Then the step should succeed
    And the output should contain:
      | annotations -> |
      | labels -> |

  # @author cryan@redhat.com
  # @case_id OCP-11707
  Scenario: update multiple existing resources with file
    Given I have a project
    When I obtain test data file "build/tc470422/application-template-stibuild.json"
    Given I replace lines in "application-template-stibuild.json":
      | "name": "ruby-22-centos7:latest" | "name": "ruby:latest", "namespace": "openshift" |
    When I run the :new_app client command with:
      | file | application-template-stibuild.json |
    Then the step should succeed
    Given the "ruby-sample-build-1" build completes
    Given 1 pods become ready with labels:
      | deployment=frontend-1 |
    #Change pod labels
    When I run the :patch client command with:
      | resource | pod |
      | resource_name | <%= pod.name %> |
      | p | {"metadata": {"labels": {"name":"changed"}}} |
    Then the step should succeed
    #Change buildconfig uri
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | ruby-sample-build |
      | p | {"spec": {"source": {"git": {"uri": "https://github.com/openshift/origin"}}}} |
    Then the step should succeed
    #Change service labels
    Given I replace resource "services" named "frontend" saving edit to "serviceschange.json":
      | app: ruby-helloworld-sample | app: change |
    When I get project pod named "<%= pod.name %>" as JSON
    Then the step should succeed
    Given I save the output to file> podschange.json
    When I get project build_config as JSON
    Then the step should succeed
    Given I save the output to file> buildconfigschange.json
    #Services are missing here, because they were replaced in the
    #substitution above
    When I run the :replace client command with:
      | f | podschange.json |
      | f | buildconfigschange.json |
    Then the step should succeed
    #Verify changes, and at the same time save the output to a directory
    #and make new changes simultaneously.
    Given I create the "change" directory
    When I get project services as JSON
    Then the output should contain:
      | "app": "change" |
    Given I save the output to file> change/services.json
    Given I replace lines in "change/services.json":
      | "app": "change" | "app": "change2" |
    When I get project pod named "<%= pod.name %>" as JSON
    Then the output should contain:
      | "name": "changed" |
    Given I save the output to file> change/pods.json
    Given I replace lines in "change/pods.json":
      | "name": "changed" | "name": "changed2" |
    When I get project build_config as JSON
    Then the output should contain:
      | "uri": "https://github.com/openshift/origin" |
    Given I save the output to file> change/buildconfig.json
    Given I replace lines in "change/buildconfig.json":
      | "uri": "https://github.com/openshift/origin" | "uri": "https://github.com/sclorg/rails-ex" |
    When I run the :replace client command with:
      | f | change/ |
    Then the step should succeed
    When I get project services as JSON
    Then the output should contain:
      | "app": "change2" |
    When I get project pod named "<%= pod.name %>" as JSON
    Then the output should contain:
      | "name": "changed2" |
    When I get project build_config as JSON
    Then the output should contain:
      | "uri": "https://github.com/sclorg/rails-ex" |
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given the "ruby-sample-build-2" build completes

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
    When I run oc create over ERB URL: <%= BushSlicer::HOME %>/features/tierN/testdata/pods/510541/scc_rules.json
    Then the step should succeed
    When the pod named "hello-pod" status becomes :running

    Given I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/hello-pod.json |
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
    When I obtain test data file "pods/tc510543/special_fs_groupid.json"
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
    Given the following scc policy is created: <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tc510543/scc_tc510543.yaml
    Then the step should succeed
    Given SCC "scc-tc510543" is added to the "first" user
    # step 4. create the pod again and it should succeed now with the new scc rule
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tc510543/special_fs_groupid.json |
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
    Then I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tc510546/tc510546_pod.json |
    Then the step should fail
    And the output should contain:
      | unable to validate against any security context constraint |
      | 1000 is not an allowed group                               |
    # step 3 create new scc rule as cluster admin and add user to the new scc
    Given the following scc policy is created: <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tc510546/scc_tc510546.yaml
    Then the step should succeed
    Given SCC "scc-tc510546" is added to the "first" user
    # step 4. create the pod again and it should succeed now with the new scc rule
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tc510546/tc510546_pod.json |
    Then the step should succeed
    And the pod named "hello-pod" status becomes :running
    When I run the :exec client command with:
      | pod          | hello-pod |
      | exec_command | id        |
    Then the step should succeed
    When I get project pods named "hello-pod"
    Then the expression should be true> pod.supplemental_groups(user:user)[0] == 1000

  # @author mcurlej@redhat.com
  # @case_id OCP-12260
  @smoke
  Scenario: Create and update the docker images tag from remote repositories via api
    Given I have a project
    When I run oc create over ERB URL: <%= BushSlicer::HOME %>/features/tierN/testdata/cli/tc519471/image-stream-tag.json
    Then the step should succeed
    # Add wait step to avoid the async delay
    And I wait for the steps to pass:
    """
    I get project istag
    the step should succeed
    the output should contain:
      |<%= product_docker_repo %>rhel7.2|
    """
    When I run oc create over ERB URL: <%= BushSlicer::HOME %>/features/tierN/testdata/cli/tc519471/image-stream-tag-update.json
    Then the step should succeed
    And I wait for the steps to pass:
    """
    I get project istag
    the step should succeed
    the output should contain:
      | registry.access.redhat.com/rhel7.1 |
      | registry.access.redhat.com/rhel7.2 |
    """

  # @author cryan@redhat.com
  # @case_id OCP-12240
  Scenario: Create resources with multiple approach via cli
    Given I have a project
    And I create the "hello-openshift" directory
    And I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json" into the "hello-openshift" dir
    And I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/Dockerfile" into the "hello-openshift" dir
    And I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello_openshift.go" into the "hello-openshift" dir
    And I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/README.md" into the "hello-openshift" dir
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
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
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

  # @author wmeng@redhat.com
  # @case_id OCP-11870
  Scenario: Opaque integer resources limits less than requests
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/opaque_integer_resources/pod_invailid5.yaml |
    Then the step should fail
    And the output should match:
      | .*requests.*must be less than or equal to.*limit\|.*limits.*must be greater than or equal to.*request |

  # @author wmeng@redhat.com
  # @case_id OCP-12014
  Scenario: Opaque integer resources requests invalid value
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/opaque_integer_resources/pod_invailid_requests1.yaml |
    Then the step should fail
    And the output should contain:
      | must be an integer |
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/opaque_integer_resources/pod_invailid_requests2.yaml |
    Then the step should fail
    And the output should contain:
      | must be greater than or equal to 0 |

  # @author wmeng@redhat.com
  # @case_id OCP-11688
  Scenario: Opaque integer resources limits invalid value
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/opaque_integer_resources/pod_invailid_limits3.yaml |
    Then the step should fail
    And the output should contain:
      | must be an integer |
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/scheduler/opaque_integer_resources/pod_invailid_limits4.yaml |
    Then the step should fail
    And the output should contain:
      | must be greater than or equal to 0 |


  # @author yinzhou@redhat.com
  # @case_id OCP-11577
  Scenario: Fail to create pod for podSpec.volumes if not in the volumes of matched scc
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/authorization/scc/pod_requests_hostdir.json |
    Then the step should fail
    And the output should contain:
      | hostPath volumes are not allowed |
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/tc472859/hello-pod.json |
    Then the step should succeed


  # @author xipang@redhat.com
  Scenario Outline: Show better output for syntax error
    Given I have a project
    Given a "template.json" file is created with the following lines:
    """
    {broken:}
    """
    When I run the :create client command with:
      | _tool    | <tool>   |
      | f        | <%= BushSlicer::HOME %>/features/tierN/testdata/cli/OCP-11049/invalid.json |
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
    When I run the :create client command with:
      | _tool    | <tool>        |
      | f        | <%= BushSlicer::HOME %>/features/tierN/testdata/cli/OCP-11049/invalid.yaml |
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
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/tc467937/pod467937-new.yaml |
    Then the step should succeed
    Given the pod named "kubernetes-metadata-volume-example" becomes ready
    When I execute on the pod:
      | ls | -laR | /data/podinfo-dir |
    Then the step should succeed
    And the output should contain:
      | annotations -> |
      | labels -> |

