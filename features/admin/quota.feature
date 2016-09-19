Feature: Quota related scenarios
  # @author qwang@redhat.com
  # @case_id 509090, 509092, 509093
  @admin
  Scenario Outline: The quota usage should be incremented if meet the following requirement
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/myquota.yaml |
      | n | <%= project.name %>                                                                   |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu\\s+0\\s+30      |
      |	memory\\s+0\\s+16Gi |
    """
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/<path>/<file>
    Then the step should succeed
    And the pod named "<pod_name>" becomes ready
    When I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | <expr1> |
      | <expr2> |

    Examples:
      | path     | file                           | pod_name                  | expr1             | expr2                       |
      | tc509090 | pod-request-limit-valid-3.yaml | pod-request-limit-valid-3 | cpu\\s+100m\\s+30 | memory\\s+(134217728\|128Mi)\\s+16Gi |
      | tc509092 | pod-request-limit-valid-1.yaml | pod-request-limit-valid-1 | cpu\\s+500m\\s+30 | memory\\s+(536870912\|512Mi)\\s+16Gi |
      | tc509093 | pod-request-limit-valid-2.yaml | pod-request-limit-valid-2 | cpu\\s+200m\\s+30 | memory\\s+(268435456\|256Mi)\\s+16Gi |

  # @author qwang@redhat.com
  # @case_id 509096
  @admin
  Scenario: The quota usage should NOT be incremented if Requests and Limits aren't specified
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/myquota.yaml |
      | n | <%= project.name %>                                                                   |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu\\s+0\\s+30      |
      | memory\\s+0\\s+16Gi |
    """
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc509096/pod-request-limit-invalid-1.yaml
    Then the step should fail
    And the output should contain:
      | Failed quota: myquota: must specify cpu,memory |
    When I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu\\s+0\\s+30      |
      | memory\\s+0\\s+16Gi |

  # @author qwang@redhat.com
  # @case_id 509095
  @admin
  Scenario: The quota usage should NOT be incremented if Requests > Limits
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/myquota.yaml |
      | n | <%= project.name %>                                                                   |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When  I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu\\s+0\\s+30      |
      | memory\\s+0\\s+16Gi |
    """
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc509095/pod-request-limit-invalid-2.yaml
    Then the step should fail
    And the output should contain:
      | spec.containers[0].resources.limits[cpu]: Invalid value: "500m": must be greater than or equal to request     |
      | spec.containers[0].resources.limits[memory]: Invalid value: "256Mi": must be greater than or equal to request |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu\\s+0\\s+30      |
      | memory\\s+0\\s+16Gi |
    """

  # @author qwang@redhat.com
  # @case_id 509094
  @admin
  Scenario: The quota usage should NOT be incremented if Requests = Limits but exceeding hard quota
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/myquota.yaml |
      | n | <%= project.name %>                                                                   |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When  I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu\\s+0\\s+30      |
      | memory\\s+0\\s+16Gi |
    """
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc509094/pod-request-limit-invalid-3.yaml
    Then the step should fail
    And the output should contain:
      | Exceeded quota |
    When I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu\\s+0\\s+30      |
      | memory\\s+0\\s+16Gi |

  # @author xiaocwan@redhat.com
  # @case_id 516457
  @admin
  Scenario: when the deployment can not be created due to a quota limit will get event from original report
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/quota.yaml"
    And I replace lines in "quota.yaml":
      | memory: 750Mi | memory: 20Mi        |
    And I run the :create admin command with:
      | f             |  quota.yaml         |
      | n             | <%= project.name %> |
    Then the step should succeed

    When I run the :create client command with:
      | f |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/dc-with-two-containers.yaml |
    Then the step should succeed
    And the output should match:
      | eployment.*onfig.*reated            |

    When I get project pods
    Then the output should not match:
      | \\S+ |
    When I get project events
    Then the output should match:
      | Failed quota: quota: must specify cpu,memory |

  # @author xiaocwan@redhat.com
  # @case_id 481679
  @admin
  Scenario: DeploymentConfig should not allow the specification(which exceed resource quota) of resource requirements
    Given I have a project
    When I run the :create admin command with:
      | f     | https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/quota.yaml  |
      | n     | <%= project.name %> |
    Then the step should succeed
    When I run the :create admin command with:
      | f     | https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/limits.yaml |
      | n     | <%= project.name %> |
    Then the step should succeed
    # This template does not include bc, which does not need to create in case step, do not need to take care of AEP
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment-with-resources.json |
    Then the step should succeed
    And the output should match:
      | eployment.*onfig\\s+"hooks".*reated |
    When I get project pods
    Then the output should contain:
      | hooks-1-deploy |

    # update dc to be exceeded and triggered deployment
    Given I replace resource "dc" named "hooks" saving edit to "hooks2.yaml":
      | cpu: 30m      | cpu:    1020m |
      | memory: 150Mi | memory: 760Mi |
    When I get project pods
    Then the output should not contain:
      | hooks-2-deploy |

    # trigger deployment manually according to the case step
    Given I wait until the status of deployment "hooks" becomes :complete
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            ||
    Then the output should match:
      | tarted.*eployment.*2  |
    When I get project pods
    Then the output should not contain:
      | hooks-2-deploy |

    When I get project events
    # here comes a bug which fail the last step - 1317783
    Then the output should match:
      | pods "hooks-\\d+-deploy" is forbidden |
      | aximum memory usage.*is 750Mi.*limit is 796917760 |
      | aximum cpu usage.*is 500m.*limit is 1020m |

  # @author xiaocwan@redhat.com
  # @case_id 470361
  @admin
  Scenario: [origin_platformexp_372][origin_platformexp_334] Resource quota can be set for project
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/quota.yaml"
    And I replace lines in "quota.yaml":
      | 750Mi    | 110Mi               |
    Then the step should succeed
    And I run the :create admin command with:
      | f        | quota.yaml          |
      | n        | <%= project.name %> |
    Then the step should succeed

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod.json |
    Then the step should fail
    And the output should match:
      | specify.*memory |

    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/limits.yaml |
      | n        | <%= project.name %> |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod.json |
    Then the step should succeed
    When I get project pod as YAML
    Then the output should match:
      | cpu:\\s*100m     |
      | memory:\\s*100Mi |
    When I run the :describe admin command with:
      | resource      | quota               |
      | name          | quota               |
      | n             | <%= project.name %> |
    Then the output should match:
      | cpu\\s*100m      |
      | memory\\s*100Mi  |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod.json |
    Then the step should fail
    And the output should match:
      | xceeded quota |
      | xceeded quota |
    When I run the :delete client command with:
      | object_type | pods |
      | all         |      |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe admin command with:
      | resource      | quota               |
      | name          | quota               |
      | n             | <%= project.name %> |
    Then the output should not match:
      | cpu\\s*100m      |
      | memory\\s*100Mi  |
    """

  # @author qwang@redhat.com
  # @case_id 519921
  @admin
  Scenario: The quota status is calculated ASAP when editing its quota spec
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/myquota.yaml |
      | n | <%= project.name %>                                                                   |
    Then the step should succeed
    When  I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu.*30                    |
      | memory.*16Gi               |
      | persistentvolumeclaims.*20 |
      | pods.*20                   |
      | replicationcontrollers.*30 |
      | resourcequotas.*1          |
      | secrets.*15                |
      | services.*10               |
    When I run the :patch admin command with:
      | resource | quota |
      | resource_name | myquota |
      | namespace | <%= project.name %> |
      | p | {"spec":{"hard":{"cpu":"40"}}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu.*40 |
    When I run the :patch admin command with:
      | resource | quota |
      | resource_name | myquota |
      | namespace | <%= project.name %> |
      | p | {"spec":{"hard":{"memory":"20Gi"}}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | memory.*20Gi |
    When I run the :patch admin command with:
      | resource | quota |
      | resource_name | myquota |
      | namespace | <%= project.name %> |
      | p | {"spec":{"hard":{"services":"100"}}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | services.*100 |

  # @author xiaocwan@redhat.com
  # @case_id 481681
  @admin
  Scenario: There is log event for deployment when they fail due to quota limits
    Given I have a project
    When I run the :create admin command with:
      | f     | https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/quota.yaml  |
      | n     | <%= project.name %> |
    Then the step should succeed
    When I run the :create admin command with:
      | f     | https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/limits.yaml |
      | n     | <%= project.name %> |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment-with-resources.json |
    Then the step should succeed
    And the output should match:
      | eployment.*onfig\\s+"hooks".*reated |
    When I get project pods
    Then the output should match:
      | hooks-1-deploy |
    ## update dc to be exceeded and triggered deplyment
    Given I replace resource "dc" named "hooks" saving edit to "hooks2.yaml":
      | cpu: 30m      | cpu:    1020m |
      | memory: 150Mi | memory: 760Mi |
    ## oc deploy hoos --latest
    When I get project pods
    Then the output should not contain:
      | hooks-2-deploy |
    When I wait until the status of deployment "hooks" becomes :complete
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            ||
    Then the output should match:
      | tarted.*eployment.*2  |
    When I get project pods
    Then the output should not contain:
      | hooks-2-deploy |
    When I run the :describe client command with:
      | resource | dc      |
      | name     | hooks   |
    Then the output should match:
      | pods "hooks-\\d+-deploy" is forbidden |
      | aximum memory usage.*is 750Mi.*limit is 796917760 |
      | aximum cpu usage.*is 500m.*limit is 1020m |

  # @author xiaocwan@redhat.com
  # @case_id 481678
  @admin
  Scenario: Buildconfig should support providing cpu and memory usage
    Given I have a project
    When I run the :create admin command with:
      | f     | https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/quota.yaml  |
      | n     | <%= project.name %> |
    Then the step should succeed
    When I run the :create admin command with:
      | f     | https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/limits.yaml |
      | n     | <%= project.name %> |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/application-template-with-resources.json |
    And I run the :new_app client command with:
      | template | ruby-helloworld-sample-with-resources |
    Then the step should succeed
    And the output should match:
      | uildconfig\\s+"ruby-sample-build"\\s+created |
    Given the pod named "database-1-deploy" is present
    And the pod named "ruby-sample-build-2-build" is present
    When I get project pod as YAML
    Then the output should match:
      |   cpu:\\s+20m     |
      |   memory:\\s+50Mi |
      |   cpu:\\s+20m     |
      |   memory:\\s+50Mi |
    When I run the :delete client command with:
      | object_type       | build               |
      | all               | |
    Then the step should succeed
    When I replace resource "bc" named "ruby-sample-build" saving edit to "ruby-sample-build2.yaml":
      | cpu: 20m          | cpu:    1020m       |
      | memory: 50Mi      | memory: 760Mi       |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    When I get project builds
    Then the step should succeed
    And the output should match:
      | ruby-sample-build-[23].*[Nn]ew.*[Cc]annotCreateBuildPod |
    """
    When I run the :describe client command with:
      | resource | build                |
    Then the output should match:
      | pods.*ruby-sample-build-[23].*forbidden |
      | aximum memory usage.*is 750Mi.*limit is 796917760 |
      | aximum cpu usage.*is 500m.*limit is 1020m |

  # @author qwang@redhat.com
  # @case_id 520702
  @admin
  Scenario: Check BestEffort scope of resourcequota
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/quota-besteffort.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When  I run the :describe client command with:
      | resource | quota            |
      | name     | quota-besteffort |
    Then the output should match:
      | Scopes:\\s+BestEffort |
      | .*have best effort    |
      | pods\\s+0\\s+2        |
    # For BestEffort pod
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-besteffort.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota            |
      | name     | quota-besteffort |
    Then the output should match:
      | pods\\s+1\\s+2 |
    Given I ensure "pod-besteffort" pod is deleted
    # Because quota optimation is under way, leave time gap to wait for operation completed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | quota            |
      | name     | quota-besteffort |
    Then the output should match:
      | pods\\s+0\\s+2 |
    """
    # For Bustable pod
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-notbesteffort.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota            |
      | name     | quota-besteffort |
    Then the output should match:
      | pods\\s+0\\s+2 |
    Given I ensure "pod-notbesteffort" pod is deleted
    When I run the :describe client command with:
      | resource | quota            |
      | name     | quota-besteffort |
    Then the output should match:
      | pods\\s+0\\s+2 |

  # @author qwang@redhat.com
  # @case_id 520703
  @admin
  Scenario: Check NotBestEffort scope of resourcequota
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/quota-notbesteffort.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota               |
      | name     | quota-notbesteffort |
    Then the output should match:
      | Scopes:\\s+NotBestEffort    |
      | .*not have best effort      |
      | limits.cpu\\s+0\\s+4        |
      | limits.memory\\s+0\\s+2Gi   |
      | pods\\s+0\\s+2              |
      | requests.cpu\\s+0\\s+2      |
      | requests.memory\\s+0\\s+1Gi |
    # For Bustable pod
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-notbesteffort.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota               |
      | name     | quota-notbesteffort |
    Then the output should match:
      | limits.cpu\\s+500m\\s+4         |
      | limits.memory\\s+256Mi\\s+2Gi   |
      | pods\\s+1\\s+2                  |
      | requests.cpu\\s+200m\\s+2       |
      | requests.memory\\s+256Mi\\s+1Gi |
    Given I ensure "pod-notbesteffort" pod is deleted
    # Because quota optimation is under way, leave time gap to wait for operation completed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | quota               |
      | name     | quota-notbesteffort |
    Then the output should match:
      | limits.cpu\\s+0\\s+4        |
      | limits.memory\\s+0\\s+2Gi   |
      | pods\\s+0\\s+2              |
      | requests.cpu\\s+0\\s+2      |
      | requests.memory\\s+0\\s+1Gi |
    """
    # For BestEffort pod
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-besteffort.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota               |
      | name     | quota-notbesteffort |
    Then the output should match:
      | limits.cpu\\s+0\\s+4        |
      | limits.memory\\s+0\\s+2Gi   |
      | pods\\s+0\\s+2              |
      | requests.cpu\\s+0\\s+2      |
      | requests.memory\\s+0\\s+1Gi |
    Given I ensure "pod-besteffort" pod is deleted
    When I run the :describe client command with:
      | resource | quota               |
      | name     | quota-notbesteffort |
    Then the output should match:
      | limits.cpu\\s+0\\s+4        |
      | limits.memory\\s+0\\s+2Gi   |
      | pods\\s+0\\s+2              |
      | requests.cpu\\s+0\\s+2      |
      | requests.memory\\s+0\\s+1Gi |

  # @author qwang@redhat.com
  # @case_id 520704
  @admin
  Scenario: Check NotTerminating scope of resourcequota
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/quota-notterminating.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota                |
      | name     | quota-notterminating |
    Then the output should match:
      | Scopes:\\s+NotTerminating     |
      | .*not have an active deadline |
      | limits.cpu\\s+0\\s+4          |
      | limits.memory\\s+0\\s+2Gi     |
      | pods\\s+0\\s+2                |
      | requests.cpu\\s+0\\s+2        |
      | requests.memory\\s+0\\s+1Gi   |
    # For NotTerminating pod
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-notterminating.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota                |
      | name     | quota-notterminating |
    Then the output should match:
      | limits.cpu\\s+500m\\s+4         |
      | limits.memory\\s+256Mi\\s+2Gi   |
      | pods\\s+1\\s+2                  |
      | requests.cpu\\s+200m\\s+2       |
      | requests.memory\\s+256Mi\\s+1Gi |
    Given I ensure "pod-notterminating" pod is deleted
    # Because quota optimation is under way, leave time gap to wait for operation completed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | quota                |
      | name     | quota-notterminating |
    Then the output should match:
      | limits.cpu\\s+0\\s+4        |
      | limits.memory\\s+0\\s+2Gi   |
      | pods\\s+0\\s+2              |
      | requests.cpu\\s+0\\s+2      |
      | requests.memory\\s+0\\s+1Gi |
    """
    # For Terminating pod
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-terminating.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota                |
      | name     | quota-notterminating |
    Then the output should match:
      | limits.cpu\\s+0\\s+4        |
      | limits.memory\\s+0\\s+2Gi   |
      | pods\\s+0\\s+2              |
      | requests.cpu\\s+0\\s+2      |
      | requests.memory\\s+0\\s+1Gi |
    Given I ensure "pod-terminating" pod is deleted
    When I run the :describe client command with:
      | resource | quota                |
      | name     | quota-notterminating |
    Then the output should match:
      | limits.cpu\\s+0\\s+4        |
      | limits.memory\\s+0\\s+2Gi   |
      | pods\\s+0\\s+2              |
      | requests.cpu\\s+0\\s+2      |
      | requests.memory\\s+0\\s+1Gi |

  # @author qwang@redhat.com
  # @case_id 520705
  @admin
  Scenario: Check Terminating scope of resourcequota
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/quota-terminating.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota             |
      | name     | quota-terminating |
    Then the output should match:
      | Scopes:\\s+Terminating         |
      | .*that have an active deadline |
      | limits.cpu\\s+0\\s+2           |
      | limits.memory\\s+0\\s+2Gi      |
      | pods\\s+0\\s+4                 |
      | requests.cpu\\s+0\\s+1         |
      | requests.memory\\s+0\\s+1Gi    |
    # For Terminating pod
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-terminating.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota             |
      | name     | quota-terminating |
    Then the output should match:
      | limits.cpu\\s+500m\\s+2         |
      | limits.memory\\s+256Mi\\s+2Gi   |
      | pods\\s+1\\s+4                  |
      | requests.cpu\\s+200m\\s+1       |
      | requests.memory\\s+256Mi\\s+1Gi |
    # activeDeadlineSeconds=60s, after 60s, used quota returns to the original state
    Given 60 seconds have passed
    When I run the :describe client command with:
      | resource | quota             |
      | name     | quota-terminating |
    Then the output should match:
      | limits.cpu\\s+0\\s+2        |
      | limits.memory\\s+0\\s+2Gi   |
      | pods\\s+0\\s+4              |
      | requests.cpu\\s+0\\s+1      |
      | requests.memory\\s+0\\s+1Gi |
    Given I ensure "pod-terminating" pod is deleted
    When I run the :describe client command with:
      | resource | quota             |
      | name     | quota-terminating |
    Then the output should match:
      | limits.cpu\\s+0\\s+2        |
      | limits.memory\\s+0\\s+2Gi   |
      | pods\\s+0\\s+4              |
      | requests.cpu\\s+0\\s+1      |
      | requests.memory\\s+0\\s+1Gi |
    # For NotTerminating pod
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-notterminating.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota             |
      | name     | quota-terminating |
    Then the output should match:
      | limits.cpu\\s+0\\s+2        |
      | limits.memory\\s+0\\s+2Gi   |
      | pods\\s+0\\s+4              |
      | requests.cpu\\s+0\\s+1      |
      | requests.memory\\s+0\\s+1Gi |
    Given I ensure "pod-notterminating" pod is deleted
    When I run the :describe client command with:
      | resource | quota             |
      | name     | quota-terminating |
    Then the output should match:
      | limits.cpu\\s+0\\s+2        |
      | limits.memory\\s+0\\s+2Gi   |
      | pods\\s+0\\s+4              |
      | requests.cpu\\s+0\\s+1      |
      | requests.memory\\s+0\\s+1Gi |


  # @author chezhang@redhat.com
  # @case_id 509087
  @admin
  Scenario: Could create quota if existing resources exceed to the hard quota but prevent to create further resources
    Given I have a project
    When I run the :new_app admin command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/quota_template.yaml        |
      | param | CPU_VALUE=0.2,MEM_VALUE=1Gi,PV_VALUE=1,POD_VALUE=2,RC_VALUE=3,RQ_VALUE=3,SECRET_VALUE=5,SVC_VALUE=5 |
      | n     | <%= project.name %>            |
    Then the step should succeed
    When  I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu\\s+0\\s+200m                 |
      | memory\\s+0\\s+1Gi               |
      | persistentvolumeclaims\\s+0\\s+1 |
      | pods\\s+0\\s+2                   |
      | replicationcontrollers\\s+0\\s+3 |
      | resourcequotas\\s+1\\s+3         |
      | secrets\\s+9\\s+5                |
      | services\\s+0\\s+5               |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc509087/mysecret.json |
    Then the step should fail
    And the output should match:
      | Error from server.*forbidden: Exceeded quota.*    |
    When I run the :patch admin command with:
      | resource | quota |
      | resource_name | myquota |
      | namespace | <%= project.name %> |
      | p | {"spec":{"hard":{"secrets":"15"}}} |
    Then the step should succeed
    When  I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu\\s+0\\s+200m                 |
      | memory\\s+0\\s+1Gi               |
      | persistentvolumeclaims\\s+0\\s+1 |
      | pods\\s+0\\s+2                   |
      | replicationcontrollers\\s+0\\s+3 |
      | resourcequotas\\s+1\\s+3         |
      | secrets\\s+9\\s+15               |
      | services\\s+0\\s+5               |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc509087/mysecret.json |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu\\s+0\\s+200m                 |
      | memory\\s+0\\s+1Gi               |
      | persistentvolumeclaims\\s+0\\s+1 |
      | pods\\s+0\\s+2                   |
      | replicationcontrollers\\s+0\\s+3 |
      | resourcequotas\\s+1\\s+3         |
      | secrets\\s+10\\s+15              |
      | services\\s+0\\s+5               |


  # @author chezhang@redhat.com
  # @case_id 519922
  @admin
  Scenario: The usage for cpu/mem/pod counts are fixed up ASAP if delete a pod
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/myquota.yaml |
      | n | <%= project.name %>    |
    Then the step should succeed
    When  I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu\\s+0\\s+30                    |
      | memory\\s+0\\s+16Gi               |
      | persistentvolumeclaims\\s+0\\s+20 |
      | pods\\s+0\\s+20                   |
      | replicationcontrollers\\s+0\\s+30 |
      | resourcequotas\\s+1\\s+1          |
      | secrets\\s+9\\s+15                |
      | services\\s+0\\s+10               |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc519922/pod-request-limit-valid-4.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu\\s+400m\\s+30                 |
      | memory\\s+1Gi\\s+16Gi             |
      | persistentvolumeclaims\\s+0\\s+20 |
      | pods\\s+1\\s+20                   |
      | replicationcontrollers\\s+0\\s+30 |
      | resourcequotas\\s+1\\s+1          |
      | secrets\\s+9\\s+15                |
      | services\\s+0\\s+10               |
    Given I ensure "pod-request-limit-valid-4" pod is deleted
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu\\s+0\\s+30                    |
      | memory\\s+0\\s+16Gi               |
      | persistentvolumeclaims\\s+0\\s+20 |
      | pods\\s+0\\s+20                   |
      | replicationcontrollers\\s+0\\s+30 |
      | resourcequotas\\s+1\\s+1          |
      | secrets\\s+9\\s+15                |
      | services\\s+0\\s+10               |
    """

  # @author qwang@redhat.com
  # @case_id 519920
  @admin
  Scenario: The current quota usage is calculated ASAP when adding a quota
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/myquota.yaml |
      | n | <%= project.name %>    |
    Then the step should succeed
    When  I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu\\s+0\\s+30                    |
      | memory\\s+0\\s+16Gi               |
      | persistentvolumeclaims\\s+0\\s+20 |
      | pods\\s+0\\s+20                   |
      | replicationcontrollers\\s+0\\s+30 |
      | resourcequotas\\s+1\\s+1          |
      | secrets\\s+9\\s+15                |
      | services\\s+0\\s+10               |
    # Add correct quota
    When I run the :patch admin command with:
      | resource      | quota                          |
      | resource_name | myquota                        |
      | namespace     | <%= project.name %>            |
      | p             | {"spec":{"hard":{"cpu":"31","memory":"20Gi","persistentvolumeclaims":"30","pods":"50","replicationcontrollers":"10","resourcequotas":"2","secrets":"20","services":"30"}}} |
    Then the step should succeed
    And I wait up to 5 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu\\s+0\\s+31                    |
      | memory\\s+0\\s+20Gi               |
      | persistentvolumeclaims\\s+0\\s+30 |
      | pods\\s+0\\s+50                   |
      | replicationcontrollers\\s+0\\s+10 |
      | resourcequotas\\s+1\\s+2          |
      | secrets\\s+9\\s+20                |
      | services\\s+0\\s+30               |
    """


  # @author qwang@redhat.com
  # @case_id 509091
  @admin
  Scenario: The quota usage should be incremented if Requests = Limits and in the range of hard quota but exceed the real node available resources
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/myquota.yaml |
      | n | <%= project.name %>    |
    Then the step should succeed
    When  I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu\\s+0\\s+30                    |
      | memory\\s+0\\s+16Gi               |
      | persistentvolumeclaims\\s+0\\s+20 |
      | pods\\s+0\\s+20                   |
      | replicationcontrollers\\s+0\\s+30 |
      | resourcequotas\\s+1\\s+1          |
      | secrets\\s+9\\s+15                |
      | services\\s+0\\s+10               |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc509091/pod-request-limit-valid-4.yaml |
    Then the step should succeed
    Given the pod named "pod-request-limit-valid-4" status becomes :pending
    When I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu\\s+10\\s+30                   |
      | memory\\s+10Gi\\s+16Gi            |
      | persistentvolumeclaims\\s+0\\s+20 |
      | pods\\s+1\\s+20                   |
      | replicationcontrollers\\s+0\\s+30 |
      | resourcequotas\\s+1\\s+1          |
      | secrets\\s+9\\s+15                |
      | services\\s+0\\s+10               |

  # @author chezhang@redhat.com
  # @case_id 532979
  @admin
  Scenario: Admin can restrict the ability to use services.nodeports
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc532979/quota-service.yaml |
      | n | <%= project.name %>  |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+0\\s+5           |
      | services.nodeports\\s+0\\s+2 |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc532979/nodeport-svc1.json |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+1\\s+5           |
      | services.nodeports\\s+1\\s+2 |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc532979/nodeport-svc2.json |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+2\\s+5           |
      | services.nodeports\\s+2\\s+2 |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc532979/nodeport-svc3.json |
    Then the step should fail
    And the output should match:
      | Exceeded quota: quota-service.*limited: services.nodeports=2 |
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+2\\s+5           |
      | services.nodeports\\s+2\\s+2 |
    When I run the :delete client command with:
      | object_type       | svc           |
      | object_name_or_id | nodeport-svc1 |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+1\\s+5           |
      | services.nodeports\\s+1\\s+2 |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc532979/nodeport-svc3.json |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+2\\s+5           |
      | services.nodeports\\s+2\\s+2 |

  # @author chezhang@redhat.com
  # @case_id 532980
  @admin
  Scenario: Service with multi nodeports should be charged properly in the quota system
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc532979/quota-service.yaml |
      | n | <%= project.name %>  |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+0\\s+5           |
      | services.nodeports\\s+0\\s+2 |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc532980/multi-nodeports-svc.json |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+1\\s+5           |
      | services.nodeports\\s+2\\s+2 |
    When I run the :delete client command with:
      | object_type       | svc                 |
      | object_name_or_id | multi-nodeports-svc |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+0\\s+5           |
      | services.nodeports\\s+0\\s+2 |

  # @author chezhang@redhat.com
  # @case_id 532981
  @admin
  Scenario: services.nodeports in quota system work well when change service type
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc532979/quota-service.yaml |
      | n | <%= project.name %>  |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+0\\s+5           |
      | services.nodeports\\s+0\\s+2 |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/tc532979/nodeport-svc1.json |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+1\\s+5           |
      | services.nodeports\\s+1\\s+2 |
    When I run the :patch client command with:
      | resource      | svc           |
      | resource_name | nodeport-svc1 |
      | type          | json          |
      | p             | [{"op": "remove", "path": "/spec/ports/0/nodePort"},{"op": "replace", "path": "/spec/type", "value": ClusterIP}] |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+1\\s+5           |
      | services.nodeports\\s+0\\s+2 |
    When I run the :patch client command with:
      | resource      | svc           |
      | resource_name | nodeport-svc1 |
      | type          | json          |
      | p             | [{"op": "replace", "path": "/spec/type", "value": NodePort}] |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+1\\s+5           |
      | services.nodeports\\s+1\\s+2 |

  # @author chezhang@redhat.com
  # @case_id 533791
  @admin
  Scenario: The quota usage should be released when pod completed
    Given I have a project
    When I run the :create_quota admin command with:
      | name | myquota                    |
      | hard | cpu=30,memory=16Gi,pods=20 |
      | n    | <%= project.name %>        |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota    |
      | name     | myquota  |
    Then the output should match:
      | cpu\\s+0\\s+30      |
      | memory\\s+0\\s+16Gi |
      | pods\\s+0\\s+20     |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-completed.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota    |
      | name     | myquota  |
    Then the output should match:
      | cpu\\s+700m\\s+30     |
      | memory\\s+1Gi\\s+16Gi |
      | pods\\s+1\\s+20       |
    Given the pod named "podtocomplete" status becomes :succeeded
    When I run the :describe client command with:
      | resource | quota    |
      | name     | myquota  |
    Then the output should match:
      | cpu\\s+0\\s+30      |
      | memory\\s+0\\s+16Gi |
      | pods\\s+0\\s+20     |

  # @author chezhang@redhat.com
  # @case_id 533795
  @admin
  Scenario: Quota with BestEffort and NotBestEffort scope
    Given I have a project
    When I run the :create_quota admin command with:
      | name   | quota-besteffort     |
      | hard   | pods=10              |
      | scopes | BestEffort           |
      | n      | <%= project.name %>  |
    Then the step should succeed
    When I run the :create_quota admin command with:
      | name   | quota-notbesteffort |
      | hard   | pods=5              |
      | scopes | NotBestEffort       |
      | n | <%= project.name %>      |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota    |
    Then the output by order should match:
      | quota-besteffort    |
      | BestEffort          |
      | pods\\s+0\\s+10     |
      | quota-notbesteffort |
      | NotBestEffort       |
      | pods\\s+0\\s+5      |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-besteffort.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota    |
    Then the output by order should match:
      | pods\\s+1\\s+10     |
      | pods\\s+0\\s+5      |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-notbesteffort.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota    |
    Then the output by order should match:
      | pods\\s+1\\s+10     |
      | pods\\s+1\\s+5      |
    Given I ensure "pod-notbesteffort" pod is deleted
    When I run the :describe client command with:
      | resource | quota    |
    Then the output by order should match:
      | pods\\s+1\\s+10     |
      | pods\\s+0\\s+5      |

  # @author chezhang@redhat.com
  # @case_id 533796
  @admin
  Scenario: Quota with Terminating and NotTerminating scope
    Given I have a project
    When I run the :create_quota admin command with:
      | name   | quota-terminating |
      | hard   | pods=10           |
      | scopes | Terminating       |
      | n | <%= project.name %>    |
    Then the step should succeed
    When I run the :create_quota admin command with:
      | name   | quota-notterminating |
      | hard   | pods=5               |
      | scopes | NotTerminating       |
      | n      | <%= project.name %>  |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota     |
    Then the output by order should match:
      | quota-notterminating |
      | NotTerminating       |
      | pods\\s+0\\s+5       |
      | quota-terminating    |
      | Terminating          |
      | pods\\s+0\\s+10      |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-terminating.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota |
    Then the output by order should match:
      | pods\\s+0\\s+5   |
      | pods\\s+1\\s+10  |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-notterminating.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota |
    Then the output by order should match:
      | pods\\s+1\\s+5   |
      | pods\\s+1\\s+10  |
    Given a pod becomes ready with labels:
      | name=pod-terminating |
    And I wait up to 70 seconds for the steps to pass:
    """
    When I get project pods
    Then the output should match "pod-terminating.*DeadlineExceeded"
    """
    When I run the :describe client command with:
      | resource | quota |
    Then the output by order should match:
      | pods\\s+1\\s+5   |
      | pods\\s+0\\s+10  |

  # @author chezhang@redhat.com
  # @case_id 533792
  @admin
  Scenario: Quota combined scopes
    Given I have a project
    When I run the :create_quota admin command with:
      | name   | quota-notbesteffortandnotterminating |
      | hard   | pods=10                              |
      | scopes | NotBestEffort,NotTerminating         |
      | n | <%= project.name %>                       |
    Then the step should succeed
    When I run the :create_quota admin command with:
      | name   | quota-besteffortandterminating |
      | hard   | pods=8                         |
      | scopes | BestEffort,Terminating         |
      | n      | <%= project.name %>            |
    Then the step should succeed
    When I run the :create_quota admin command with:
      | name   | quota-besteffort    |
      | hard   | pods=6              |
      | scopes | BestEffort          |
      | n      | <%= project.name %> |
    Then the step should succeed
    When I run the :create_quota admin command with:
      | name   | quota-notterminating |
      | hard   | pods=5               |
      | scopes | NotTerminating       |
      | n      | <%= project.name %>  |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota |
    Then the output by order should match:
      | quota-besteffort                     |
      | BestEffort                           |
      | pods\\s+0\\s+6                       |
      | quota-besteffortandterminating       |
      | BestEffort.*Terminating              |
      | pods\\s+0\\s+8                       |
      | quota-notbesteffortandnotterminating |
      | NotBestEffort.*NotTerminating        |
      | pods\s+0\\s+10                       |
      | quota-notterminating                 |
      | NotTerminating                       |
      | pods\\s+0\\s+5                       |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-notbesteffort.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota |
    Then the output by order should match:
      | pods\\s+0\\s+6 |
      | pods\\s+0\\s+8 |
      | pods\s+1\\s+10 |
      | pods\\s+1\\s+5 |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-besteffort.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota |
    Then the output by order should match:
      | pods\\s+1\\s+6 |
      | pods\\s+0\\s+8 |
      | pods\s+1\\s+10 |
      | pods\\s+2\\s+5 |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-besteffort-terminating.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota |
    Then the output by order should match:
      | pods\\s+2\\s+6 |
      | pods\\s+1\\s+8 |
      | pods\s+1\\s+10 |
      | pods\\s+2\\s+5 |
    Given a pod becomes ready with labels:
      | name=pod-besteffort-terminating |
    And I wait up to 70 seconds for the steps to pass:
    """
    When I get project pods
    Then the output should match "pod-besteffort-terminating.*DeadlineExceeded"
    """
    When I run the :describe client command with:
      | resource | quota |
    Then the output by order should match:
      | pods\\s+1\\s+6 |
      | pods\\s+0\\s+8 |
      | pods\s+1\\s+10 |
      | pods\\s+2\\s+5 |


  # @author qwang@redhat.com
  # @case_id 533793
  @admin
  Scenario: Quota scope conflict BestEffort and NotBestEffort
    Given I have a project
    When I run the :create_quota admin command with:
      | name   | quota-besteffortnot      |
      | hard   | pods=10                  |
      | scopes | BestEffort,NotBestEffort |
      | n      | <%= project.name %>      |
    Then the step should fail
    And the output should contain "spec.scopes: Invalid value: ["BestEffort","NotBestEffort"]: conflicting scopes"


  # @author qwang@redhat.com
  # @case_id 533794
  @admin
  Scenario: Quota scope conflict Terminating and NotTerminating
    Given I have a project
    When I run the :create_quota admin command with:
      | name   | quota-terminatingnot       |
      | hard   | pods=10                    |
      | scopes | Terminating,NotTerminating |
      | n      | <%= project.name %>        |
    Then the step should fail
    And the output should contain "spec.scopes: Invalid value: ["Terminating","NotTerminating"]: conflicting scopes"

  # @author wmeng@redhat.com
  # @case_id 534960
  Scenario: check QoS Tier BestEffort
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-besteffort.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod            |
      | name     | pod-besteffort |
    Then the step should succeed
    And the output should not match:
      | Burstable  |
      | Guaranteed |
    And the output should match:
      | BestEffort |

  # @author wmeng@redhat.com
  # @case_id 534961
  Scenario: check QoS Tier Burstable
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-burstable.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod            |
      | name     | pod-burstable |
    Then the step should succeed
    And the output should not match:
      | Guaranteed |
      | BestEffort |
    And the output should match:
      | Burstable  |

  # @author wmeng@redhat.com
  # @case_id 534962
  Scenario: check QoS Tier Guaranteed
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-guaranteed.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod            |
      | name     | pod-guaranteed |
    Then the step should succeed
    And the output should not match:
      | BestEffort |
      | Burstable  |
    And the output should match:
      | Guaranteed |
