Feature: oc_set_resources.feature
  # @author yadu@redhat.com
  # @case_id 536677
  Scenario: Set invalid vlaue for CPU and memory limits
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And all pods in the project are ready
    # Set resource for non-existing container
    When I run the :set_resources client command with:
      | resource     | rc           |
      | resourcename | test-rc      |
      | c            | nonexisting  |
      | limits       | cpu=100m     |
    Then the step should fail
    And the output should contain:
      | unable to find container named nonexisting |
    # Set invalid value for resource
    When I run the :set_resources client command with:
      | resource     | rc                      |
      | resourcename | test-rc                 |
      | limits       | cpu=-100m,memory=-512Mi |
    Then the step should fail
    And the output should contain:
      | Invalid value                     |
      | must be a valid resource quantity |
    When I run the :set_resources client command with:
      | resource     | rc                  |
      | resourcename | test-rc             |
      | limits       | cpu=abc,memory=*^@  |
    Then the step should fail
    And the output should contain:
      | quantities must match the regular expression |
    # set the limits cpu/memory is less then request cpu/memory
    When I run the :set_resources client command with:
      | resource     | rc                    |
      | resourcename | test-rc               |
      | limits       | cpu=100m,memory=256Mi |
      | requests     | cpu=200m,memory=512Mi |
    Then the step should fail
    And the output should contain:
      | must be greater than or equal to cpu request |
    # Set limited for non-allowed resource
    When I run the :set_resources client command with:
      | resource     | pod                   |
      | resourcename | <%= pod.name %>       |
      | limits       | cpu=100m,memory=256Mi |
    Then the step should fail
    And the output should contain:
      | failed to patch limit update to pod template |

  # @author yadu@redhat.com
  # @case_id 536678
  Scenario: Set limits on a local file without talking to the server
    Given I have a project
    When I run the :set_resources client command with:
      | f            | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
      | limits       | cpu=200m,memory=512Mi |
      | requests     | cpu=100m,memory=256Mi |
      | o            | yaml                  |
      | local        | true                  |
    Then the step should succeed
    And the output should contain:
      | resources:    |
      | limits:       |
      | cpu: 200m     |
      | memory: 512Mi |
      | requests:     |
      | cpu: 100m     |
      | memory: 256Mi |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    And the pod named "hooks-1-deploy" becomes ready
    Given I wait for the pod named "hooks-1-deploy" to die
    When I run the :set_resources client command with:
      | resource     | dc                    |
      | resourcename | hooks                 |
      | limits       | cpu=100m,memory=256Mi |
      | requests     | cpu=100m,memory=256Mi |
      | dryrun       | true                  |
      | o            | yaml                  |
    Then the step should succeed
    And the output should contain:
      | resources:    |
      | limits:       |
      | cpu: 100m     |
      | memory: 256Mi |
      | requests:     |
      | cpu: 100m     |
      | memory: 256Mi |
