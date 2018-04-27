Feature: buildlogic.feature

  # @author haowang@redhat.com
  # @case_id OCP-9769
  @admin
  Scenario: if build fails to schedule because of quota, after the quota increase, the build should start
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/quota_pods.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/test-buildconfig.json |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    When I get project build
    Then the output should contain:
      |  (CannotCreateBuildPod) |
    When I run the :delete admin command with:
      | object_type       | resourcequota       |
      | object_name_or_id | quota               |
      | n                 | <%= project.name %> |
    Then the step should succeed
    Then I wait up to 60 seconds for the steps to pass:
    """
    When I get project build
    Then the output should not contain:
      |  (CannotCreateBuildPod) |
    """

  # @author haowang@redhat.com
  # @case_id OCP-11545
  Scenario: Build with specified Dockerfile via new-build -D
    Given I have a project
    When I run the :new_build client command with:
      | D    | FROM centos:7\nRUN echo "hello" |
      | to   | myappis                         |
      | name | myapp                           |
    Then the step should succeed
    And the "myapp-1" build was created
    And the "myapp-1" build completed

  # @author xiazhao@redhat.com
  # @case_id OCP-11170
  Scenario: Result image will be tried to push after multi-build
    Given I have a project
    When I run the :new_app client command with:
      | file |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/php-55-rhel7-stibuild.json |
    Then the step should succeed
    # The 1st build should be triggered automatically
    And the "php-sample-build-1" build was created
    # Trigger the 2nd build in order for doing multi-builds
    When I run the :start_build client command with:
      | buildconfig | php-sample-build |
    Then the step should succeed
    And the "php-sample-build-2" build was created
    # Wait for the first 2 builds finished
    And the "php-sample-build-1" build finished
    And the "php-sample-build-2" build finished
    # Trigger the 3rd build, it should succeed
    When I run the :start_build client command with:
      | buildconfig | php-sample-build |
    Then the step should succeed
    And the "php-sample-build-3" build was created
    And the "php-sample-build-3" build completed

  # @author gpei@redhat.com
  # @case_id OCP-11767
  Scenario: Create build without output
    Given I have a project
    When I run the :new_build client command with:
      | app_repo  | centos/ruby-23-centos7~https://github.com/openshift/ruby-hello-world.git |
      | no-output | true                                                                 |
      | name      | myapp                                                                |
    Then the step should succeed
    And the "myapp-1" build was created
    And the "myapp-1" build completed

  # @author yantan@redhat.com
  # @case_id OCP-10799
  Scenario: Create new build config use dockerfile with source repo
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | https://github.com/openshift/ruby-hello-world   |
      | D        | FROM centos/ruby-22-centos7:latest\nRUN echo ok |
    Then the step should succeed
    When I get project buildconfigs as YAML
    Then the step should succeed
    Then the output should match:
      | dockerfile   |
      | FROM centos/ruby-22-centos7:latest                 |
      | RUN echo ok  |
      | uri: https://github.com/openshift/ruby-hello-world |
      | type: [Gg]it |
    When I get project build
    Then the "ruby-hello-world-1" build completed

  # @author haowang@redhat.com
  # @case_id OCP-11508
  Scenario: Prevent STI builder images from running as root
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc499515/test-buildconfig-user0.json |
    Then the step should succeed
    Given the "ruby-sample-build-user0-1" build was created
    And the "ruby-sample-build-user0-1" build failed
    When I run the :build_logs client command with:
      | build_name  | ruby-sample-build-user0-1 |
    Then the output should match:
      | specify.*user |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc499515/test-buildconfig-userdefault.json |
    Then the step should succeed
    Given the "ruby-sample-build-userdefault-1" build was created
    And the "ruby-sample-build-userdefault-1" build failed
    When I run the :build_logs client command with:
      | build_name  | ruby-sample-build-userdefault-1 |
    Then the output should match:
      | specify.*user |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc499515/test-buildconfig-userroot.json |
    Then the step should succeed
    Given the "ruby-sample-build-userroot-1" build was created
    And the "ruby-sample-build-userroot-1" build failed
    When I run the :build_logs client command with:
      | build_name  | ruby-sample-build-userroot-1 |
    Then the output should match:
      | specify.*user |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc499515/test-buildconfig-usernon.json |
    Then the step should succeed
    Given the "ruby-sample-build-usernon-1" build was created
    And the "ruby-sample-build-usernon-1" build failed
    When I run the :build_logs client command with:
      | build_name  | ruby-sample-build-usernon-1 |
    Then the output should match:
      | specify.*user |

  # @author haowang@redhat.com
  # @case_id OCP-11740
  Scenario: Prevent STI builder images from running as root - using onbuild image
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc499516/test-buildconfig-onbuild-user0.json |
    Then the step should succeed
    Given the "ruby-sample-build-onbuild-user0-1" build was created
    And the "ruby-sample-build-onbuild-user0-1" build failed
    When I run the :build_logs client command with:
      | build_name  | ruby-sample-build-onbuild-user0-1 |
    Then the output should contain:
      |  not allowed |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc499516/test-buildconfig-onbuild-userdefault.json |
    Then the step should succeed
    Given the "ruby-sample-build-onbuild-userdefault-1" build was created
    And the "ruby-sample-build-onbuild-userdefault-1" build failed
    When I run the :build_logs client command with:
      | build_name  | ruby-sample-build-onbuild-userdefault-1 |
    Then the output should contain:
      |  not allowed |

  # @author haowang@redhat.com
  Scenario Outline: ForcePull image for build
    Given I have a project
    When I run the :create client command with:
      | f | <template> |
    Then the step should succeed
    Given the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build becomes :running
    When I run the :describe client command with:
      | resource | build               |
      | name     | ruby-sample-build-1 |
    Then the step should succeed
    And the output should match:
      | Force Pull:\s+(true\|yes)|

    Examples:
      | template                                                                                                                    |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/forcePull/buildconfig-docker-ImageStream.json      | # @case_id OCP-10651
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/forcePull/buildconfig-s2i-ImageStream.json         | # @case_id OCP-11148
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/forcePull/buildconfig-docker-dockerimage.json      | # @case_id OCP-10652
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/forcePull/buildconfig-s2i-dockerimage.json         | # @case_id OCP-11149

  # @author haowang@redhat.com
  Scenario Outline: ForcePull image for build using ImageSteamImage
    Given I have a project
    When I run the :get client command with:
      | resource      | istag          |
      | resource_name | ruby:2.2       |
      | o             | json           |
      | n             | openshift      |
    Then the step should succeed
    And evaluation of `@result[:parsed]['image']['metadata']['name']` is stored in the :imagestreamimage clipboard
    When I run oc create over "<template>" replacing paths:
      | ['spec']['strategy']['<strategy>']['from']['name'] | ruby@<%= cb.imagestreamimage %> |
    Then the step should succeed
    Given the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build becomes :running
    When I run the :describe client command with:
      | resource | build               |
      | name     | ruby-sample-build-1 |
    Then the step should succeed
    And the output should match:
      | Force Pull:\s+(true\|yes)|

    Examples:
      | strategy       | template                                                                                                                    |
      | dockerStrategy | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/forcePull/buildconfig-docker-ImageStreamImage.json | # @case_id OCP-11500
      | sourceStrategy | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/forcePull/buildconfig-s2i-ImageStreamImage.json    | # @case_id OCP-11735

  # @author yantan@redhat.com
  # @case_id OCP-10745
  Scenario: Build with specified Dockerfile to image with same image name via new-build
    Given I have a project
    When I run the :new_build client command with:
      | D | FROM centos:7\nRUN yum install -y httpd |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | bc     |
      | name     | centos |
    Then the output should match:
      | From Image:\s+ImageStreamTag centos:7     |
      | Output to:\s+ImageStreamTag centos:latest |
    Given the "centos-1" build becomes :complete
    When I run the :new_build client command with:
      | D    | FROM centos:7\nRUN yum install -y httpd |
      | to   | centos:7                                |
      | name | myapp                                   |
    And I get project bc
    Then the output should contain:
      | myapp |
    Given the "myapp-1" build becomes :complete
    And the "myapp-2" build becomes :complete
    And the "myapp-3" build becomes :running
    When I run the :new_build client command with:
      | code         | https://github.com/openshift/nodejs-ex.git    |
      | image_stream | openshift/nodejs:0.10                         |
      | code         | https://github.com/openshift/ruby-hello-world |
      | image_stream | openshift/ruby:2.0                            |
      | to           | centos:7                                      |
    Then the step should fail
    And the output should contain:
      | error |

  # @author dyan@redhat.com
  # @case_id OCP-10596
  Scenario: Failed to push image with invalid Docker secret
    Given I have a project
    When I run the :oc_secrets_new_dockercfg client command with:
      | secret_name     | pushme |
      | docker_username | dyan |
      | docker_password | xxxxxx |
      | docker_email    | dyan@redhat.com |
    Then the step should succeed
    When I run the :secret_add client command with:
      | sa_name | builder |
      | secret_name | pushme |
    Then the step should succeed
    When I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc476354/pushimage.json"
    Then the step should succeed
    And the "ruby22-sample-build-1" build failed
    When I run the :logs client command with:
      | resource_name | build/ruby22-sample-build-1 |
    Then the output should contain:
      | build error |
      | Failed to push image |

  # @author haowang@redhat.com
  # @case_id OCP-11720
  Scenario: Build from private git repo with/without ssh key
    Given I have a project
    And I have an ssh-git service in the project
    And the "secret" file is created with the following lines:
      | <%= cb.ssh_private_key.to_pem %> |
    And I run the :oc_secrets_new_sshauth client command with:
      | ssh_privatekey | secret   |
      | secret_name    | mysecret |
    Then the step should succeed
    When I execute on the pod:
      | bash |
      | -c   |
      | cd /repos/ && rm -rf sample.git && git clone --bare https://github.com/openshift/ruby-hello-world sample.git |
    Then the step should succeed
    When I run the :new_build client command with:
      | image_stream | openshift/ruby:2.2                            |
      | code         | https://github.com/openshift/ruby-hello-world |
      | name         | ruby-hello-world                              |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completed
    When I run the :patch client command with:
      | resource      | buildconfig                                              |
      | resource_name | ruby-hello-world                                         |
      | p             | {"spec":{"source":{"git":{"uri":"<%= cb.git_repo %>"}}}} |
    Then the step should succeed
    And I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the "ruby-hello-world-2" build was created
    Then the "ruby-hello-world-2" build failed
    When I run the :patch client command with:
      | resource      | buildconfig                                              |
      | resource_name | ruby-hello-world                                         |
      | p             | {"spec":{"source":{"sourceSecret":{"name":"mysecret"}}}} |
    Then the step should succeed
    And I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the "ruby-hello-world-3" build was created
    Then the "ruby-hello-world-3" build completed

  # @author haowang@redhat.com
  # @case_id OCP-11160
  @admin
  Scenario: Check labels info in built images when do sti build in openshift
    Given I have a project
    When I run the :new_build client command with:
      | app_repo     | https://github.com/openshift-qe/ruby-hello-world-context |
      | image_stream | openshift/ruby:latest                                    |
      | context_dir  | test                                                     |
      | name         | ruby-hello-world                                         |
    Then the step should succeed
    Then the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completed
    And evaluation of `pod("ruby-hello-world-1-build").node_name(user: user)` is stored in the :build_pod_node clipboard
    Then I use the "<%= cb.build_pod_node %>" node
    And evaluation of `image_stream("ruby-hello-world").docker_image_repository(user: user)` is stored in the :built_image clipboard
    And I run commands on the host:
      | docker inspect <%= cb.built_image %> |
    Then the step should succeed
    And the output should match:
      | .*io.openshift.build.commit.author.*                 |
      | .*io.openshift.build.commit.date.*                   |
      | .*io.openshift.build.commit.id.*                     |
      | .*io.openshift.build.commit.message.*                |
      | .*io.openshift.build.commit.ref.*master.*            |
      | .*io.openshift.build.image.*ruby.*                   |
      | .*io.openshift.build.source-context-dir.*test.*      |
      | .*io.openshift.build.source-location.*openshift-qe.* |
      | .*io.openshift.expose-services.*                     |
      | .*io.openshift.s2i.scripts-url.*                     |
      | .*io.openshift.tags.*                                |
      | .*io.s2i.scripts-url.*                               |
      | .*OPENSHIFT_BUILD_NAME.*                             |
      | .*OPENSHIFT_BUILD_NAMESPACE.*                        |
      | .*OPENSHIFT_BUILD_SOURCE.*                           |
      | .*OPENSHIFT_BUILD_COMMIT.*                           |

  # @author yantan@redhat.com
  # @case_id OCP-12031
  Scenario: Trigger build from webhook against external git provider - gitlab
    Given I have a project
    And I have an ssh-git service in the project
    And the "secret" file is created with the following lines:
      | <%= cb.ssh_private_key.to_pem %>  |
    When I run the :oc_secrets_new_sshauth client command with:
      | ssh_privatekey | secret           |
      | secret_name    | mysecret         |
    Then the step should succeed
    When I execute on the pod:
      | bash           |
      | -c             |
      | cd /repos/ && rm -rf sample.git && git clone --bare https://github.com/openshift-qe/ruby-ex sample.git |
    Then the step should succeed
    When I run the :new_build client command with:
      | image_stream   | openshift/ruby:2.2                            |
      | code           | https://github.com/openshift/ruby-hello-world |
      | name           | ruby-hello-world                              |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completes
    When I run the :patch client command with:
      | resource       | buildconfig                                                   |
      | resource_name  | ruby-hello-world                                              |
      | p              | {"spec":{"source":{"git":{"uri":"<%= cb.git_repo %>","ref":"test-tcms438840"},"sourceSecret":{"name":"mysecret"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig    | ruby-hello-world   |
    Then the step should succeed
    And the "ruby-hello-world-2" build was created
    And the "ruby-hello-world-2" build completes
    When I get project buildconfigs as JSON
    And evaluation of `@result[:parsed]['items'][0]['spec']['triggers'][1]['generic']['secret']` is stored in the :secret_name clipboard
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/pkg/build/webhook/generic/testdata/push-generic.json"
    When I replace lines in "push-generic.json":
      | refs/heads/master                        | refs/heads/test-tcms438840               |
      | git://mygitserver/myrepo.git             | git@git-server:sample.git                |
      | 9bdc3a26ff933b32f3e558636b58aea86a69f051 | 89af0dd3183f71b9ec848d5cc2b55599244de867 |
    And I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-hello-world/webhooks/<%= cb.secret_name %>/generic
    :method: post
    :headers:
      :content_type: application/json
    :payload: <%= File.read("push-generic.json").to_json %>
    """
    Then the step should succeed
    And the "ruby-hello-world-3" build was created
    And the "ruby-hello-world-3" build completes

  # @author dyan@redhat.com
  # @case_id OCP-12130
  Scenario: Trigger generic webhooks with invalid branch or commit ID for external private git solutions - gitlab
    Given I have a project
    And I have an ssh-git service in the project
    And the "secret" file is created with the following lines:
      | <%= cb.ssh_private_key.to_pem %>  |
    When I run the :oc_secrets_new_sshauth client command with:
      | ssh_privatekey | secret           |
      | secret_name    | mysecret         |
    Then the step should succeed
    When I execute on the pod:
      | bash           |
      | -c             |
      | cd /repos/ && rm -rf sample.git && git clone --bare https://github.com/openshift-qe/ruby-ex sample.git |
    Then the step should succeed
    When I run the :new_build client command with:
      | image_stream   | openshift/ruby:2.2                            |
      | code           | https://github.com/openshift/ruby-hello-world |
      | name           | ruby-hello-world                              |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completes
    When I run the :patch client command with:
      | resource       | buildconfig                                                   |
      | resource_name  | ruby-hello-world                                              |
      | p              | {"spec":{"source":{"git":{"uri":"<%= cb.git_repo %>","ref":"test-tcms438840"},"sourceSecret":{"name":"mysecret"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig    | ruby-hello-world   |
    Then the step should succeed
    And the "ruby-hello-world-2" build was created
    And the "ruby-hello-world-2" build completes
    When I get project buildconfigs as JSON
    And evaluation of `@result[:parsed]['items'][0]['spec']['triggers'][1]['generic']['secret']` is stored in the :secret_name clipboard
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/pkg/build/webhook/generic/testdata/push-generic.json"
    When I replace lines in "push-generic.json":
      | refs/heads/master                        | refs/heads/test123                       |
      | git://mygitserver/myrepo.git             | git@git-server:sample.git                |
      | 9bdc3a26ff933b32f3e558636b58aea86a69f051 | 89af0dd3183f71b9ec848d5cc2b55599244de867 |
    Then the step should succeed
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-hello-world/webhooks/<%= cb.secret_name %>/generic
    :method: post
    :headers:
      :content_type: application/json
    :payload: <%= File.read("push-generic.json").to_json %>
    """
    Then the step should succeed
    When I get project build
    Then the step should succeed
    And the output should not contain "ruby-hello-world-3"
    When I replace lines in "push-generic.json":
      | refs/heads/test123                        | refs/heads/test-tcms438840 |
      | 89af0dd3183f71b9ec848d5cc2b55599244de867  | 123456 |
    Then the step should succeed
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-hello-world/webhooks/<%= cb.secret_name %>/generic
    :method: post
    :headers:
      :content_type: application/json
    :payload: <%= File.read("push-generic.json").to_json %>
    """
    Then the step should succeed
    When I get project build
    Then the step should succeed
    Given the "ruby-hello-world-3" build was created
    And the "ruby-hello-world-3" build failed
    When I run the :logs client command with:
      | resource_name | build/ruby-hello-world-3 |
    Then the step should succeed
    And the output should match:
      | [Ee]rror  |
      | 123456 |

  # @author yantan@redhat.com
  # @case_id OCP-11896
  Scenario: Create new-app from private git repo with ssh key
    Given I have a project
    When I run the :new_app client command with:
      | image_stream   | openshift/perl:5.20       |
      | code           | https://github.com/openshift/sti-perl.git |
      | context_dir    | 5.20/test/sample-test-app/|
    Then the step should succeed
    Given the "sti-perl-1" build completes
    And I have an ssh-git service in the project
    And the "secret" file is created with the following lines:
      | <%= cb.ssh_private_key.to_pem %>         |
    And I run the :oc_secrets_new_sshauth client command with:
      | ssh_privatekey | secret      |
      | secret_name    | mysecret    |
    When I execute on the pod:
      | bash           |
      | -c             |
      | cd /repos/ && rm -rf sample.git && git clone --bare https://github.com/openshift/sti-perl sample.git |
    Then the step should succeed
    When I run the :patch client command with:
      | resource       | buildconfig                                                 |
      | resource_name  | sti-perl                                                    |
      | p              | {"spec":{"source":{"git":{"uri":"<%= cb.git_repo %>"},"sourceSecret":{"name":"mysecret"}}}} |
    Then the step should succeed
    And I run the :start_build client command with:
      | buildconfig    | sti-perl    |
    Then the "sti-perl-2" build was created
    Then the "sti-perl-2" build completes
    When I expose the "sti-perl" service
    Then I wait for a web server to become available via the "sti-perl" route

  # @author yantan@redhat.com
  # @case_id OCP-11479
  Scenario: Build from private git repo with wrong auth method
    Given I have a project
    When I run the :new_build client command with:
      | image_stream   | openshift/ruby:2.2                            |
      | code           | https://github.com/openshift/ruby-hello-world |
      | name           | ruby-hello-world                              |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    Given I have an ssh-git service in the project
    When I execute on the pod:
      | bash           |
      | -c             |
      | cd /repos/ && rm -rf sample.git && git clone --bare https://github.com/openshift/ruby-hello-world sample.git |
    Then the step should succeed
    Given a 20 characters random string of type :dns is stored into the :ssh_secret clipboard
    And the "secret" file is created with the following lines:
      | <%= cb.ssh_secret %>      |
    When I run the :oc_secrets_new_sshauth client command with:
      | ssh_privatekey | secret   |
      | secret_name    | mysecret |
    Then the step should succeed
    When I run the :patch client command with:
      | resource       | buildconfig              |
      | resource_name  | ruby-hello-world         |
      | p              | {"spec":{"source":{"git":{"uri":"<%= cb.git_repo %>"},"sourceSecret":{"name":"mysecret"}}}} |
    Then the step should succeed
    And I run the :start_build client command with:
      | buildconfig    | ruby-hello-world         |
    Then the step should succeed
    Given the "ruby-hello-world-2" build was created
    Given the "ruby-hello-world-2" build failed
    When I run the :logs client command with:
      | resource_name  | build/ruby-hello-world-2 |
    Then the step should succeed
    And the output should contain:
      | Permission denied                         |

  # @author xiuwang@redhat.com
  # @case_id OCP-10669
  @admin
  Scenario: Check labels info in built images when do docker build in openshift
    Given I have a project
    When I run the :new_build client command with:
      | app_repo     | https://github.com/openshift-qe/ruby-hello-world-context |
      | context_dir  | test                                                     |
      | name         | ruby-hello-world                                         |
    Then the step should succeed
    Then the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completed
    And evaluation of `pod("ruby-hello-world-1-build").node_name(user: user)` is stored in the :build_pod_node clipboard
    Then I use the "<%= cb.build_pod_node %>" node
    And evaluation of `image_stream("ruby-hello-world").docker_image_repository(user: user)` is stored in the :built_image clipboard
    And I run commands on the host:
      | docker inspect <%= cb.built_image %> |
    Then the step should succeed
    And the output should match:
      | .*io.openshift.build.commit.author.*                 |
      | .*io.openshift.build.commit.date.*                   |
      | .*io.openshift.build.commit.id.*                     |
      | .*io.openshift.build.commit.message.*                |
      | .*io.openshift.build.commit.ref.*master.*            |
      | .*io.openshift.build.source-context-dir.*test.*      |
      | .*io.openshift.build.source-location.*openshift-qe.* |
      | .*io.openshift.expose-services.*                     |
      | .*io.openshift.s2i.scripts-url.*                     |
      | .*io.openshift.tags.*                                |
      | .*io.s2i.scripts-url.*                               |
      | .*OPENSHIFT_BUILD_NAME.*                             |
      | .*OPENSHIFT_BUILD_NAMESPACE.*                        |
      | .*OPENSHIFT_BUILD_SOURCE.*                           |
      | .*OPENSHIFT_BUILD_COMMIT.*                           |

  # @author shiywang@redhat.com
  Scenario Outline: Tune perl image to autoconfigure based on available memory
    Given I have a project
    When I run the :new_app client command with:
      | app_repo     | https://github.com/openshift/dancer-ex|
      | image_stream | <image>                               |
    Then the step should succeed
    And I run the :patch client command with:
      | resource      | dc                                                                                                               |
      | resource_name | dancer-ex                                                                                                        |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"dancer-ex","resources":{"limits":{"memory":"<memory>"}}}]}}}}  |
    Then the step should succeed
    And the "dancer-ex-1" build was created
    And the "dancer-ex-1" build completed
    Given a pod becomes ready with labels:
      | deployment=dancer-ex-1 |
    And I execute on the pod:
      | scl | enable | httpd24 | cat /opt/app-root/etc/httpd.d/50-mpm.conf |
    Then the step should succeed
    And the output should match:
      | StartServers\\s*8          |
      | MinSpareServers\\s*8       |
      | MaxSpareServers\\s*18      |
      | MaxRequestWorkers\\s*<num> |
      | ServerLimit\\s*<num>       |
    When I run the :env client command with:
      | resource | dc/dancer-ex                |
      | e        | HTTPD_MAX_REQUEST_WORKERS=2 |
      | e        | HTTPD_START_SERVERS=1       |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=dancer-ex-2 |
    And I execute on the pod:
      | scl | enable | httpd24 | cat /opt/app-root/etc/httpd.d/50-mpm.conf |
    Then the step should succeed
    And the output should match:
      | StartServers\\s*1       |
      | MinSpareServers\\s*1    |
      | MaxRequestWorkers\\s*2  |
      | ServerLimit\\s*2        |
    When I wait for the "dancer-ex" service to become ready
    And I get the service pods
    Then the step should succeed
    When I execute on the pod:
      | bash                                                                          |
      | -c                                                                            |
      | /opt/rh/httpd24/root/usr/bin/ab -c 200 -n 1000 http://<%= service.ip %>:8080/  |
    Then the step should succeed
    When I execute on the pod:
      | bash                                                                          |
      | -c                                                                            |
      | ps -ef \|grep httpd \|grep -v grep \|awk '{print $2}'\|grep -v ^1$ \|wc -l    |
    Then the step should succeed
    And the output should contain "2"
    #100Mi for OCP env, 204Mi is for online env
    Examples:
      | image     | memory | num |
      | perl:5.16 | 100Mi  | 10  | # @case_id OCP-10855
      | perl:5.20 | 100Mi  | 10  | # @case_id OCP-11283
      | perl:5.24 | 100Mi  | 10  | # @case_id OCP-11378
      | perl:5.16 | 480Mi  | 64  | # @case_id OCP-13144
      | perl:5.20 | 480Mi  | 64  | # @case_id OCP-13145

  # @author shiywang@redhat.com
  # @case_id OCP-10835
  Scenario: Cancel builds with --state negative test
    Given I have a project
    When I run the :new_build client command with:
      | image_stream | openshift/ruby:latest                            |
      | code         | http://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-1 |
      | state      | completed          |
    And the output should contain "The '--state' flag has invalid value. Must be one of 'new', 'pending', or 'running'"
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-1 |
      | state      | failed             |
    And the output should contain "The '--state' flag has invalid value. Must be one of 'new', 'pending', or 'running'"
    And the "ruby-hello-world-1" build becomes :running
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-1 |
      | state      | running            |
    Then the step should succeed
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-1 |
      | state      | cancelled          |
    And the output should contain "The '--state' flag has invalid value. Must be one of 'new', 'pending', or 'running'"
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-1 |
      | state      | invalid            |
    And the output should contain "The '--state' flag has invalid value. Must be one of 'new', 'pending', or 'running'"

  # @author dyan@redhat.com
  # @case_id OCP-11081
  Scenario: Show the fields of build
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    Given the "ruby-hello-world-1" build becomes :running
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-1 |
    Then the step should succeed
    When I run the :describe client command with:
      | resource   | build               |
      | name       | ruby-hello-world-1 |
    Then the step should succeed
    And the output should match:
      | [Nn]ame                |
      | [Ll]abels              |
      | [Ss]tatus              |
      | [Cc]ancelled           |
      | [Dd]uration            |
      | [Ss]trategy            |
    When I run the :patch client command with:
      | resource      | bc  |
      | resource_name | ruby-hello-world |
      | p             | {"spec": {"source": {"sourceSecret": {"name": "mysecret"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    And the "ruby-hello-world-2" build was created
    Given the "ruby-hello-world-2" build becomes :pending
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-2 |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | build |
      | name     | ruby-hello-world-2 |
    Then the step should succeed
    And the output should match:
      | [Nn]ame                |
      | [Ll]abels              |
      | [Ss]tatus              |
      | [Cc]ancelled           |
      | [Dd]uration            |
      | [Ss]trategy            |


  # @author wzheng@redhat.com
  # @case_id OCP-10577
  Scenario: Buildconfig cannot be created with long name label(more than64)
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc527410/longname-build-withlabel.json |
    Then the step should fail
    And the output should contain "must be no more than 63 characters"

  # @author dyan@redhat.com
  # @case_id OCP-13683
  Scenario: Check s2i build substatus and times
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc470422/application-template-stibuild.json| 
    Then the step should succeed
    Given the "ruby-sample-build-1" build completed
    When I run the :describe client command with:
      | resource | build               |
      | name     | ruby-sample-build-1 |
    Then the step should succeed
    And the output should match:
      | Duration:\s+(\d+m)?\d+s        |
      | FetchInputs:\s+(\d+m)?\d+s     |
      | CommitContainer:\s+(\d+m)?\d+s |
      | Assemble:\s+(\d+m)?\d+s        |
      | PostCommit:\s+(\d+m)?\d+s      |
      | PushImage:\s+(\d+m)?\d+s       |

  # @author dyan@redhat.com
  # @case_id OCP-13684
  Scenario: Check docker build substatus and times
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-dockerbuild.json |
    Then the step should succeed
    Given the "ruby-sample-build-1" build completed
    When I run the :describe client command with:
      | resource | build               |
      | name     | ruby-sample-build-1 |
    Then the step should succeed
    And the output should match:
      | Duration:\s+(\d+m)?\d+s    |
      | FetchInputs:\s+(\d+m)?\d+s |
      | Build:\s+(\d+m)?\d+s       |
      | PostCommit:\s+(\d+m)?\d+s  |
      | PushImage:\s+(\d+m)?\d+s   |

 
  # @author xiuwang@redhat.com
  # @case_id OCP-13684
  Scenario: Prune old builds automaticly
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | ruby                                          | 
      | code         | https://github.com/openshift/ruby-hello-world | 
    Then the step should succeed
    When I run the :get client command with:
      | resource      | buildconfig      |
      | resource_name | ruby-hello-world |
      | o             | yaml             |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["spec"]["failedBuildsHistoryLimit"] == 5
    And the expression should be true> @result[:parsed]["spec"]["successfulBuildsHistoryLimit"] == 5
    Given the "ruby-hello-world-1" build completed
    Given I run the steps 5 times:
    """
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    """
    Given the "ruby-hello-world-6" build completed
    Given I get project builds
    Then the output should match 5 times:
      | Complete |
    Then the output should not contain:
      |ruby-hello-world-1|
    Given I run the steps 3 times:
    """
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    """
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-7 |
      | build_name | ruby-hello-world-8 |
      | build_name | ruby-hello-world-9 |
    Then the step should succeed
    Given I run the :patch client command with:
      | resource      | bc                                                                                |
      | resource_name | ruby-hello-world                                                                  |
      | p             | {"spec":{"source":{"git":{"uri":"https://xxxgithub.com/openshift/ruby-ex.git"}}}} |
    Given I run the steps 3 times:
    """
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    """
    Given the "ruby-hello-world-12" build fails
    Given I get project builds
    Then the output should match 2 times:
      | Git.*Cancelled |
    Then the output should match 3 times:
      | Git.*Failed |
    Then the output should not contain:
      |ruby-hello-world-7|
