Feature: stibuild.feature
  # @author haowang@redhat.com
  # @case_id OCP-11464
  @smoke
  Scenario: STI build with SourceURI and context dir
    Given I have a project
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/image/language-image-templates/python-27-rhel7-context-stibuild.json |
    Then the step should succeed
    And the "python-sample-build-1" build was created
    And the "python-sample-build-1" build completed

  # @author wzheng@redhat.com
  # @case_id OCP-11470
  Scenario: Add ENV to STIStrategy buildConfig when do sti build
    Given I have a project
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/build/ruby22rhel7-env-sti.json |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    Given I wait for the "frontend" service to become ready up to 300 seconds
    When I run the :set_env client command with:
      | resource | pods |
      | list     | true |
      | all      | true |
    Then the step should succeed
    And the output should contain:
      | {"name":"DISABLE_ASSET_COMPILATION","value":"true"} |
    When I get project build_config named "ruby-sample-build" as JSON
    And I save the output to file> bc.json
    And I replace lines in "bc.json":
      | true | 1 |
    When I run the :replace client command with:
      | f | bc.json |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    And the "ruby-sample-build-2" build was created
    And the "ruby-sample-build-2" build completed
    Given I wait for the "frontend" service to become ready up to 300 seconds
    When I run the :set_env client command with:
      | resource | pods |
      | list     | true |
      | all      | true |
    Then the step should succeed
    And the output should contain:
      | {"name":"DISABLE_ASSET_COMPILATION","value":"1"} |

  # @author wzheng@redhat.com
  # @case_id OCP-9575
  Scenario: Build invoked once buildconfig is created when there is no imagechangetrigger in buildconfig
    Given I have a project
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/build/stibuild-configchange.json |
    Then the step should succeed
    And the "php-sample-build-1" build was created
    When I run the :describe client command with:
      | resource | build              |
      | name     | php-sample-build-1 |
    Then the output should contain:
      | Build configuration change |

  # @author wzheng@redhat.com
  # @case_id OCP-13448
  Scenario: Error in buildlog if STI build with invalid context dir
    Given I have a project
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/image/language-image-templates/python-27-rhel7-errordir-stibuild.json |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | python-sample-build |
    And the "python-sample-build-1" build was created
    And the "python-sample-build-1" build failed
    When I run the :logs client command with:
      | resource_name | bc/python-sample-build|
    Then the output should contain:
      | no such file or directory |

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

  # @author wzheng@redhat.com
  # @case_id OCP-9550
  Scenario: Provide the built image reference as part of the build status
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://github.com/sclorg/ruby-ex |
      | image_stream | ruby |
    Then the step should succeed
    And evaluation of `image_stream_tag("ruby:latest",project("openshift")).digest` is stored in the :image_id clipboard
    When I run the :describe client command with:
      | resource | build     |
      | name     | ruby-ex-1 |
    Then the output should match:
      | <%= cb.image_id %> |

  # @author wewang@redhat.com
  # @case_id OCP-14967
  @admin
  @destructive
  Scenario: Configure env LOGLEVEL in the BuildDefaults plug-in when build
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        BuildDefaults:
          configuration:
            apiVersion: v1
            kind: BuildDefaultsConfig
            env:
            - name: BUILD_LOGLEVEL
              value: "8"
    """
    And the master service is restarted on all master nodes
    Given I have a project
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/build/ruby22rhel7-template-sti.json |
    Then the step should succeed
    And the "ruby22-sample-build-1" build was created
    And the "ruby22-sample-build-1" build completed
    When I run the :logs client command with:
      | resource_name    | bc/ruby22-sample-build |
    Then the step should succeed
    And the output should match:
      | "name":"BUILD_LOGLEVEL" |
      | "value":"8"             |
    And a pod becomes ready with labels:
      | name=frontend |
    When I execute on the pod:
      | bash                       |
      | -c                         |
      | env \| grep BUILD_LOGLEVEL |
    Then the step should succeed
    And the output should contain:
      | BUILD_LOGLEVEL=8 |

  # @author wewang@redhat.com
  # @case_id OCP-15458
  Scenario:Allow incremental to be specified on s2i build request
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | openshift/ruby:2.3~https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completed
    And I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
      | incremental | true             |
    Then the step should succeed
    And the "ruby-hello-world-2" build completed
    When I run the :logs client command with:
      | resource_name | bc/ruby-hello-world |
    Then the step should succeed
    And the output should contain:
      | save-artifacts: No such file or directory|
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
      | incremental | false            |
    Then the step should succeed
    And the "ruby-hello-world-3" build completed
    When I run the :logs client command with:
      | resource_name | build/ruby-sample-build-3 |
    Then the output should not contain:
      | save-artifacts: No such file or directory |

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
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/application-template-stibuild.json |
    Then the step should succeed
    And the output should match:
      | Access your application via route 'route-edge[-a-zA-Z0-9_.]+' |

  # @author wewang@redhat.com
  # @case_id OCP-10940
  @admin
  @destructive
  Scenario: Do incremental builds for sti-build after configure BuildDefaults incredentails true
    Given I have a project
    And master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        BuildDefaults:
          configuration:
            apiVersion: v1
            kind: BuildDefaultsConfig
            sourceStrategyDefaults:
              incremental: true 
    """
    Given the master service is restarted on all master nodes
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/build/ruby22rhel7-template-sti.json |
    Then the step should succeed
    And the "ruby22-sample-build-1" build completed
    When I run the :start_build client command with:
      | buildconfig | ruby22-sample-build |
    Then the step should succeed
    And the "ruby22-sample-build-2" build completed 
    When I run the :logs client command with:
      | resource_name | bc/ruby22-sample-build |
    Then the output should contain:
      | save-artifacts: No such file or directory |
    When I run the :delete client command with:
      | all_no_dash |  |
      | all         |  |
    Then the step should succeed
    Given I obtain test data file "build/application-template-stibuild_incremental_true.json"
    And I replace lines in "application-template-stibuild_incremental_true.json":
      | "incremental": true, ||
    When I run the :new_app client command with:
      | file | application-template-stibuild_incremental_true.json | 
    Then the step should succeed
    And the "ruby-sample-build-1" build completed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    And the "ruby-sample-build-2" build completed
    When I run the :logs client command with:
      | resource_name | bc/ruby-sample-build |
    Then the output should contain:
      | Restoring artifacts |

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
    When I run the :new_app client command with:
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
    When I run the :new_app client command with:
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
  # @case_id OCP-19632
  @admin
  @destructive
  Scenario: Container ENV proxy vars should be same with master config when BUILD_LOGLEVEL=5 used in build
    Given the master version >= "3.10"
    When I have a project
    And I have a proxy configured in the project
    Given master config is merged with the following hash:                                                
    """
    admissionConfig:
      pluginConfig:
        BuildDefaults:
          configuration:
            apiVersion: v1
            kind: BuildDefaultsConfig
            gitHTTPProxy: http://<%= cb.proxy_ip %>:<%= cb.proxy_port %>
            gitHTTPSProxy: http://<%= cb.proxy_ip %>:<%= cb.proxy_port %>
            env:
            - name: HTTP_PROXY
              value: http://<%= cb.proxy_ip %>:<%= cb.proxy_port %>
            - name: HTTPS_PROXY
              value: http://<%= cb.proxy_ip %>:<%= cb.proxy_port %>
            - name: CUSTOM_VAR
              value: custom_value
    """
    Given the master service is restarted on all master nodes                    
    When I run the :new_app client command with:
      | app_repo | openshift/ruby:2.3~https://github.com/openshift/ruby-hello-world |
      | env      | BUILD_LOGLEVEL=5                                                 |
    Then the step should succeed
    And the "ruby-hello-world-1" build completed
    Given 1 pods become ready with labels:
      | app=ruby-hello-world |
    When I execute on the pod:
      | bash              |
      | -c                |
      | env  \| grep HTTP |
    Then the output should contain:
      | HTTP_PROXY=http://<%= cb.proxy_ip %>:<%= cb.proxy_port %>  | 
      | HTTPS_PROXY=http://<%= cb.proxy_ip %>:<%= cb.proxy_port %> |

  # @author wewang@redhat.com
  # @case_id OCP-20999
  @admin
  Scenario: Build update that sets phase status failed should contain log snippet data
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    And the "ruby-hello-world-1" build completed
    When I run the :set_build_hook client command with:
      | buildconfig | bc/ruby-hello-world    |
      | post_commit | true                   |
      | script      | bundle exec rake1 test |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    And the "ruby-hello-world-2" build failed
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
    Then the output should contain "logSnippet"

  # @author wewang@redhat.com
  # @case_id OCP-23174
  Scenario: Image source extraction w/ symlink should success when running a build	
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/build/OCP-23174/symlink-rel-both.yaml |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | symlink-rel-both |
    Then the step should succeed
    And the "symlink-rel-both-1" build completed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/build/OCP-23174/symlink-rel-link.yaml |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | symlink-rel-link |
    Then the step should succeed
    And the "symlink-rel-link-1" build failed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/build/OCP-23174/symlink-abs-both.yaml |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | symlink-abs-both |
    Then the step should succeed
    And the "symlink-abs-both-1" build failed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/build/OCP-23174/symlink-abs-link.yaml |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | symlink-abs-link |
    Then the step should succeed
    And the "symlink-abs-link-1" build failed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/build/OCP-23174/symlink-rel-single.yaml |
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
    When I run the :new_app client command with:
      | app_repo | <%= BushSlicer::HOME %>/features/tierN/testdata/build/OCP-18926/paused-build.json |
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
