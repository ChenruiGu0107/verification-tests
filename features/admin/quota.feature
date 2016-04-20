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
      | must make a non-zero request for memory since it is tracked by quota |
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
      | spec.containers[0].resources.resources.limits[memory]: invalid value '256Mi', Details: limit cannot be smaller than request |
      | spec.containers[0].resources.resources.limits[cpu]: invalid value '500m', Details: limit cannot be smaller than request     |
    And I wait for the steps to pass
    When I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu\\s+0\\s+30      |
      | memory\\s+0\\s+16Gi |


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
      | unable to admit pod without exceeding quota for resource cpu:  limited to 30 but require 35 to succeed |
    When I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | cpu\\s+0\\s+30      |
      | memory\\s+0\\s+16Gi |


  # @author xiaocwan@redhat.com
  # @case_id 516457
  @admin
  Scenario:when the deployment can not be created due to a quota limit will get event from original report
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
      | rror creating deployer pod.*<%= project.name %>/dctest-1 |

  # @author xiaocwan@redhat.com
  # @case_id 481679
  @admin
  Scenario:DeploymentConfig should not allow the specification(which exceed resource quota) of resource requirements
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
    When I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployments_nobc_cpulimit.json"
    Then the step should succeed
    And the output should match:
      | eployment.*onfig\\s+"database".*reated |
    When I get project pods
    Then the output should contain:
      | database-1-deploy |
    
    # update dc to be exceeded and triggered deplyment 
    Given I replace resource "dc" named "database" saving edit to "database2.yaml":
      | cpu: 20m     | cpu:    1020m |
      | memory: 50Mi | memory: 760Mi |
    When I get project pods
    Then the output should not contain:
      | database-2-deploy |
    
    # trigger deployment manually according to the case step
    When I wait until the status of deployment "database" becomes :complete
    When I run the :deploy client command with:
      | deployment_config | database |
      | latest            ||
    Then the output should match:
      | tarted.*eployment.*2  |
    When I get project pods
    Then the output should not contain:
      | database-2-deploy |

    When I get project events
    # here comes a bug which fail the last step - 1317783 
    Then the output should match:
      | pods "database-\\d+-deploy" is forbidden |
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
      | f | https://raw.githubusercontent.com/xiaocwan/v3-testfiles/master/pods/hello-pod.json |
    Then the step should fail
    And the output should match:
      | specify.*memory |

    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/limits.yaml |
      | n        | <%= project.name %> |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/xiaocwan/v3-testfiles/master/pods/hello-pod.json |
    Then the step should succeed
    When I run the :get client command with:
      |resource | pod  |
      | o       | yaml |
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
      | f | https://raw.githubusercontent.com/xiaocwan/v3-testfiles/master/pods/hello-pod.json |
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