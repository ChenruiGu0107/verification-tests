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
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby20rhel7-env-sti.json |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    Given I wait for the "frontend" service to become ready
    When I run the :env client command with:
      | resource | pods |
      | list     | true |
      | all      | true |
    Then the step should succeed
    And the output should contain:
      | {"name":"DISABLE_ASSET_COMPILATION","value":"true"} |
    When I get project bc named "ruby-sample-build" as JSON
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
    Given I wait for the "frontend" service to become ready
    When I run the :env client command with:
      | resource | pods |
      | list     | true |
      | all      | true |
    Then the step should succeed
    And the output should contain:
      | {"name":"DISABLE_ASSET_COMPILATION","value":"1"} |

  # @author haowang@redhat.com
  # @case_id OCP-11099
  Scenario: STI build with invalid context dir
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/python-27-rhel7-errordir-stibuild.json |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | python-sample-build |
    And the "python-sample-build-1" build was created
    And the "python-sample-build-1" build failed
    When I run the :get client command with:
      | resource | build |
    Then the output should contain:
      | InvalidContextDirectory |

  # @author wzheng@redhat.com
  # @case_id OCP-9575
  Scenario: Build invoked once buildconfig is created when there is no imagechangetrigger in buildconfig
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/stibuild-configchange.json |
    Then the step should succeed
    And the "php-sample-build-1" build was created
    And the "php-sample-build-1" build completed
    When I expose the "frontend" service
    Then I wait for a web server to become available via the "frontend" route
    And the output should contain:
      | Hello World!|
    When I run the :describe client command with:
      | resource | build              |
      | name     | php-sample-build-1 |
    Then the output should contain:
      | Build configuration change |

  # @author xiuwang@redhat.com
  @admin
  Scenario Outline: Trigger s2i/docker/custom build using additional imagestream
    Given I have a project
    And I run the :new_app client command with:
      | file | <template> |
    Then the step should succeed
    And the "sample-build-1" build was created
    # must run this step prior to calling the step 'I run commands on the host'
    And I select a random node's host
    Given default registry service ip is stored in the :integrated_reg_ip clipboard
    When I run commands on the host:
      | docker login -u <%= user.name %> -p <%= user.get_bearer_token.token %> -e dnm@redmail.com <%= cb.integrated_reg_ip %> |
    Then the step should succeed
    When I run commands on the host:
      | docker pull docker.io/docker:latest |
    Then the step should succeed
    And I run commands on the host:
      | docker tag docker.io/docker <%= cb.integrated_reg_ip %>/<%= project.name %>/myimage|
    Then the step should succeed
    When I run commands on the host:
      | docker push <%= cb.integrated_reg_ip %>/<%= project.name %>/myimage|
    Then the step should succeed
    And the "sample-build-2" build was created
    When I get project bc named "sample-build" as YAML
    Then the step should succeed
    And the output should contain:
      |lastTriggeredImageID: <%= cb.integrated_reg_ip %>/<%= project.name %>/myimage|
    When I run the :start_build client command with:
      | buildconfig | sample-build |
    Then the step should succeed
    And the "sample-build-3" build was created
    When I get project builds
    Then the step should succeed
    And the output should not contain "sample-build-4"

    Examples:
      |template|
      |https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc498848/tc498848-s2i.json   | # @case_id OCP-12041
      |https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc498847/tc498847-docker.json| # @case_id OCP-11911
      |https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc498846/tc498846-custom.json| # @case_id OCP-11739

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
      | app_repo     | https://github.com/openshift/ruby-hello-world#refs/pull/60/head | 
      | image_stream | ruby:latest                                                     |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completed
    And a pod becomes ready with labels:
      | app=ruby-hello-world |
    When I expose the "ruby-hello-world" service
    Then I wait for a web server to become available via the "ruby-hello-world" route
    And  the output should contain "Welcome to an OpenShift v3 Demo App! - QE Test"
    When I run the :patch client command with:
      | resource      | buildconfig                                        |
      | resource_name | ruby-hello-world                                   |
      | p | {"spec":{"source":{"git":{"ref":"refs/pull/60/head:master"}}}} | 
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
      | ruby-hello-world-2.*Git@refs/pull/60/head:master.*FetchSourceFailed |
      | ruby-hello-world-3.*Git@refs/pull/100000/head.*FetchSourceFailed    |

  # @author wzheng@redhat.com
  # @case_id OCP-9550
  Scenario: Provide the built image reference as part of the build status
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://github.com/openshift/ruby-ex |
      | image_stream | ruby |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | build     |
      | name     | ruby-ex-1 |
    Then the output should contain:
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
    Then the step should succeed
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
