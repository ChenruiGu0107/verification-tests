Feature: stibuild.feature
  # @author xiuwang@redhat.com
  # @case_id OCP-14128
  Scenario: Start build with PR ref for an app using dockerstrategy
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://github.com/openshift/ruby-hello-world#refs/pull/60/head |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completed
    And a pod becomes ready with labels:
      | deploymentconfig=ruby-hello-world |
    When I expose the "ruby-hello-world" service
    Then I wait for a web server to become available via the "ruby-hello-world" route
    And  the output should contain "Welcome to an OpenShift v3 Demo App! - QE Test"

  # @author xiuwang@redhat.com
  # @case_id OCP-14093
  Scenario: Start build with PR ref for an app using sourcestrategy
    Given I have a project
    When I run the :new_app client command with:
      | app_repo     | https://github.com/openshift/ruby-hello-world#refs/pull/73/head |
      | image_stream | ruby:latest                                                     |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completed
    And a pod becomes ready with labels:
      | deploymentconfig=ruby-hello-world |
    When I expose the "ruby-hello-world" service
    Then I wait for a web server to become available via the "ruby-hello-world" route
    And  the output should contain "Hello from OpenShift v3!!! CUSTOM DEMORRRR"
    When I run the :patch client command with:
      | resource      | buildconfig                                        |
      | resource_name | ruby-hello-world                                   |
      | p | {"spec":{"source":{"git":{"ref":"refs/pull/73/head:master"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    And the "ruby-hello-world-2" build was created
    And the "ruby-hello-world-2" build failed
    When I run the :patch client command with:
      | resource      | buildconfig                                     |
      | resource_name | ruby-hello-world                                |
      | p | {"spec":{"source":{"git":{"ref":"refs/pull/100000/head"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    And the "ruby-hello-world-3" build was created
    And the "ruby-hello-world-3" build failed
    When I run the :get client command with:
      | resource | build |
    Then the output should match:
      | ruby-hello-world-2.*Git@refs/pull/73/head:master.*FetchSourceFailed |
      | ruby-hello-world-3.*Git@refs/pull/100000/head.*FetchSourceFailed    |

  # @author wewang@redhat.com
  # @case_id OCP-15481
  Scenario: Setting incremental with wrong info on s2i build request
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | openshift/ruby~https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
      | incremental | abc              |
    Then the step should fail
    Then the output should contain:
      | Error: invalid argument "abc"  |

  # @author wewang@redhat.com
  # @case_id OCP-15970
  Scenario: Create an application using template with route defined	
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    Then the output should contain:
      | Access your application via route 'www.example.com' |

  # @author wewang@redhat.com
  # @case_id OCP-15974
  Scenario: Create an application with no host value in template
    Given I have a project
    Given I obtain test data file "templates/application-template-stibuild.json"
    When I run the :new_app client command with:
      | file | application-template-stibuild.json |
    Then the step should succeed
    And the output should match:
      | Access your application via route 'route-edge[-a-zA-Z0-9_.]+' |

  # @author wewang@redhat.com
  # @case_id OCP-15506
  Scenario: Create a build configuration based on a private remote git repository
    Given I have a project
    And I have an ssh-git service in the project
    And the "secret" file is created with the following lines:
      | <%= cb.ssh_private_key.to_pem %> |
    And I run the :create_secret client command with:
      | secret_type | generic               |
      | name        | mysecret              |
      | from_file   | ssh-privatekey=secret |
    Then the step should succeed
    When I execute on the pod:
      | bash |
      | -c   |
      | cd /repos/ && rm -rf sample.git && git clone --bare https://github.com/openshift/ruby-hello-world sample.git |
    Then the step should succeed
    When I run the :new_build client command with:
      | app_repo      | openshift/ruby:2.5~https://github.com/openshift/ruby-hello-world |
      | source_secret | mysecret |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completed
    Then I run the :delete client command with:
      | object_type       | buildConfig      |
      | object_name_or_id | ruby-hello-world |
    Then the step should succeed
    When I run the :new_build client command with:
      | app_repo      | https://github.com/openshift/ruby-hello-world |
      | source_secret | nonsecret                                     |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    Then the "ruby-hello-world-1" build becomes :pending
    Given 60 seconds have passed
    Given I get project builds
    Then the output should contain "Pending"
    Then I run the :delete client command with:
      | object_type       | buildConfig      |
      | object_name_or_id | ruby-hello-world |
    Then the step should succeed
    When I run the :new_build client command with:
      | app_repo     | openshift/ruby:2.5~<%= cb.git_repo %> |
      | source_secret| mysecret                              |
    Then the step should succeed
    And the "sample-1" build was created
    And the "sample-1" build completed

  # @author wewang@redhat.com
  # @case_id OCP-15507
  Scenario: Creates a new application based on the source code in a private remote repository
    Given I have a project
    And I have an ssh-git service in the project
    And the "secret" file is created with the following lines:
      | <%= cb.ssh_private_key.to_pem %> |
    And I run the :create_secret client command with:
      | secret_type | generic               |
      | name        | mysecret              |
      | from_file   | ssh-privatekey=secret |
    Then the step should succeed
    When I execute on the pod:
      | bash |
      | -c   |
      | cd /repos/ && rm -rf sample.git && git clone --bare https://github.com/openshift/ruby-hello-world sample.git |
    Then the step should succeed
    When I run the :new_app_as_dc client command with:
      | app_repo      | openshift/ruby:2.5~https://github.com/openshift/ruby-hello-world |
      | source_secret | mysecret |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completed
    Then I run the :delete client command with:
      | object_type       | buildConfig      |
      | object_name_or_id | ruby-hello-world |
    Then the step should succeed
    Then I run the :delete client command with:
      | object_type       | deploymentConfig |
      | object_name_or_id | ruby-hello-world |
    Then the step should succeed
    Then I run the :delete client command with:
      | object_type       | service          |
      | object_name_or_id | ruby-hello-world |
    Then the step should succeed
    When I run the :new_app_as_dc client command with:
      | app_repo      | openshift/ruby:2.5~https://github.com/openshift/ruby-hello-world |
      | source_secret | nonsecret |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    Then the "ruby-hello-world-1" build becomes :pending
    Given 60 seconds have passed
    Given I get project builds
    Then the output should contain "Pending"
    When I run the :delete client command with:
      | object_type       | buildConfig      |
      | object_name_or_id | ruby-hello-world |
    Then the step should succeed
    When I run the :new_app client command with:
      | app_repo     | openshift/ruby:2.5~<%= cb.git_repo %> |
      | source_secret| mysecret                              |
    Then the step should succeed
    And the "sample-1" build was created
    And the "sample-1" build completed

  # @author wewang@redhat.com
  # @case_id OCP-23174
  Scenario: Image source extraction w/ symlink should success when running a build	
    Given I have a project
    Given I obtain test data file "build/OCP-23174/symlink-rel-both.yaml"
    When I run the :create client command with:
      | f | symlink-rel-both.yaml |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | symlink-rel-both |
    Then the step should succeed
    And the "symlink-rel-both-1" build completed
    Given I obtain test data file "build/OCP-23174/symlink-rel-link.yaml"
    When I run the :create client command with:
      | f | symlink-rel-link.yaml |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | symlink-rel-link |
    Then the step should succeed
    And the "symlink-rel-link-1" build failed
    Given I obtain test data file "build/OCP-23174/symlink-abs-both.yaml"
    When I run the :create client command with:
      | f | symlink-abs-both.yaml |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | symlink-abs-both |
    Then the step should succeed
    And the "symlink-abs-both-1" build failed
    Given I obtain test data file "build/OCP-23174/symlink-abs-link.yaml"
    When I run the :create client command with:
      | f | symlink-abs-link.yaml |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | symlink-abs-link |
    Then the step should succeed
    And the "symlink-abs-link-1" build failed
    Given I obtain test data file "build/OCP-23174/symlink-rel-single.yaml"
    When I run the :create client command with:
      | f | symlink-rel-single.yaml |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | symlink-rel-single |
    Then the step should succeed
    And the "symlink-rel-single-1" build completed

  # @author wewang@redhat.com
  # @case_id OCP-20973
  @admin
  Scenario: No panic in the build controller after delete build pod when build in complete phase
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    And the "ruby-hello-world-1" build completed
    When I get project builds named "ruby-hello-world-1" as YAML
    And I save the response to file> build_output.yaml
    When I delete matching lines from "build_output.yaml":
      | completionTimestamp: |
    Then the step should succeed
    When I run the :apply client command with:
      | f | build_output.yaml |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | pod                      |
      | object_name_or_id | ruby-hello-world-1-build |
    Then the step should succeed
    When I get project builds named "ruby-hello-world-1" as YAML
    And I save the response to file> build_output.yaml
    When I delete matching lines from "build_output.yaml":
      | completionTimestamp: |
    Then the step should succeed
    When I run the :apply client command with:
      | f | build_output.yaml |
    Then the step should succeed
    When I get project builds named "ruby-hello-world-1" as YAML
    Then the output should contain "completionTimestamp:"
    Given I switch to cluster admin pseudo user
    When I use the "openshift-controller-manager" project
    Then I store in the :pods clipboard the pods labeled:
      | app=openshift-controller-manager |
    And I repeat the following steps for each :pod in cb.pods:
    """
    And I run the :logs client command with:
      | resource_name | #{cb.pod.name} |
    Then the step should succeed
    """
    And the output should not contain:
      | invalid memory address  |
      | nil pointer dereference |

  # @author wewang@redhat.com
  # @case_id OCP-23414
  @admin
  Scenario: Build should succeed with no error logs and delay	
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/sclorg/nginx-ex/master/openshift/templates/nginx.json |
      | p        | NGINX_VERSION=latest |
    Then the step should succeed
    And the "nginx-example-1" build completed
    Given I switch to cluster admin pseudo user
    When I use the "openshift-controller-manager" project
    Then I store in the :pods clipboard the pods labeled:
      | app=openshift-controller-manager |
    And I repeat the following steps for each :pod in cb.pods:
    """
    And I run the :logs client command with:
      | resource_name | #{cb.pod.name} |
      | loglevel      | 5              |
    Then the step should succeed
    """
    Then the output should not contain "invalid phase transition"

  # @case_id OCP-17650
  @admin
  Scenario: Create an application using -i and code
    Given scc policy "restricted" is restored after scenario
    When I have a project
    Then I run the :new_app client command with:
      | app_repo | openshift/ruby~https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    And the "ruby-hello-world-1" build completed
    When I run the :delete client command with:
      | all_no_dash ||
      | all         ||
    Then the step should succeed
    When I run the :new_app client command with:
      | image_stream | openshift/ruby                                    |
      | app_repo     | https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    And the "ruby-hello-world-1" build completed
    When I run the :delete client command with:
      | all_no_dash ||
      | all         ||
    Then the step should succeed
    When I run the :new_app client command with:
      | image_stream | openshift/ruby                                    |
      | code         | https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    And the "ruby-hello-world-1" build completed
    When I run the :delete client command with:
      | all_no_dash ||
      | all         ||
    Then the step should succeed
    When I git clone the repo "https://github.com/openshift/ruby-hello-world.git"
    Then I run the :new_app client command with:
      | image_stream | openshift/ruby     |
      | app_repo     | ./ruby-hello-world |
    And the step should succeed
    And the "ruby-hello-world-1" build completed
    And as admin I replace resource "scc" named "restricted":
      | MustRunAsRange | RunAsAny |
    When I run the :policy_add_role_to_user client command with:
      | role           | edit    |
      | serviceaccount | default |
    Then the step should succeed
    When I run the :run client command with:
      | name    | nogit                                      |
      | image   | <%= project_docker_repo %>openshift/origin |
      | env     | POD_NAMESPACE=<%= project.name %>          |
      | command | true                                       |
      | cmd     | sleep                                      |
      | cmd     | 3600                                       |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | run=nogit |
    Given I execute on the pod:
      | oc | new-app | --image-stream=openshift/ruby | --code=https://github.com/openshift/ruby-hello-world |
    Then the step should fail
    And the output should contain "Cannot find git"
    Given I execute on the pod:
      | oc | new-app | --code=https://github.com/openshift/ruby-hello-world |
    Then the step should fail
    And the output should contain "Cannot find git"
    Given I execute on the pod:
      | bash                                                                                                                              |
      | -c                                                                                                                                |
      | cd /tmp; wget --no-check-certificate https://github.com/openshift/ruby-hello-world/archive/master.tar.gz; tar -xvzf master.tar.gz |
    Then the step should succeed
    Given I execute on the pod:
      | oc | new-app | --code=/tmp/ruby-hello-world-master | --name=test-no-git |
    Then the step should succeed

  # @author wewang@redhat.com
  # @case_id OCP-18926
  Scenario: Setting Paused boolean in buildconfig when images are changed	
    Given I have a project
    Given I obtain test data file "build/OCP-18926/paused-build.json"
    When I run the :new_app client command with:
      | app_repo | paused-build.json |
      | name     | paused-build |
    Then the step should succeed
    And the "paused-build-1" build completed
    When I run the :tag client command with:
      | source       | registry.access.redhat.com/rhscl/ruby-25-rhel7 |
      | dest         | ruby-25-centos7:latest                         |
    Then the step should succeed
    And the "paused-build-2" build completed
    When I run the :patch client command with:
      | resource      | bc           |
      | resource_name | paused-build |
      | p             | '{"spec":{"triggers":[{"imageChange":{"from":{"kind":"ImageStreamTag","name":"ruby-25-centos7:latest"},"paused":abc},"type":"ImageChange"}]}}' |
    Then the step should fail
    When I run the :patch client command with:
      | resource      | bc           |
      | resource_name | paused-build |
      | p             | '{"spec":{"triggers":[{"imageChange":{"from":{"kind":"ImageStreamTag","name":"ruby-25-centos7:latest"},"abcott. habcat. fiabci. ruvabc. rvoabc. nabcep. rpnabc. spoabc.":true},"type":"ImageChange"}]}}' |
    When I get project buildconfig as YAML
    And the output should not contain:
      | abcott. habcat. fiabci. ruvabc. rvoabc. nabcep. rpnabc. spoabc. |
    When I run the :patch client command with:
      | resource      | bc           |
      | resource_name | paused-build |
      | p             | {"spec":{"triggers":[{"imageChange":{"from":{"kind":"ImageStreamTag","name":"ruby-25-centos7:latest"},"paused":true},"type":"ImageChange"}]}} |
    Then the step should succeed
    When I get project buildconfig as YAML
    And the output should contain:
      |  paused: true |
    When I run the :tag client command with:
      | source       | centos/ruby-25-centos7  |
      | dest         | ruby-25-centos7:latest  |
    Then the step should succeed
    When I run the :get client command with:
      | resource | builds |
    Then the step should succeed
    And the output should not contain:
      | paused-build-3 |

  # @author wewang@redhat.com
  # @case_id OCP-30253
  Scenario: Builds should be configured to use mirrors in disconnected environments
    Given the master version >= "4.5"
    When I have a project
    Then I run the :new_build client command with:
      | D    | FROM quay.io/openshifttest/ruby-25-centos7@sha256:575194aa8be12ea066fc3f4aa9103dcb4291d43f9ee32e4afe34e0063051610b |
      | name | disconnect-build |
    And the step should succeed
    And the "disconnect-build-1" build was created
    And the "disconnect-build-1" build completed

  # @author wewang@redhat.com
  # @case_id OCP-30239
  Scenario: use an image from registry.redhat.io as source during a build	
  When I have a project
    Given I obtain test data file "build/OCP-30239/bc_imagesource.yaml"
  Then I run the :create client command with:
    | f | bc_imagesource.yaml |
  And the step should succeed
  When I run the :start_build client command with:
    | buildconfig | imagesourcebuildconfig |
  Then the step should succeed
  And the "imagesourcebuildconfig-1" build completed

  # @author wewang@redhat.com
  # @case_id OCP-30238
  Scenario: Add invalid pull secret in buildconfig and start-build
  When I have a project
  Then I run the :new_build client command with:
    | app_repo | openshift/ruby:2.5~https://github.com/openshift/ruby-hello-world |
  Then the step should succeed
  And the "ruby-hello-world-1" build completed
    Given I obtain test data file "build/OCP-30238/invaildsecret.json"
  When I run the :create_secret client command with:
    | name        | invalid-secret |
    | secret_type | generic        |
    | from_file   | .dockercfgjson=invaildsecret.json |
    | type        | kubernetes.io/dockercfgjson                                                                       |
  Then the step should succeed 
  When I run the :set_build_secret client command with:
    | bc_name     | ruby-hello-world |
    | secret_name | invalid-secret   |
    | pull        | true             |
  Then the step should succeed
  And I run the :start_build client command with:
    | buildconfig | ruby-hello-world |
  And the step should succeed
  And the "ruby-hello-world-2" build failed

  # @author xiuwang@redhat.com
  # @case_id OCP-31251
  Scenario: Start build with PR ref for an app using dockerstrategy test
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://github.com/openshift/ruby-hello-world#refs/pull/60/head |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completed
    And a pod becomes ready with labels:
      | deployment=ruby-hello-world |
    When I expose the "ruby-hello-world" service
    Then I wait for a web server to become available via the "ruby-hello-world" route
    And  the output should contain "Welcome to an OpenShift v3 Demo App! - QE Test"

  # @author xiuwang@redhat.com
  # @case_id OCP-31253
  Scenario: Start build with PR ref for an app using sourcestrategy test
    Given I have a project
    When I run the :new_app client command with:
      | app_repo     | https://github.com/openshift/ruby-hello-world#refs/pull/73/head |
      | image_stream | ruby:latest                                                     |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completed
    And a pod becomes ready with labels:
      | deployment=ruby-hello-world |
    When I expose the "ruby-hello-world" service
    Then I wait for a web server to become available via the "ruby-hello-world" route
    And  the output should contain "Hello from OpenShift v3!!! CUSTOM DEMORRRR"
    When I run the :patch client command with:
      | resource      | buildconfig                                        |
      | resource_name | ruby-hello-world                                   |
      | p | {"spec":{"source":{"git":{"ref":"refs/pull/73/head:master"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    And the "ruby-hello-world-2" build was created
    And the "ruby-hello-world-2" build failed
    When I run the :patch client command with:
      | resource      | buildconfig                                     |
      | resource_name | ruby-hello-world                                |
      | p | {"spec":{"source":{"git":{"ref":"refs/pull/100000/head"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    And the "ruby-hello-world-3" build was created
    And the "ruby-hello-world-3" build failed
    When I run the :get client command with:
      | resource | build |
    Then the output should match:
      | ruby-hello-world-2.*Git@refs/pull/73/head:master.*FetchSourceFailed |
      | ruby-hello-world-3.*Git@refs/pull/100000/head.*FetchSourceFailed    |

  # @author wewang@redhat.com
  # @case_id OCP-30237
  @admin
  Scenario: Build pod always mounts pull secrets that are available on the node
    Given I have a project
    When I run the :new_app client command with:
      | app_repo     | https://github.com/openshift/ruby-hello-world |
      | image_stream | openshift/ruby:latest                         |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completed
    When I get project pod named "ruby-hello-world-1-build" as YAML
    And the expression should be true> @result[:parsed]['spec']['volumes'].any? {|p| p['name'] == "node-pullsecrets"} && @result[:parsed]['spec']['volumes'].any? {|p| p['hostPath']['path'] == "/var/lib/kubelet/config.json"}
    When I run the :debug admin command with:
      | resource         | pod/ruby-hello-world-1-build |
      | oc_opts_end      |                              |
      | exec_command     | cat                          | 
      | exec_command_arg | /var/lib/kubelet/config.json |
      | n                | <%= project.name %>          |
    Then the step should succeed
    And the output should contain:
      | registry.redhat.io |

  # @author wewang@redhat.com
  # @case_id OCP-30236
  @admin
  Scenario: Create build using node credentials to pull image
    Given I have a project
    When I run the :tag client command with:
      | source | registry.redhat.io/rhscl/ruby-25-rhel7:latest |
      | dest   | <%= project.name %>/ruby:latest               |
    Then the step should succeed
    Given the "ruby" image stream was created
    When I run the :new_app client command with:
      | app_repo     | https://github.com/openshift/ruby-hello-world |
      | image_stream | <%= project.name %>/ruby:latest               |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completed
    When I get project pod named "ruby-hello-world-1-build" as YAML
    And the expression should be true> @result[:parsed]['spec']['volumes'].any? {|p| p['name'] == "node-pullsecrets"} && @result[:parsed]['spec']['volumes'].any? {|p| p['hostPath']['path'] == "/var/lib/kubelet/config.json"}
    When I run the :debug admin command with:
      | resource         | pod/ruby-hello-world-1-build |
      | oc_opts_end      |                              |
      | exec_command     | cat                          |
      | exec_command_arg | /var/lib/kubelet/config.json |
      | n                | <%= project.name %>          |
    Then the step should succeed
    And the output should contain:
      | registry.redhat.io |

  # @author wewang@redhat.com
  # @case_id OCP-24931
  @admin
  Scenario: Mount trusted CA for cluster proxies to source build pod
  Given I run the :get admin command with:
    | resource      | configmap                          |
    | resource_name | user-ca-bundle                     |
    | template      | '{{index .data "ca-bundle.crt" }}' | 
    | namespace     | openshift-config                   |
  And the step should succeed
  And I save the output to file> user_ca
  And I replace lines in "user_ca":
    | '-----BEGIN CERTIFICATE----- | -----BEGIN CERTIFICATE----- |
  And the step should succeed
  When I delete matching lines from "user_ca":
    | ' |
  Then the step should succeed
  And evaluation of `File.read("user_ca")` is stored in the :userca clipboard
  Given I have a project
  When I obtain test data file "build/https_cases/bc_source.yaml"
  When I run the :create client command with:
    | f | bc_source.yaml |
  Then the step should succeed
  When I run the :start_build client command with:
    | buildconfig | ca-test-source |
  Then the step should succeed
  And the "ca-test-source-1" build completed
  When I get project configmaps named "ca-test-1-global-ca"
  Then the step should succeed
  And I run the :describe client command with:
    | resource | pods                   |
    | name     | ca-test-source-1-build |
  And the step should succeed
  And the output should contain "/var/run/configs/openshift.io/pki"
  When I run the :debug admin command with:
    | resource         | pod/ca-test-source-1-build                          |
    | oc_opts_end      |                                                     |
    | exec_command     | cat                                                 |
    | exec_command_arg | /var/run/configs/openshift.io/pki/tls-ca-bundle.pem |
    | n                | <%= project.name %>                                 |
  Then the step should succeed
  And evaluation of `@result[:stdout]` is stored in the :buildca clipboard
  And the expression should be true> cb.userca == cb.buildca

  # @author wewang@redhat.com
  # @case_id OCP-37460
  @admin
  Scenario: Print Buildah version in Builds
    Given I have a project
    When I run the :new_app client command with:
      | app_repo     | https://github.com/openshift/ruby-hello-world |
      | image_stream | openshift/ruby:latest                         |
    Then the step should succeed
    And the "ruby-hello-world-1" build completed
    When I run the :debug admin command with:
      | resource         | pod/ruby-hello-world-1-build    |
      | oc_opts_end      |                                 |
      | exec_command     | /usr/bin/openshift-docker-build | 
      | exec_command_arg | version                         |                                
      | n                | <%= project.name %>             |
    And the output should contain:
      | Buildah version |
    When I run the :debug admin command with:
      | resource         | pod/ruby-hello-world-1-build             |
      | oc_opts_end      |                                          |
      | exec_command     | /usr/bin/openshift-extract-image-content |
      | exec_command_arg | version                                  |
      | n                | <%= project.name %>                      |
    And the output should contain:
      | Buildah version  |
    When I run the :debug admin command with:
      | resource         | pod/ruby-hello-world-1-build |
      | oc_opts_end      |                              |
      | exec_command     | /usr/bin/openshift-git-clone |
      | exec_command_arg | version                      |
      | n                | <%= project.name %>          |
    And the output should contain:
      | Buildah version |
    When I run the :debug admin command with:
      | resource         | pod/ruby-hello-world-1-build         |
      | oc_opts_end      |                                      |
      | exec_command     | /usr/bin/openshift-manage-dockerfile |
      | exec_command_arg | version                              |
      | n                | <%= project.name %>                  |
    And the output should contain:
      | Buildah version |
    When I run the :debug admin command with:
      | resource         | pod/ruby-hello-world-1-build |
      | oc_opts_end      |                              |
      | exec_command     | /usr/bin/openshift-sti-build |
      | exec_command_arg | version                      |
      | n                | <%= project.name %>          |
    And the output should contain:
      | Buildah version |
    When I run the :start_build client command with:
      | buildconfig    | ruby-hello-world |
      | build_loglevel | 5                |
    Then the step should succeed
    And the "ruby-hello-world-2" build completed
    When I run the :logs client command with:
      | f             | f                        |
      | resource_name | build/ruby-hello-world-2 |
    Then the step should succeed
    And the output should contain:
      | Powered by buildah |
