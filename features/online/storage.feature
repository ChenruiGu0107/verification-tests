Feature: ONLY ONLINE Storage related scripts in this file

  # @author bingli@redhat.com
  # @case_id OCP-9967
  Scenario: Delete pod with mounting error
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/tc526564/pod_volumetest.json |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource | pod |
    Then the output should match:
      | volumetest\\s+0/1\\s+RunContainerError.+ |
    """
    When I run the :describe client command with:
      | resource | pod        |
      | name     | volumetest |
    Then the step should succeed
    And the output should contain:
      | mkdir /var/lib/docker/volumes/ |
      | permission denied              |
    When I run the :delete client command with:
      | object_type       | pod        |
      | object_name_or_id | volumetest |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource | pod |
    Then the output should not contain:
      | volumetest |
    """

  # @author yasun@redhat.com
  # @case_id OCP-9809
  Scenario: Pod should not create directories within /var/lib/docker/volumes/ on nodes
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json" replacing paths:
      | ["objects"][8]["spec"]["template"]["spec"]["containers"][0]["volumeMounts"] | null |
    Then the step should succeed
    When I run the :new_app client command with:
      | template | ruby-helloworld-sample |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource | pod |
    Then the output should match:
      | database-1-hook-pre\\s+0/1\\s+RunContainerError.+ |
    """
    When I run the :describe client command with:
      | resource | pod                 |
      | name     | database-1-hook-pre |
    Then the step should succeed
    And the output should contain:
      | mkdir /var/lib/docker/volumes/ |
      | permission denied              |

  # @author yasun@redhat.com
  # @case_id OCP-13108
  Scenario: Basic user could not get pv object info
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/claim.json" replacing paths:
      | ["metadata"]["name"]                           | ebsc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"]   | 1Gi                      |
    And the step should succeed
    And the "ebsc-<%= project.name %>" PVC becomes :bound
    And evaluation of `pvc("ebsc-#{project.name}").volume_name(user: user)` is stored in the :pv_name clipboard

    When I run the :describe client command with:
      | resource          | pvc                      |
      | name              | ebsc-<%= project.name %> |
    And the step should succeed

    When I run the :get client command with:
      | resource          | pv                |
      | resource_name     | <%= cb.pv_name %> |
    And the step should fail
    And the output should contain:
      | Forbidden     |
      | cannot get    |

    When I run the :describe client command with:
      | resource          | pv                |
      | name              | <%= cb.pv_name %> |
    And the step should fail
    And the output should contain:
      | Forbidden     |
      | cannot get    |

    When I run the :delete client command with:
      | object_type       | pv                |
      | object_name_or_id | <%= cb.pv_name %> |
    And the step should fail
    And the output should contain:
      | Forbidden     |
      | cannot delete |
 
