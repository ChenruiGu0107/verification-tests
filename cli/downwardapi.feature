Feature: Downward API

  # @author qwang@redhat.com
  # @author weinliu@redhat.com
  # @case_id OCP-10913
  @admin
  Scenario: Could expose resouces limits and requests via ENV from Downward APIs by passing containerName
    Given I have a project
    Given I obtain test data file "downwardapi/dapi-resources-env-containername-pod.yaml"
    When I run the :create client command with:
      | f | dapi-resources-env-containername-pod.yaml |
    Then the step should succeed
    And the pod named "dapi-resources-env-containername-pod" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | dapi-resources-env-containername-pod |
    Then the step should succeed
    And the output should contain:
      | MY_MEM_LIMIT=67108864 |
      | MY_CPU_LIMIT=1        |
      | MY_MEM_REQUEST=32     |
      | MY_CPU_REQUEST=1      |
    # Test file without requests, use limits as requests by default
    Given I ensure "dapi-resources-env-containername-pod" pod is deleted
    Given I obtain test data file "downwardapi/dapi-resources-env-containername-pod-without-requests.yaml"
    When I run the :create client command with:
      | f | dapi-resources-env-containername-pod-without-requests.yaml |
    Then the step should succeed
    And the pod named "dapi-resources-env-containername-pod-without-requests" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | dapi-resources-env-containername-pod-without-requests |
    Then the step should succeed
    And the output should contain:
      | MY_MEM_LIMIT=67108864 |
      | MY_CPU_LIMIT=1        |
      | MY_MEM_REQUEST=64     |
      | MY_CPU_REQUEST=1      |
    # Test file without limits, use node allocatable as limits by default
    Given I ensure "dapi-resources-env-containername-pod-without-requests" pod is deleted
    Given I obtain test data file "downwardapi/dapi-resources-env-containername-pod-without-limits.yaml"
    When I run the :create client command with:
      | f | dapi-resources-env-containername-pod-without-limits.yaml |
    Then the step should succeed
    And the pod named "dapi-resources-env-containername-pod-without-limits" status becomes :succeeded
    Given evaluation of `pod("dapi-resources-env-containername-pod-without-limits").node_name(user: user)` is stored in the :node clipboard
    When I run the :get admin command with:
      | resource      | node           |
      | resource_name | <%= cb.node %> |
      | o             | yaml           |
    Then the step should succeed
    And evaluation of `@result[:parsed]["status"]["capacity"]["cpu"]` is stored in the :nodecpulimit clipboard
    And evaluation of `@result[:parsed]["status"]["allocatable"]["memory"].gsub(/Ki/,'')` is stored in the :nodememorylimit clipboard
    When I run the :logs client command with:
      | resource_name | dapi-resources-env-containername-pod-without-limits |
    Then the step should succeed
    And the output should contain:
      | MY_MEM_REQUEST=32                                |
      | MY_CPU_REQUEST=1                                 |
      | MY_MEM_LIMIT=<%= cb.nodememorylimit.to_i*1024 %> |
      | MY_CPU_LIMIT=<%= cb.nodecpulimit %>              |
    When I run the :describe client command with:
      | resource | pod                                                 |
      | name     | dapi-resources-env-containername-pod-without-limits |
    Then the step should succeed
    And the output should match:
      | MY_CPU_REQUEST:\\s+1 \(requests.cpu\)               |
      | MY_CPU_LIMIT:\\s+node allocatable \(limits.cpu\)    |
      | MY_MEM_REQUEST:\\s+32 \(requests.memory\)           |
      | MY_MEM_LIMIT:\\s+node allocatable \(limits.memory\) |


  # @author qwang@redhat.com
  # @case_id OCP-11324
  @admin
  Scenario: Could expose resouces limits and requests via ENV from Downward APIs with magic keys
    Given I have a project
    Given I obtain test data file "downwardapi/dapi-resources-env-magic-keys-pod.yaml"
    When I run the :create client command with:
      | f | dapi-resources-env-magic-keys-pod.yaml |
    Then the step should succeed
    And the pod named "dapi-resources-env-magic-keys-pod" status becomes :succeeded within 300 seconds
    When I run the :logs client command with:
      | resource_name | dapi-resources-env-magic-keys-pod |
    Then the step should succeed
    And the output should contain:
      | MY_MEM_LIMIT=67108864 |
      | MY_CPU_LIMIT=2        |
      | MY_MEM_REQUEST=32     |
      | MY_CPU_REQUEST=1      |
    # Test file without requests, use limits as requests by default
    Given I ensure "dapi-resources-env-magic-keys-pod" pod is deleted
    Given I obtain test data file "downwardapi/dapi-resources-env-magic-keys-pod-without-requests.yaml"
    When I run the :create client command with:
      | f | dapi-resources-env-magic-keys-pod-without-requests.yaml |
    Then the step should succeed
    And the pod named "dapi-resources-env-magic-keys-pod-without-requests" status becomes :succeeded within 300 seconds
    When I run the :logs client command with:
      | resource_name | dapi-resources-env-magic-keys-pod-without-requests |
    Then the step should succeed
    And the output should contain:
      | MY_MEM_LIMIT=67108864 |
      | MY_CPU_LIMIT=1        |
      | MY_MEM_REQUEST=64     |
      | MY_CPU_REQUEST=1      |
    # Test file without limits, use node allocatable as limits by default
    Given I ensure "dapi-resources-env-magic-keys-pod-without-requests" pod is deleted
    Given I obtain test data file "downwardapi/dapi-resources-env-magic-keys-pod-without-limits.yaml"
    When I run the :create client command with:
      | f | dapi-resources-env-magic-keys-pod-without-limits.yaml |
    Then the step should succeed
    And the pod named "dapi-resources-env-magic-keys-pod-without-limits" status becomes :succeeded within 300 seconds
    Given evaluation of `pod("dapi-resources-env-magic-keys-pod-without-limits").node_name(user: user)` is stored in the :node clipboard
    When I run the :get admin command with:
      | resource      | node           |
      | resource_name | <%= cb.node %> |
      | o             | yaml           |
    Then the step should succeed
    And evaluation of `@result[:parsed]["status"]["allocatable"]["cpu"]` is stored in the :nodecpulimit clipboard
    And evaluation of `@result[:parsed]["status"]["allocatable"]["memory"].gsub(/Ki/,'')` is stored in the :nodememorylimit clipboard
    When I run the :logs client command with:
      | resource_name | dapi-resources-env-magic-keys-pod-without-limits |
    Then the step should succeed
    And the output should contain:
      | MY_MEM_REQUEST=32                                |
      | MY_CPU_REQUEST=1                                 |
      | MY_MEM_LIMIT=<%= cb.nodememorylimit.to_i*1024 %> |
      | MY_CPU_LIMIT=<%= cb.nodecpulimit %>              |
    When I run the :describe client command with:
      | resource | pod                                              |
      | name     | dapi-resources-env-magic-keys-pod-without-limits |
    Then the step should succeed
    And the output should match:
      | MY_CPU_REQUEST:\\s+1 \(requests.cpu\)               |
      | MY_CPU_LIMIT:\\s+node allocatable \(limits.cpu\)    |
      | MY_MEM_REQUEST:\\s+32 \(requests.memory\)           |
      | MY_MEM_LIMIT:\\s+node allocatable \(limits.memory\) |

