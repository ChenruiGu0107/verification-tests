Feature: API server related custom resource features

  # @author kewang@redhat.com
  # @case_id OCP-22578
  Scenario Outline: Explain for CRD of config.openshift.io
    When I run the :explain client command with:
      | resource    | <item>                 |
      | api_version | config.openshift.io/v1 |
    Then the step should succeed
    And the output should contain:
      | KIND        |
      | VERSION     |
      | DESCRIPTION |
    And the output should not contain:
      | <empty> |

    When I run the :explain client command with:
      | resource    | <item>.spec            |
      | api_version | config.openshift.io/v1 |
    Then the step should succeed
    And the output should contain:
      | KIND        |
      | VERSION     |
      | DESCRIPTION |
    And the output should not contain:
      | <empty> |

    Examples:
      | item             |
      | clusteroperators |
      | clusterversions  |
      | infrastructures  |
      | authentications  |
      | oauths           |
      | featuregates     |
      | projects         |
      | schedulers       |
      | apiservers       |
