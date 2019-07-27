Feature: stibuild.feature
  # @author haowang@redhat.com
  # @case_id OCP-11464
  @smoke
  Scenario: STI build with SourceURI and context dir
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/python-27-rhel7-context-stibuild.json |
    Then the step should succeed
    And the "python-sample-build-1" build was created
    And the "python-sample-build-1" build completed

  # @author wzheng@redhat.com
  # @case_id OCP-11470
  Scenario: Add ENV to STIStrategy buildConfig when do sti build
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-env-sti.json |
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
    And I save the output to file>bc.json
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
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/stibuild-configchange.json |
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
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/python-27-rhel7-errordir-stibuild.json |
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
      | app=ruby-hello-world |
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
      | app=ruby-hello-world |
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
    When I run the :describe client command with:
      | resource | build     |
      | name     | ruby-ex-1 |
    Then the output should match:
      | From Image:[^\\n]*@sha256 |

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
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json |
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
      | app_repo | openshift/ruby:2.3~https://github.com/openshift/ruby-hello-world.git |
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

  # @wewang@redhat.com
  # @case_id OCP-15974
  Scenario: Create an application with no host value in template
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/application-template-stibuild.json |
    Then the step should succeed
    And the output should match:
      | Access your application via route 'route-edge[-a-zA-Z0-9_.]+' |

  # @wewang@redhat.com
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
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json |
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
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/application-template-stibuild_incremental_true.json"
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

  # @wewang@redhat.com
  # @case_id OCP-15506
  Scenario: Create a build configuration based on a private remote git repository
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
      | app_repo      | openshift/ruby:2.3~https://github.com/openshift/ruby-hello-world |
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
      | app_repo     | openshift/ruby:2.3~<%= cb.git_repo %> |
      | source_secret| mysecret                              | 
    Then the step should succeed
    And the "sample-1" build was created
    And the "sample-1" build completed

  # @wewang@redhat.com
  # @case_id OCP-15507
  Scenario: Creates a new application based on the source code in a private remote repository
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
    When I run the :new_app client command with:
      | app_repo      | openshift/ruby:2.3~https://github.com/openshift/ruby-hello-world |
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
      | app_repo      | openshift/ruby:2.3~https://github.com/openshift/ruby-hello-world |
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
      | app_repo     | openshift/ruby:2.3~<%= cb.git_repo %> |
      | source_secret| mysecret                              |
    Then the step should succeed
    And the "sample-1" build was created
    And the "sample-1" build completed

  # @wewang@redhat.com
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

  # @wewang@redhat.com
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
    And I run the logs: client command with:
      | pod | <%= cb.pod %> |
    Then the output should contain "logSnippet"
    """
