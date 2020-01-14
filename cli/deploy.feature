Feature: deployment related features

  # @author xxing@redhat.com
  # @case_id OCP-11072
  Scenario: CLI rollback dry run
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    When I run the :replace client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/updatev1.json |
    Then the step should succeed
    When I get project dc named "hooks"
    Then the output should match:
      | hooks.*|
    When I run the :rollback client command with:
      | deployment_name | hooks-1 |
      | dry_run         |         |
    Then the output should match:
      | .*rolled back to hooks-1 \(dry run\) |
    When I run the :rollback client command with:
      | deployment_name         | hooks-1 |
      | dry_run                 |         |
      | change_scaling_settings |         |
      | change_strategy         |         |
      | change_triggers         |         |
    Then the output should match:
      | .*rolled back to hooks-1 \(dry run\) |

  # @author xxing@redhat.com
  # @case_id OCP-12034
  Scenario: Can't stop a deployment in Complete status
    Given I have a project
    When I run the :new_app client command with:
      | docker_image   | <%= project_docker_repo %>openshift/deployment-example |
    Then the step should succeed
    # Wait till the deploy complete
    And the pod named "deployment-example-1-deploy" becomes ready
    Given I wait for the pod named "deployment-example-1-deploy" to die
    When  I run the :describe client command with:
      | resource | dc                 |
      | name     | deployment-example |
    Then the output should match:
      | Status:\\s+Complete       |
      | Pods Status:\\s+1 Running |
    When I run the :rollout_cancel client command with:
      | resource | deploymentConfig   |
      | name     | deployment-example |
    Then the output should contain "No rollout is in progress"
    When I run the :describe client command with:
      | resource | dc                 |
      | name     | deployment-example |
    Then the output should match:
      | Status:\\s+Complete |
    When I run the :rollout_retry client command with:
      | resource | deploymentConfig   |
      | name     | deployment-example |
    Then the output should contain:
      |  #1 is complete                |
      | You can start a new deployment |

  # @author xxing@redhat.com
  # @case_id OCP-12623
  Scenario: Negative test for rollback
    Given I have a project
    When I run the :rollback client command with:
      | deployment_name | non-exist |
    Then the output should contain:
      | error: non-exist |
    When I run the :rollback client command with:
      | deployment_name         | non-exist |
      | change_strategy         |           |
      | change_triggers         |           |
      | change_scaling_settings |           |
    Then the output should contain:
      | error: non-exist |
    When I run the :rollback client command with:
      | deployment_name         | non-exist |
      | change_strategy         |           |
      | change_triggers         |           |
      | change_scaling_settings |           |
      | dry_run                 |           |
    Then the output should contain:
      | error: non-exist |
    When I run the :rollback client command with:
      | deployment_name         | non-exist |
      | output                  | yaml      |
      | change_strategy         |           |
      | change_triggers         |           |
      | change_scaling_settings |           |
    Then the output should contain:
      | error: non-exist |

  # @author pruan@redhat.com
  # @case_id OCP-12536
  Scenario: oc deploy negative test
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | aosqe/hello-openshift |
      | name     | hooks                  |
    Then the step should succeed
    When I run the :rollout_latest client command with:
      | resource | notreal |
    Then the step should fail
    Then the output should match:
      | Error\\s+.*\\s+"notreal" not found |
    Given I wait until the status of deployment "hooks" becomes :complete
    When I run the :rollout_retry client command with:
      | resource | deploymentConfig   |
      | name     | hooks              |
    Then the step should fail
    And the output should contain:
      | only failed deployments can be retried |
    When I run the :rollout_latest client command with:
      | resource | hooks |
    Then I wait until the status of deployment "hooks" becomes :complete

  # @author pruan@redhat.com
  # @case_id OCP-12402
  Scenario: Negative test for deployment history
    Given I have a project
    When I run the :describe client command with:
      | resource | dc         |
      | name     | no-such-dc |
    Then the step should fail
    And the output should match:
      | Error\\s+.*\\s+"no-such-dc" not found |
    When I run the :describe client command with:
      | resource | dc              |
      | name     | docker-registry |
    Then the step should fail
    And the output should match:
      | Error\\s+.*\\s+"docker-registry" not found |

  # @author pruan@redhat.com
  # @case_id 487644
  Scenario: New deployment will be created once the old one is complete - single deployment
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/sleepv1.json |
    # simulate 'oc edit'
    When I get project dc named "hooks" as YAML
    And I save the output to file>hooks.yaml
    And I replace lines in "hooks.yaml":
      | 200              | 10               |
      | latestVersion: 1 | latestVersion: 2 |
    When I run the :replace client command with:
      | f | hooks.yaml |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :running
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the step should succeed
    And the output should contain:
      | hooks #2 deployment pending on update |
      | hooks #1 deployment running           |
    And I wait until the status of deployment "hooks" becomes :complete
    And I run the :describe client command with:
      | resource | dc    |
      | name     | hooks |
    Then the step should succeed
    And the output should match:
      | Latest Version:\\s+2 |
      | Deployment\\s+#2\\s+ |
      | Status:\\s+Complete  |
      | Deployment #1:       |
      | Status:\\s+Complete  |


  # @author pruan@redhat.com
  # @case_id 484483
  Scenario: Deployment succeed when running time is less than ActiveDeadlineSeconds
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    # simulate 'oc edit'
    When the pod named "hooks-1-deploy" becomes ready
    When I get project pod named "hooks-1-deploy" as YAML
    And I save the output to file>hooks.yaml
   And I replace lines in "hooks.yaml":
      | activeDeadlineSeconds: 21600 | activeDeadlineSeconds: 300 |
    When I run the :replace client command with:
      | f | hooks.yaml |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=hooks-1     |
      | deploymentconfig=hooks |

  # @author pruan@redhat.com
  # @case_id OCP-10633
  Scenario: Deployment is automatically stopped when running time is more than ActiveDeadlineSeconds
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/sleepv1.json|
    # simulate 'oc edit'
    When the pod named "hooks-1-deploy" becomes ready
    When I get project pod named "hooks-1-deploy" as YAML
    And I save the output to file>hooks.yaml
    And I replace lines in "hooks.yaml":
      | activeDeadlineSeconds: 21600 | activeDeadlineSeconds: 2 |
    When I run the :replace client command with:
      | f | hooks.yaml |
    Then the step should succeed
    When I run the :rollout_status client command with:
      | resource | deploymentConfig |
      | name     | hooks            |
    Then the output should match:
      | failed progressing |

  # @author pruan@redhat.com
  # @case_id 490716
  Scenario: Make a new deployment by using a invalid LatestVersion
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            | true  |
    And I wait until the status of deployment "hooks" becomes :complete
    And I replace resource "dc" named "hooks" saving edit to "tmp_out.yaml":
      | latestVersion: 2 | latestVersion: -1 |
    Then the step should fail
    When I run the :get client command with:
      | resource      | dc    |
      | resource_name | hooks |
      | template      | {{.status.latestVersion}} |
    Then the output should match "2"
    And I replace resource "dc" named "hooks":
      | latestVersion: 2 | latestVersion: 0 |
    Then the step should fail
    When I run the :get client command with:
      | resource      | dc                        |
      | resource_name | hooks                     |
      | template      | {{.status.latestVersion}} |
    Then the output should match "2"
    And I replace resource "dc" named "hooks":
      | latestVersion: 2 | latestVersion: 5 |
    Then the step should fail
    When I run the :get client command with:
      | resource      | dc                        |
      | resource_name | hooks                     |
      | template      | {{.status.latestVersion}} |
    Then the output should match "2"

  # @author pruan@redhat.com
  # @case_id OCP-10635
  Scenario: Deployment will be failed if deployer pod no longer exists
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    # deployment 1
    And I wait until the status of deployment "hooks" becomes :complete
    # deployment 2
    When I run the :rollout_latest client command with:
      | resource | hooks |
    And I wait until the status of deployment "hooks" becomes :complete
    # deployment 3
    When I run the :rollout_latest client command with:
      | resource | hooks |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    Then I run the :describe client command with:
      | resource | dc    |
      | name     | hooks |
    And the output by order should contain:
      | Deployment #3 (latest):   |
      |  Status:		Complete      |
      | Deployment #2:            |
      |  Status:		Complete      |
      | Deployment #1:            |
      | Status:		Complete        |
    And I replace resource "rc" named "hooks-2":
      | Complete | Running |
    Then the step should succeed
    And I replace resource "rc" named "hooks-3":
      | Complete | Pending |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :rollout_latest client command with:
      | resource | hooks |
    Then the step should succeed
    """
    And I wait until the status of deployment "hooks" becomes :complete
    Then I run the :describe client command with:
      | resource | dc    |
      | name     | hooks |
    And the output by order should contain:
      | Deployment #4 (latest): |
      | Status:		Complete      |
      | Deployment #3:          |
      | Status:		Failed        |
      | Deployment #2:          |
      | Status:		Failed        |

    # This deviate form the testplan a little in that we are not doing more than one deploy, which should be sufficient since we are checking two deployments already (while the testcase called for 5)

  # @author cryan@redhat.com
  # @case_id OCP-11131
  @admin
  Scenario: Check the default option value for command oadm prune deployments
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | aosqe/hello-openshift |
      | name     | database              |
    Then the step should succeed
    Given I wait for the pod named "database-1-deploy" to die
    When I run the :rollout_latest client command with:
      | resource | database |
    Then the step should succeed
    Given I wait for the pod named "database-2-deploy" to die
    When I run the :rollout_latest client command with:
      | resource | database |
    Then the step should succeed
    Given I wait for the pod named "database-3-deploy" to die
    When I run the :rollout_latest client command with:
      | resource | database |
    Then the step should succeed
    Given I wait for the pod named "database-4-deploy" to die
    When I run the :rollout_latest client command with:
      | resource | database |
    Then the step should succeed
    Given I wait for the pod named "database-5-deploy" to die
    When I run the :rollout_latest client command with:
      | resource | database |
    Then the step should succeed
    Given I wait for the pod named "database-6-deploy" to die
    When I run the :rollout_latest client command with:
      | resource | database |
    Then the step should succeed
    Given I wait for the pod named "database-7-deploy" to die
    When I run the :rollout_latest client command with:
      | resource | database |
    Then the step should succeed
    Given I wait for the pod named "database-8-deploy" to die
    When I run the :rollout_latest client command with:
      | resource | database |
    Then the step should succeed
    Given I wait for the pod named "database-9-deploy" to die
    When I run the :get client command with:
      | resource | rc                  |
      | n        | <%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | database-1 |
      | database-9 |
    When I run the :oadm_prune_deployments client command with:
      |h||
    Then the step should succeed
    And the output should contain "completed and failed deployments"
    Given 60 seconds have passed
    When I run the :oadm_prune_deployments admin command with:
      | keep_younger_than | 1m |
    Then the step should succeed
    And the output should match:
      |NAMESPACE\\s+NAME                   |
      |<%= project.name %>\\s+database-\\d+|
    When I run the :oadm_prune_deployments admin command with:
      | confirm | false |
    Then the step should succeed
    And the output should not match:
      |<%= project.name %>\\s+database-\\d+|

  # @author pruan@redhat.com
  # @case_id OCP-12452, OCP-12460
  Scenario Outline: Failure handler of pre-post deployment hook
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/<file_name>|
    Then the step should succeed
    When the pod named "<pod_name>" becomes present
    And I wait up to 300 seconds for the steps to pass:

    """
      When I get project pod named "<pod_name>" as JSON
      Then the expression should be true> @result[:parsed]['status']['containerStatuses'][0]['restartCount'] > 1
    """
    Examples:
      | file_name | pod_name          |
      | pre.json  | hooks-1-hook-pre  |
      | post.json | hooks-1-hook-post |

  # @author cryan@redhat.com
  # @case_id OCP-9768
  Scenario: Could edit the deployer pod during deployment
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc515805/tc515805.json |
    Then the step should succeed
    Given the pod named "database-1-deploy" becomes ready
    When I replace resource "pod" named "database-1-deploy":
      | activeDeadlineSeconds: 21600 | activeDeadlineSeconds: 55 |
    Then the step should succeed
    Given the pod named "database-1-deploy" status becomes :failed
    When I get project pods
    Then the output should contain "DeadlineExceeded"

  # @author yinzhou@redhat.com
  # @case_id OCP-11203
  Scenario: deployment hook volume inheritance -- that volume names which are not found
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/tc510607/hooks-unexist-volume.json |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    When I get project pods
    Then the output should contain:
      | NAME            |
      | hooks-1-hook-pre|
    """

  # @author yinzhou@redhat.com
  # @case_id OCP-12622
  Scenario: Trigger info is retained for deployment caused by config changes
    Given I have a project
    When I run the :new_app client command with:
      | docker_image   | <%= project_docker_repo %>openshift/deployment-example |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete
    And I replace resource "dc" named "deployment-example":
      | terminationGracePeriodSeconds: 30 | terminationGracePeriodSeconds: 36 |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete
    When I get project dc named "deployment-example" as YAML
    Then the output by order should match:
      | terminationGracePeriodSeconds: 36 |
      | causes:                           |
      | - type: ConfigChange              |


  # @author yinzhou@redhat.com
  # @case_id OCP-9829
  Scenario: Check the deployments in a completed state on test deployment configs
    Given I have a project
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/test-deployment.json |
    Then the step should succeed
    And I run the :logs client command with:
      | f | true |
      | resource_name | dc/hooks |
    Then the output should contain:
      | Scaling hooks-1 to 1 |
    And I wait until the status of deployment "hooks" becomes :complete
    When I get project rc named "hooks-1" as YAML
    Then the output by order should match:
      | phase: Complete |
      | status:         |
      | replicas: 0     |

  # @author yinzhou@redhat.com
  # @case_id OCP-9830
  Scenario: Check the deployments in a failed state on test deployment configs
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | aosqe/hello-openshift |
      | name     | hooks                 |
      | as_test  | true                  |
    Then the step should succeed
    #And I run the :create client command with:
    #  | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/test-deployment.json |
    #Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :running
    Given I successfully patch resource "pod/hooks-1-deploy" with:
      | {"spec":{"activeDeadlineSeconds":3}} |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :rollout_status client command with:
      | resource | deploymentConfig |
      | name     | hooks            |
    Then the output should match "failed"
    """
    When I get project rc named "hooks-1" as YAML
    Then the output by order should match:
      | phase: Failed |
      | status:       |
      | replicas: 0   |

  # @author pruan@redhat.com
  # @case_id OCP-9831
  Scenario: Scale the deployments will failed on test deployment config
    Given I have a project
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/tc518650/test.json |
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :complete
    Then I run the :scale client command with:
      | resource | deploymentconfig |
      | name     | hooks            |
      | replicas | 2                |
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :complete
    And I wait until number of replicas match "0" for replicationController "hooks-1"

  # @author yinzhou@redhat.com
  # @case_id OCP-10850
  Scenario: Automatic set to false with ConfigChangeController on the DeploymentConfig
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    And I replace lines in "application-template-stibuild.json":
      |"automatic": true|"automatic": false|
    When I process and create "application-template-stibuild.json"
    Given the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    And I wait until the status of deployment "frontend" becomes :complete
    When I get project dc named "frontend" as JSON
    Then the output should contain:
      | lastTriggeredImage |
    And evaluation of `@result[:parsed]['spec']['triggers'][0]['imageChangeParams']['lastTriggeredImage']` is stored in the :imagestreamimage clipboard
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given the "ruby-sample-build-2" build finishes
    When I get project imagestream named "origin-ruby-sample" as JSON
    And evaluation of `@result[:parsed]['status']['tags'][0]['items']` is stored in the :imagestreamitems clipboard
    And the expression should be true> cb.imagestreamitems.length == 2
    When I get project dc named "frontend" as JSON
    Then the output should contain:
      | "latestVersion": 1 |
    And evaluation of `@result[:parsed]['spec']['triggers'][0]['imageChangeParams']['lastTriggeredImage']` is stored in the :sed_imagestreamimage clipboard
    And the expression should be true> cb.imagestreamimage == cb.sed_imagestreamimage

  # @author yinzhou@redhat.com
  # @case_id OCP-11586
  Scenario: Automatic set to true with ConfigChangeController on the DeploymentConfig
    Given I have a project
    When I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-11384/application-template-stibuild.json"
    Given the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    And I wait until the status of deployment "frontend" becomes :complete
    When I get project dc named "frontend" as JSON
    Then the output should contain:
      | lastTriggeredImage |
    And evaluation of `@result[:parsed]['spec']['triggers'][0]['imageChangeParams']['lastTriggeredImage']` is stored in the :imagestreamimage clipboard
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given the "ruby-sample-build-2" build finishes
    When I get project imagestream named "origin-ruby-sample" as JSON
    And evaluation of `@result[:parsed]['status']['tags'][0]['items']` is stored in the :imagestreamitems clipboard
    And the expression should be true> cb.imagestreamitems.length == 2
    When I get project dc named "frontend" as JSON
    Then the output should contain:
      | "latestVersion": 2 |
    And evaluation of `@result[:parsed]['spec']['triggers'][0]['imageChangeParams']['lastTriggeredImage']` is stored in the :sed_imagestreamimage clipboard
    And the expression should be true> cb.imagestreamimage != cb.sed_imagestreamimage

  # @author yinzhou@redhat.com
  # @case_id OCP-11489
  Scenario: app deploy successfully with correct registry credentials
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | centos/ruby-25-centos7~https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    Given the "ruby-hello-world-1" build was created
    Given the "ruby-hello-world-1" build completed
    Given I wait for the "ruby-hello-world" service to become ready up to 300 seconds
    When I expose the "ruby-hello-world" service
    Then I wait for a web server to become available via the "ruby-hello-world" route
    And the output should contain "Demo App!"
    When I git clone the repo "https://github.com/openshift/ruby-hello-world" to "dummy"
    Given I replace lines in "dummy/views/main.erb":
      | Demo App | zhouying |
    Then the step should succeed
    And I commit all changes in repo "dummy" with message "test"
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
      | from_dir    | dummy            |
    Then the step should succeed
    Given the "ruby-hello-world-2" build completed
    And I wait until the status of deployment "ruby-hello-world" becomes :complete
    Then I wait for a web server to become available via the "ruby-hello-world" route
    And the output should contain "zhouying"
    When I run the :rollback client command with:
      | deployment_name | ruby-hello-world |
      | to_version      | 1                |
    Then the step should succeed
    And I wait until the status of deployment "ruby-hello-world" becomes :complete
    Then I wait for a web server to become available via the "ruby-hello-world" route
    And the output should contain "Demo App!"

  # @author yinzhou@redhat.com
  # @case_id OCP-11790
  Scenario: Automatic set to true without ConfigChangeController on the DeploymentConfig
    Given I have a project
    Given I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/build-deploy-without-configchange.json"
    Given the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    And I wait for the steps to pass:
    """
    When I get project dc named "frontend" as JSON
    Then the output should contain:
      | lastTriggeredImage     |
      | "latestVersion": 1     |
    """
    And evaluation of `@result[:parsed]['spec']['triggers'][0]['imageChangeParams']['lastTriggeredImage']` is stored in the :imagestreamimage clipboard
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given the "ruby-sample-build-2" build finishes
    When I get project imagestream named "origin-ruby-sample" as JSON
    And evaluation of `@result[:parsed]['status']['tags'][0]['items']` is stored in the :imagestreamitems clipboard
    And the expression should be true> cb.imagestreamitems.length == 2
    When I get project dc named "frontend" as JSON
    Then the output should contain:
      | "latestVersion": 2 |
    And evaluation of `@result[:parsed]['spec']['triggers'][0]['imageChangeParams']['lastTriggeredImage']` is stored in the :sed_imagestreamimage clipboard
    And the expression should be true> cb.imagestreamimage != cb.sed_imagestreamimage

  # @author yinzhou@redhat.com
  # @case_id OCP-11281
  Scenario: Automatic set to false without ConfigChangeController on the DeploymentConfig
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/build-deploy-without-configchange.json"
    And I replace lines in "build-deploy-without-configchange.json":
      | "automatic": true | "automatic": false |
    When I process and create "build-deploy-without-configchange.json"
    Given the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    And I wait for the steps to pass:
    """
    When I get project dc named "frontend" as JSON
    Then the output should contain:
      | lastTriggeredImage |
    And the output should not contain:
      | "latestVersion": 1 |
    """
    And evaluation of `@result[:parsed]['spec']['triggers'][0]['imageChangeParams']['lastTriggeredImage']` is stored in the :imagestreamimage clipboard
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given the "ruby-sample-build-2" build finishes
    When I get project imagestream named "origin-ruby-sample" as JSON
    And evaluation of `@result[:parsed]['status']['tags'][0]['items']` is stored in the :imagestreamitems clipboard
    And the expression should be true> cb.imagestreamitems.length == 2
    When I get project dc named "frontend" as JSON
    Then the output should not contain:
      | "latestVersion": 1 |
    And evaluation of `@result[:parsed]['spec']['triggers'][0]['imageChangeParams']['lastTriggeredImage']` is stored in the :sed_imagestreamimage clipboard
    And the expression should be true> cb.imagestreamimage == cb.sed_imagestreamimage

  # @author mcurlej@redhat.com
  # @case_id OCP-11611
  Scenario: Could revert an application back to a previous deployment by 'oc rollout undo' command
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :set_env client command with:
      | resource | dc/hooks |
      | e        | TEST=123 |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :set_env client command with:
      | resource | dc/hooks |
      | list     | true     |
    Then the step should succeed
    And the output should contain "TEST=123"
    When I run the :rollout_undo client command with:
      | resource      | dc    |
      | resource_name | hooks |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :set_env client command with:
      | resource | dc/hooks |
      | list     | true     |
    Then the step should succeed
    And the output should not contain "TEST=123"
    When I run the :rollout_undo client command with:
      | resource      | dc    |
      | resource_name | hooks |
      | to_revision   | 2     |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :set_env client command with:
      | resource | dc/hooks |
      | list     | true     |
    Then the step should succeed
    And the output should contain "TEST=123"

  # @author mcurlej@redhat.com
  # @case_id OCP-11313
  Scenario: Check the status for deployment configs
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :get client command with:
      | resource      | dc    |
      | resource_name | hooks |
      | o             | json  |
    Then the step should succeed
    And evaluation of `@result[:parsed]['metadata']['generation']` is stored in the :prev_generation clipboard
    And evaluation of `@result[:parsed]['status']['observedGeneration']` is stored in the :prev_observed_generation clipboard
    When I run the :set_env client command with:
      | resource | dc/hooks |
      | e        | TEST=1   |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :get client command with:
      | resource      | dc    |
      | resource_name | hooks |
      | o             | json  |
    Then the step should succeed
    And the expression should be true> @result[:parsed]['metadata']['generation'] - cb.prev_generation >= 1
    And the expression should be true> @result[:parsed]['status']['observedGeneration'] - cb.prev_observed_generation >= 1
    And the expression should be true> @result[:parsed]['status']['observedGeneration'] >= @result[:parsed]['metadata']['generation']

  # @author yinzhou@redhat.com
  # @case_id OCP-10916
  Scenario: Support endpoints of Deployment in OpenShift
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/extensions/deployment.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource | deployment |
    Then the step should succeed
    And the output should contain:
      | hello-openshift |
    When I run the :patch client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"hello-openshift","ports":[{"containerPort":80}]}]}}}} |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | deployment                |
      | resource_name | hello-openshift           |
      | template      | {{.metadata.annotations}} |
    Then the step should succeed
    And the output should contain:
      | deployment.kubernetes.io/revision:2 |
    When I run the :delete client command with:
      | object_type       | deployment      |
      | object_name_or_id | hello-openshift |
    Then the step should succeed
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I get project pods
    Then the step should succeed
    And the output should not contain "Terminating"
    And the output should not contain "Running"
    """
    When I get project rs
    Then the step should succeed
    And the output should not contain "hello-openshift.*"

  # @author mcurlej@redhat.com
  # @case_id OCP-12079
  Scenario: View the history of rollouts for a specific deployment config
    Given I have a project
    When I run the :new_app client command with:
      | docker_image   | <%= project_docker_repo %>openshift/deployment-example |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete
    When I run the :set_env client command with:
      | resource | dc/deployment-example |
      | e        | TEST=1                |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete
    When I run the :rollout_history client command with:
      | resource      | dc                 |
      | resource_name | deployment-example |
    Then the step should succeed
    And the output should contain:
      | image change  |
      | config change |
    When I run the :rollout_history client command with:
      | resource      | dc                 |
      | resource_name | deployment-example |
      | revision      | 2                  |
    Then the step should succeed
    And the output should match:
      | revision     |
      | Labels:      |
      | Containers:  |
      | Annotations: |

  # @author pruan@redhat.com
  # @case_id OCP-11973
  Scenario: Support MinReadySeconds in DC
    Given I have a project
    And evaluation of `60` is stored in the :min_ready_seconds clipboard
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/tc532415/min_ready.yaml
    Then the step should succeed
    And 20 seconds have passed
    And the expression should be true> dc('minreadytest').unavailable_replicas == 2
    And I wait until the status of deployment "minreadytest" becomes :complete
    And the expression should be true> dc('minreadytest').available_replicas(cached: false) == 2

  # @author mcurlej@redhat.com
  # @case_id OCP-11812
  Scenario: Pausing and Resuming a Deployment
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    When I run the :rollout_pause client command with:
      | resource | dc    |
      | name     | hooks |
    Then the step should succeed
    When I get project dc named "hooks" as YAML
    Then the step should succeed
    And the output should match "paused:\s+?true"
    When I run the :set_env client command with:
      | resource | dc/hooks |
      | e        | TEST=123 |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | rc/hooks-1 |
      | list     | true       |
    Then the step should succeed
    And the output should not contain "TEST=123"
    When I get project rc as YAML
    Then the step should succeed
    # Check if that no new rc was created if the dc is paused
    And the output should not contain "hooks-2"
    When I run the :rollout_resume client command with:
      | resource | dc    |
      | name     | hooks |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :set_env client command with:
      | resource | rc/hooks-2 |
      | list     | true       |
    Then the step should succeed
    And the output should contain "TEST=123"


  # @author yinzhou@redhat.com
  # @case_id OCP-9973 OCP-9974
  Scenario Outline: custom deployment for Recreate/Rolling strategy
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/<file> |
    Then the step should succeed
    And I run the :logs client command with:
      | f             | true                 |
      | resource_name | dc/custom-deployment |
    Then the output should contain:
      | Reached 50% |
      | Halfway     |
      | Success     |
      | Finished    |
    Examples:
      | file                 |
      | custom-rolling.yaml  |
      | custom-recreate.yaml |


  # @author yinzhou@redhat.com
  # @case_id OCP-10973
  @admin
  Scenario: Should show deployment conditions correctly
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment-ignores-deployer.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | dc                                       |
      | resource_name | database                                 |
      | template      | {{(index .status.conditions 1).reason }} |
    Then the step should succeed
    And the output should match "NewReplicationControllerCreated"
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/testhook.json |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :get client command with:
      | resource      | dc                                       |
      | resource_name | hooks                                    |
      | template      | {{(index .status.conditions 1).reason }} |
    Then the step should succeed
    And the output should match "NewReplicationControllerAvailable"
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            |       |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When  I run the :deploy client command with:
      | deployment_config | hooks |
      | cancel            |       |
    And I run the :get client command with:
      | resource      | dc                                       |
      | resource_name | hooks                                    |
      | template      | {{(index .status.conditions 1).reason }} |
    Then the step should succeed
    And the output should match "ProgressDeadlineExceeded"
    """
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/myquota.yaml"
    Then the step should succeed
    And I replace lines in "myquota.yaml":
      | replicationcontrollers: "30" | replicationcontrollers: "1" |
    When I run the :create admin command with:
      | f | myquota.yaml        |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            |       |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | dc                                       |
      | resource_name | hooks                                    |
      | template      | {{(index .status.conditions 1).reason }} |
    Then the step should succeed
    And the output should match "ReplicationControllerCreateError"

  # @author yinzhou@redhat.com
  # @case_id OCP-10967
  Scenario: Deployment config with automatic=false in ICT
    #Given the master version >= "3.4"
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | centos/ruby-25-centos7~https://github.com/sclorg/ruby-ex.git |
    Then the step should succeed
    Given I replace resource "dc" named "ruby-ex" saving edit to "ruby-ex.yaml":
      | automatic: true | automatic: false |
    Given the "ruby-ex-1" build was created
    And the "ruby-ex-1" build completed
    And 20 seconds have passed
    When I get project dc named "ruby-ex" as JSON
    And the output should not contain:
      | lastTriggeredImage |
      | "latestVersion": 1 |
    When I run the :rollout_latest client command with:
      | resource | ruby-ex |
    Then the step should succeed
    And I wait until the status of deployment "ruby-ex" becomes :complete
    When I get project imagestream named "ruby-ex" as JSON
    And evaluation of `dc.trigger_by_type(type: 'ImageChange', cached: false).last_image` is stored in the :imagestreamimage clipboard
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    Given the "ruby-ex-2" build finishes
    When I get project imagestream named "ruby-ex" as JSON
    And evaluation of `image_stream('ruby-ex').tag_statuses[0].events` is stored in the :imagestreamitems clipboard
    And the expression should be true> cb.imagestreamitems.length == 2
    When I get project dc named "ruby-ex" as JSON
    Then the output should contain:
      | "latestVersion": 1 |
    And evaluation of `dc.trigger_by_type(type: 'ImageChange', cached: false).last_image` is stored in the :sed_imagestreamimage clipboard
    And the expression should be true> cb.imagestreamimage == cb.sed_imagestreamimage
    When I run the :rollout_latest client command with:
      | resource | ruby-ex |
    Then the step should succeed
    And I wait until the status of deployment "ruby-ex" becomes :complete
    When I get project dc named "ruby-ex" as JSON
    And evaluation of `dc.trigger_by_type(type: 'ImageChange', cached: false).last_image` is stored in the :imagestreamimage3 clipboard
    And the expression should be true> cb.imagestreamimage != cb.imagestreamimage3

  # @author yinzhou@redhat.com
  # @case_id OCP-11834
  Scenario: Paused deployments shouldn't update the image to template
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    When I process and create "application-template-stibuild.json"
    Then the step should succeed
    When I run the :rollout_pause client command with:
      | resource | dc       |
      | name     | frontend |
    Then the step should succeed
    Given the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    When I get project dc named "frontend" as JSON
    Then the output should contain:
      | "availableReplicas": 0 |
      | "latestVersion": 0     |


  # @author yinzhou@redhat.com
  # @case_id OCP-14336
  @admin
  Scenario: Show deployment conditions correctly
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment-ignores-deployer.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | dc                                       |
      | resource_name | database                                 |
      | template      | {{(index .status.conditions 1).reason }} |
    Then the step should succeed
    And the output should match "NewReplicationControllerCreated"
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/testhook.json |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :get client command with:
      | resource      | dc                                       |
      | resource_name | hooks                                    |
      | template      | {{(index .status.conditions 1).reason }} |
    Then the step should succeed
    And the output should match "NewReplicationControllerAvailable"
    When I run the :rollout_latest client command with:
      | resource | hooks |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :rollout_cancel client command with:
      | resource | deploymentConfig   |
      | name     | hooks              |
    And I run the :get client command with:
      | resource      | dc                                       |
      | resource_name | hooks                                    |
      | template      | {{(index .status.conditions 1).reason }} |
    Then the step should succeed
    And the output should match "RolloutCancelled"
    """
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/myquota.yaml"
    Then the step should succeed
    And I replace lines in "myquota.yaml":
      | replicationcontrollers: "30" | replicationcontrollers: "1" |
    When I run the :create admin command with:
      | f | myquota.yaml        |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :rollout_latest client command with:
      | resource | hooks |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | dc                                       |
      | resource_name | hooks                                    |
      | template      | {{(index .status.conditions 1).reason }} |
    Then the step should succeed
    And the output should match "ReplicationControllerCreateError"


  # @author azagayno@redhat.com
  # @case_id OCP-12217
  Scenario: Proportionally scale - Scale up deployment succeed in unpause and pause
    Given I have a project

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/hello-deployment-1.yaml |
    Then the step should succeed

    Given number of replicas of "hello-openshift" deployment becomes:
      | desired   | 10 |
      | current   | 10 |
      | updated   | 10 |
      | available | 10 |

    Given number of replicas of the current replica set for the "hello-openshift" deployment becomes:
      | desired  | 10 |
      | current  | 10 |
      | ready    | 10 |

    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | 20              |
    Then the step should succeed

    Given number of replicas of "hello-openshift" deployment becomes:
      | desired   | 20 |
      | current   | 20 |
      | updated   | 20 |
      | available | 20 |

    Given number of replicas of the current replica set for the "hello-openshift" deployment becomes:
      | desired  | 20 |
      | current  | 20 |
      | ready    | 20 |

    When I run the :patch client command with:
      | resource      | deployment                                                                                                           |
      | resource_name | hello-openshift                                                                                                      |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"hello-openshift","image":"docker.io/aosqe/hello-openshift"}]}}}} |
    Then the step should succeed

    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | 30              |
    Then the step should succeed

    Given number of replicas of "hello-openshift" deployment becomes:
      | desired   | 30 |
      | current   | 30 |
      | updated   | 30 |
      | available | 30 |

    Given number of replicas of the current replica set for the "hello-openshift" deployment becomes:
      | desired  | 30 |
      | current  | 30 |
      | ready    | 30 |

    When I run the :patch client command with:
      | resource      | deployment                                                                                     |
      | resource_name | hello-openshift                                                                                |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"hello-openshift","image":"not-exist"}]}}}} |
    Then the step should succeed

    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | 40              |
    Then the step should succeed

    Given number of replicas of "hello-openshift" deployment becomes:
      | desired   | 40 |
      | current   | 43 |
      | updated   |  7 |
      | available | 36 |

    Given number of replicas of the current replica set for the "hello-openshift" deployment becomes:
      | desired  | 7 |
      | current  | 7 |
      | ready    | 0 |

    When I run the :rollout_pause client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed

    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | 60              |
    Then the step should succeed

    Given number of replicas of "hello-openshift" deployment becomes:
      | desired   | 60 |
      | current   | 63 |
      | updated   | 10 |
      | available | 53 |

    Given number of replicas of the current replica set for the "hello-openshift" deployment becomes:
      | desired  | 10 |
      | current  | 10 |
      | ready    |  0 |

    When I run the :rollout_resume client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed

    Given number of replicas of "hello-openshift" deployment becomes:
      | desired   | 60 |
      | current   | 63 |
      | updated   | 10 |
      | available | 53 |

    Given number of replicas of the current replica set for the "hello-openshift" deployment becomes:
      | desired  | 10 |
      | current  | 10 |
      | ready    |  0 |

  # @author chuyu@redhat.com
  # @case_id OCP-15167
  Scenario: Pod referencing image streams directly
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15167/example-pod.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the output should contain "ErrImagePull"
    """
    Given I ensure "example-pod" pod is deleted
    When I run the :set_image_lookup client command with:
      | image_stream | app |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15167/example-pod.yaml |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | app=example-pod |

  # @author chuyu@redhat.com
  # @case_id OCP-15174
  Scenario: Requesting dereference on an entire object for Pod
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15167/example-pod.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the output should contain "ErrImagePull"
    """
    Given I ensure "example-pod" pod is deleted
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15167/example-pod-annotation.yaml |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | app=example-pod |

  # @author chuyu@redhat.com
  # @case_id OCP-15168
  Scenario: Job referencing image streams directly
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15168/example-job.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the output should contain "ErrImagePull"
    """
    Given I ensure "example-job" job is deleted
    When I run the :set_image_lookup client command with:
      | image_stream | app |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15168/example-job.yaml |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | app=example-job |

  # @author chuyu@redhat.com
  # @case_id OCP-15179
  Scenario: Requesting dereference on an entire object for Job
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15168/example-job.yaml |
    Then the step should succeed
    And I wait up to 240 seconds for the steps to pass:
    """
    When I get project pods
    Then the output should contain "ErrImagePull"
    """
    Given I ensure "example-job" job is deleted
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15168/example-job-annotation.yaml |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | app=example-job |

  # @author chuyu@redhat.com
  # @case_id OCP-15169
  Scenario: Replicasets referencing image streams directly
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15169/example-rs.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the output should contain "ErrImagePull"
    """
    Given I ensure "example-rs" replicaset is deleted
    When I run the :set_image_lookup client command with:
      | image_stream | app |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15169/example-rs.yaml |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | app=example-rs |

  # @author chuyu@redhat.com
  # @case_id OCP-15180
  Scenario: Requesting dereference on an entire object for Replicaset
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15169/example-rs.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the output should contain "ErrImagePull"
    """
    Given I ensure "example-rs" replicaset is deleted
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15169/example-rs-annotation.yaml |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | app=example-rs |

  # @author chuyu@redhat.com
  # @case_id OCP-15170
  Scenario: ReplicationController referencing image streams directly
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15170/example-rc.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the output should contain "ErrImagePull"
    """
    Given I ensure "example-rc" replicationcontroller is deleted
    When I run the :set_image_lookup client command with:
      | image_stream | app |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15170/example-rc.yaml |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | name=example-rc |

  # @author chuyu@redhat.com
  # @case_id OCP-15181
  Scenario:  Requesting dereference on an entire object for ReplicationController
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15170/example-rc.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the output should contain "ErrImagePull"
    """
    Given I ensure "example-rc" replicationcontroller is deleted
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15170/example-rc-annotation.yaml |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | name=example-rc |

  # @author chuyu@redhat.com
  # @case_id OCP-15153
  Scenario: Imagestream updates triggering on Kubernetes Deployment
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15153/deployment-example.yaml |
    Then the step should succeed
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | example:latest                  |
    Then the step should succeed
    And status becomes :running of 1 pods labeled:
      | app=deployment-example |
    And current replica set name of "deployment-example" deployment stored into :rs1 clipboard
    When I run the :set_triggers client command with:
      | resource   | deploy/deployment-example |
      | from_image | example:latest            |
      | containers | web                       |
    Then the step should succeed
    Given replica set "<%= cb.rs1 %>" becomes non-current for the "deployment-example" deployment
    And number of replicas of the current replica set for the deployment becomes:
      | ready | 1 |
    And current replica set name of "deployment-example" deployment stored into :rs2 clipboard
    Then the expression should be true> rs(cb.rs2).containers_spec[0].image == "openshift/deployment-example@sha256:c505b916f7e5143a356ff961f2c21aee40fbd2cd906c1e3feeb8d5e978da284b"
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v2 |
      | dest        | example:latest                  |
    Then the step should succeed
    Given replica set "<%= cb.rs2 %>" becomes non-current for the "deployment-example" deployment
    And number of replicas of the current replica set for the deployment becomes:
      | ready | 1 |
    And current replica set name of "deployment-example" deployment stored into :rs3 clipboard
    Then the expression should be true> rs(cb.rs3).containers_spec[0].image == "openshift/deployment-example@sha256:1318f08b141aa6a4cdca8c09fe8754b6c9f7802f8fc24e4e39ebf93e9d58472b"

  # @author chuyu@redhat.com
  # @case_id OCP-15155
  Scenario: Kubernetes Deployment referencing image streams directly
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :set_image_lookup client command with:
      | image_stream | app |
    Then the step should succeed
    When I run the :run client command with:
      | name      | app                |
      | generator | deployment/v1beta1 |
      | image     | app:v1             |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | run=app |
    And current replica set name of "app" deployment stored into :rs1 clipboard
    And the expression should be true> pod.containers[0].spec.image == "openshift/deployment-example@sha256:c505b916f7e5143a356ff961f2c21aee40fbd2cd906c1e3feeb8d5e978da284b" or pod.containers[0].spec.image == "image-registry.openshift-image-registry.svc:5000/<%= project.name %>/app:v1"
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v2 |
      | dest        | app:v2                          |
    Then the step should succeed
    When I run the :set_image client command with:
      | source    | docker     |
      | type_name | deploy/app |
      | keyval    | app=app:v2 |
    Then the step should succeed
    Given replica set "<%= cb.rs1 %>" becomes non-current for the "app" deployment
    And number of replicas of the current replica set for the deployment becomes:
      | ready | 1 |
    Given status becomes :running of 1 pods labeled:
      | run=app |
    And the expression should be true> pod.containers[0].spec.image == "openshift/deployment-example@sha256:1318f08b141aa6a4cdca8c09fe8754b6c9f7802f8fc24e4e39ebf93e9d58472b" or pod.containers[0].spec.image == "image-registry.openshift-image-registry.svc:5000/<%= project.name %>/app:v2"

  # @author chuyu@redhat.com
  # @case_id OCP-15156
  Scenario: Requesting dereference on an entire object for Kubernetes Deployment
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                          |
      | source      | openshift/deployment-example:v1 |
      | dest        | app:v1                          |
    Then the step should succeed
    When I run the :run client command with:
      | name      | app                |
      | generator | deployment/v1beta1 |
      | image     | app:v1             |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the output should contain "ErrImagePull"
    """
    When I run the :set_image_lookup client command with:
      | deployment | deployment/app |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | deployment                                     |
      | resource_name | app                                            |
      | o             | jsonpath={.spec.template.metadata.annotations} |
    Then the step should succeed
    And the output should match "alpha.image.policy.openshift.io/resolve-names"
    Given status becomes :running of 1 pods labeled:
      | run=app |

  # @author yinzhou@redhat.com
  # @case_id OCP-14211
  Scenario: Mock a hash collision
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/hello-deployment-oso.yaml |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | app=hello-openshift |
    And current replica set name of "hello-openshift" deployment stored into :rs1 clipboard
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 2 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 2 |
    When I run the :patch client command with:
      | resource      | rs                                                                   |
      | resource_name | <%= cb.rs1 %>                                                        |
      | p             | {"spec":{"template":{"spec":{"terminationGracePeriodSeconds": 35}}}} |
    Then the step should succeed
    Given replica set "<%= cb.rs1 %>" becomes non-current for the "hello-openshift" deployment
    And current replica set name of "hello-openshift" deployment stored into :rs2 clipboard
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 2 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 0 |
    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 2 |
    And the expression should be true> deployment.collision_count == 1

  # @author yinzhou@redhat.com
  # @case_id OCP-16632
  Scenario: View the history of rollouts for a specific deployment config for 3.7
    Given the master version >= "3.7"
    Given I have a project
    When I run the :new_app client command with:
      | docker_image   | <%= project_docker_repo %>openshift/deployment-example |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete
    When I run the :set_env client command with:
      | resource | dc/deployment-example |
      | e        | TEST=1                |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete
    When I run the :rollout_history client command with:
      | resource      | dc                 |
      | resource_name | deployment-example |
    Then the step should succeed
    And the output should contain 2 times:
      | config change |
    When I run the :rollout_history client command with:
      | resource      | dc                 |
      | resource_name | deployment-example |
      | revision      | 2                  |
    Then the step should succeed
    And the output should match:
      | revision     |
      | Labels:      |
      | Containers:  |
      | Annotations: |
