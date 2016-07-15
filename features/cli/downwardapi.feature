Feature: Downward API

  # @author qwang@redhat.com
  # @case_id 509097
  Scenario: Pods can get IPs via downward API under race condition
    Given I have a project
    When I run the :create client command with:
      | filename  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/downwardapi/tc509097/pod-downwardapi-env.yaml |
    Then the step should succeed
    Given the pod named "downwardapi-env" becomes ready
    When I run the :get client command with:
      | resource | pods |
    Then the output should contain:
      | NAME            |
      | downwardapi-env |
    When  I run the :describe client command with:
      | resource | pod             |
      | name     | downwardapi-env |
    Then the output should match:
      | Status:\\s+Running |
      | Ready\\s+True      |
    When I run the :exec client command with:
      | pod          | downwardapi-env |
      | exec_command | env             |
    Then the output should contain "MYSQL_POD_IP=1"

  # @author cryan@redhat.com
  # @case_id 483203
  Scenario: downward api pod name and pod namespace as env variables
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/downwardapi/tc483203/downward-example.yaml |
    Then the step should succeed
    And the pod named "dapi-test-pod" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | dapi-test-pod |
    Then the step should succeed
    And the output should contain:
      | POD_NAME=dapi-test-pod |
      | POD_NAMESPACE=<%= project.name %> |

  # @author qwang@redhat.com
  # @case_id 509098
  Scenario: Container consume infomation from the downward API using a volume plugin
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/downwardapi/pod-dapi-volume.yaml |
    Then the step should succeed
    Given the pod named "pod-dapi-volume" becomes ready
    When I execute on the pod:
      | ls | -laR | /var/tmp/podinfo |
    Then the output should contain:
      | annotations -> ..downwardapi/annotations |
      | labels -> ..downwardapi/labels           |
      | name -> ..downwardapi/name               |
      | namespace -> ..downwardapi/namespace     |
    When I execute on the pod:
      | cat | /var/tmp/podinfo/name |
    Then the output should contain:
      | pod-dapi-volume |
    And I execute on the pod:
      | cat | /var/tmp/podinfo/namespace |
    Then the output should contain:
      | <%= project.name %> |
    And I execute on the pod:
      | cat | /var/tmp/podinfo/labels |
    Then the output should contain:
      | rack="a111" |
      | region="r1" |
      | zone="z11"  |
    And I execute on the pod:
      | cat | /var/tmp/podinfo/annotations |
    Then the output should contain:
      | build="one"      |
      | builder="qe-one" |
    # Change the value of annotations
    When I run the :patch client command with:
      | resource      | pod |
      | resource_name | pod-dapi-volume |
      | p             | {"metadata":{"annotations":{"build":"two"}}} |
    And I execute on the pod:
      | cat | /var/tmp/podinfo/annotations |
    Then the output should contain:
      | build="two" |
    # Delete one of labels
    When I run the :patch client command with:
      | resource      | pod                                   |
      | resource_name | pod-dapi-volume                       |
      | p             | {"metadata":{"labels":{"rack":null}}} |
    And I execute on the pod:
      | cat | /var/tmp/podinfo/labels |
    Then the output should not contain:
      | rack="a111" |
    And the output should contain:
      | region="r1" |
      | zone="z11"  |
