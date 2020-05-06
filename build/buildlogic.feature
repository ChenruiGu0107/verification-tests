Feature: buildlogic.feature

  # @author haowang@redhat.com
  # @case_id OCP-9769
  @admin
  Scenario: if build fails to schedule because of quota, after the quota increase, the build should start
    Given I have a project
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/build/quota_pods.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    And I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/build/test-buildconfig.json |
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
  # @case_id OCP-11508
  Scenario: Prevent STI builder images from running as root
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/build/tc499515/test-buildconfig-user0.json |
    Then the step should succeed
    Given the "ruby-sample-build-user0-1" build was created
    And the "ruby-sample-build-user0-1" build failed
    When I run the :build_logs client command with:
      | build_name  | ruby-sample-build-user0-1 |
    Then the output should match:
      | specify.*user |
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/build/tc499515/test-buildconfig-userdefault.json |
    Then the step should succeed
    Given the "ruby-sample-build-userdefault-1" build was created
    And the "ruby-sample-build-userdefault-1" build failed
    When I run the :build_logs client command with:
      | build_name  | ruby-sample-build-userdefault-1 |
    Then the output should match:
      | specify.*user |
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/build/tc499515/test-buildconfig-userroot.json |
    Then the step should succeed
    Given the "ruby-sample-build-userroot-1" build was created
    And the "ruby-sample-build-userroot-1" build failed
    When I run the :build_logs client command with:
      | build_name  | ruby-sample-build-userroot-1 |
    Then the output should match:
      | specify.*user |
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/build/tc499515/test-buildconfig-usernon.json |
    Then the step should succeed
    Given the "ruby-sample-build-usernon-1" build was created
    And the "ruby-sample-build-usernon-1" build failed
    When I run the :build_logs client command with:
      | build_name  | ruby-sample-build-usernon-1 |
    Then the output should match:
      | specify.*user |

  # @author haowang@redhat.com
  Scenario Outline: ForcePull image for build using ImageSteamImage
    Given I have a project
    When I run the :get client command with:
      | resource      | istag       |
      | resource_name | ruby:latest |
      | o             | json        |
      | n             | openshift   |
    Then the step should succeed
    And evaluation of `@result[:parsed]['image']['metadata']['name']` is stored in the :imagestreamimage clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/build/forcePull/<template>" replacing paths:
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
      | strategy       | template                                 |
      | dockerStrategy | buildconfig-docker-ImageStreamImage.json | # @case_id OCP-11500
      | sourceStrategy | buildconfig-s2i-ImageStreamImage.json    | # @case_id OCP-11735

  # @author haowang@redhat.com
  # @case_id OCP-11160
  @admin
  Scenario: Check labels info in built images when do sti build in openshift
    Given I have a project
    Given default registry service ip is stored in the :registry_hostname clipboard
    And I have a skopeo pod in the project
    Given I find a bearer token of the deployer service account
    When I run the :new_build client command with:
      | app_repo     | https://github.com/sclorg/s2i-ruby-container |
      | context_dir  | 2.5/test/puma-test-app/                      |
      | image_stream | openshift/ruby:latest                        |
      | name         | ruby-hello-world                             |
    Then the step should succeed
    Then the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completed
    When I execute on the pod:
      | skopeo             |
      | --debug            |
      | --insecure-policy  |
      | inspect            |
      | --tls-verify=false |
      | --creds            |
      | dnm:<%= service_account.cached_tokens.first %>                                   |
      | docker://<%= cb.registry_hostname %>/<%= project.name %>/ruby-hello-world:latest |
    And the output should match:
      | .*io.openshift.build.commit.author.*                       |
      | .*io.openshift.build.commit.date.*                         |
      | .*io.openshift.build.commit.id.*                           |
      | .*io.openshift.build.commit.message.*                      |
      | .*io.openshift.build.commit.ref.*master.*                  |
      | .*io.openshift.build.image.*ruby.*                         |
      | .*io.openshift.build.source-context-dir.*test.*            |
      | .*io.openshift.build.source-location.*s2i-ruby-container.* |
      | .*io.openshift.expose-services.*                           |
      | .*io.openshift.s2i.scripts-url.*                           |
      | .*io.openshift.tags.*                                      |
      | .*io.s2i.scripts-url.*                                     |

  # @author yantan@redhat.com
  # @case_id OCP-12031
  Scenario: Trigger build from webhook against external git provider - gitlab
    Given I have a project
    And I have an ssh-git service in the project
    And the "secret" file is created with the following lines:
      | <%= cb.ssh_private_key.to_pem %>  |
    When I run the :secrets_new_sshauth client command with:
      | ssh_privatekey | secret           |
      | secret_name    | mysecret         |
    Then the step should succeed
    When I execute on the pod:
      | bash           |
      | -c             |
      | cd /repos/ && rm -rf sample.git && git clone --bare https://github.com/openshift-qe/ruby-ex sample.git |
    Then the step should succeed
    When I run the :new_build client command with:
      | image_stream   | openshift/ruby:latest                         |
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
    :url: <%= env.api_endpoint_url %>/apis/build.openshift.io/v1/namespaces/<%= project.name %>/buildconfigs/ruby-hello-world/webhooks/<%= cb.secret_name %>/generic
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
    When I run the :secrets_new_sshauth client command with:
      | ssh_privatekey | secret           |
      | secret_name    | mysecret         |
    Then the step should succeed
    When I execute on the pod:
      | bash           |
      | -c             |
      | cd /repos/ && rm -rf sample.git && git clone --bare https://github.com/openshift-qe/ruby-ex sample.git |
    Then the step should succeed
    When I run the :new_build client command with:
      | image_stream   | openshift/ruby:latest                         |
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
    :url: <%= env.api_endpoint_url %>/apis/build.openshift.io/v1/namespaces/<%= project.name %>/buildconfigs/ruby-hello-world/webhooks/<%= cb.secret_name %>/generic
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
    :url: <%= env.api_endpoint_url %>/apis/build.openshift.io/v1/namespaces/<%= project.name %>/buildconfigs/ruby-hello-world/webhooks/<%= cb.secret_name %>/generic
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
  # @case_id OCP-11479
  Scenario: Build from private git repo with wrong auth method
    Given I have a project
    When I run the :new_build client command with:
      | image_stream   | openshift/ruby:latest                         |
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
    And I run the :create_secret client command with:
      | secret_type | generic               |
      | name        | mysecret              |
      | from_file   | ssh-privatekey=secret |
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

  # @author shiywang@redhat.com
  Scenario Outline: Tune perl image to autoconfigure based on available memory
    Given I have a project
    When I run the :new_app client command with:
      | app_repo     | https://github.com/sclorg/dancer-ex|
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
    When I run the :set_env client command with:
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
    When I wait for the "dancer-ex" service to become ready up to 300 seconds
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
    And the output should match:
      | invalid.*value.*be one of 'new', 'pending', or 'running'|
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-1 |
      | state      | failed             |
    And the output should match:
      | invalid.*value.*be one of 'new', 'pending', or 'running'|
    And the "ruby-hello-world-1" build becomes :running
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-1 |
      | state      | running            |
    Then the step should succeed
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-1 |
      | state      | cancelled          |
    And the output should match:
      | invalid.*value.*be one of 'new', 'pending', or 'running'|
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-1 |
      | state      | invalid            |
    And the output should match:
      | invalid.*value.*be one of 'new', 'pending', or 'running'|

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
  # @case_id OCP-13906
  Scenario: Check the events for started/completed/failed builds
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/ruby:latest                  |
      | app_repo     | https://github.com/sclorg/ruby-ex |
    Then the step should succeed
    Given the "ruby-ex-1" build completed
    When I run the :describe client command with:
      | resource     | build     |
      | name         | ruby-ex-1 |
    Then the step should succeed
    And the output should contain:
      | Created        |
      | Started        |
      | BuildCompleted |
    When I run the :patch client command with:
      | resource      | buildconfig  |
      | resource_name | ruby-ex      |
      | p             | {"spec":{"source":{"git":{"uri":"http://github.com/openshift/incorrect"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    Given the "ruby-ex-2" build fails
    When I run the :describe client command with:
      | resource     | build     |
      | name         | ruby-ex-2 |
    Then the step should succeed
    And the output should contain:
      | BuildFailed |

  # @author xiuwang@redhat.com
  # @case_id OCP-19736
  Scenario: Add arbitrary labels to builder images
    Given I have a project
    Given default registry service ip is stored in the :registry_hostname clipboard
    And I have a skopeo pod in the project
    Given I find a bearer token of the deployer service account
    When I run the :new_build client command with:
      | app_repo | http://github.com/openshift/ruby-hello-world.git |
      | strategy | docker                                           |
      | l        | app=newbuild1                                    |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | bc               |
      | resource_name | ruby-hello-world |
      | p             | {"spec":{"output":{"imageLabels":[{"name":"apple","value":"yummy"}]}}} |
    Then the step should succeed
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-1 |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    Then the "ruby-hello-world-2" build was created
    And the "ruby-hello-world-2" build completed
    When I execute on the pod:
      | skopeo             |
      | --debug            |
      | --insecure-policy  |
      | inspect            |
      | --tls-verify=false |
      | --creds            |
      | dnm:<%= service_account.cached_tokens.first %>                                   |
      | docker://<%= cb.registry_hostname %>/<%= project.name %>/ruby-hello-world:latest |
    And the output should match:
      | apple.*yummy |
    When I run the :delete client command with:
      | all_no_dash |               |
      | l           | app=newbuild1 |
    Then the step should succeed
    When I run the :new_build client command with:
      | app_repo     | https://github.com/openshift/ruby-hello-world.git |
      | image_stream | ruby                                              |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | bc               |
      | resource_name | ruby-hello-world |
      | p             | {"spec":{"output":{"imageLabels":[{"name":"pineapple","value":"soyummy"}]}}} |
    Then the step should succeed
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-1 |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    Then the "ruby-hello-world-2" build was created
    And the "ruby-hello-world-2" build completed
    When I execute on the pod:
      | skopeo             |
      | --debug            |
      | --insecure-policy  |
      | inspect            |
      | --tls-verify=false |
      | --creds            |
      | dnm:<%= service_account.cached_tokens.first %>                                   |
      | docker://<%= cb.registry_hostname %>/<%= project.name %>/ruby-hello-world:latest |
    And the output should match:
      | pineapple.*soyummy |
    Then the step should succeed
