Feature: Update emptyDir volumes via command: oc set volumes

  # @author lxia@redhat.com
  # @case_id OCP-27288
  Scenario: Add emptyDir volume to deploymentconfig via oc set volumes
    Given I have a project
    When I run the :new_app client command with:
      | template | openshift/jenkins-ephemeral |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=jenkins |

    When I run the :set_volume client command with:
      | resource   | dc/jenkins |
      | action     | --add      |
      | type       | emptyDir   |
      | mount-path | /mypath    |
      | name       | myvolume   |
    Then the step should succeed
    And I wait for the resource "pod" named "<%= pod.name %>" to disappear
    And a pod becomes ready with labels:
      | name=jenkins |

    Given the expression should be true> dc('jenkins').containers_spec.first.volume_mounts.last['mountPath'] == "/mypath"
    Given the expression should be true> dc('jenkins').containers_spec.first.volume_mounts.last['name'] == "myvolume"
    When I execute on the pod:
      | mount |
    Then the step should succeed
    And the output should contain "/mypath"
    When I execute on the pod:
      | df | -h | /mypath |
    Then the step should succeed


  # @author lxia@redhat.com
  # @case_id OCP-27289
  Scenario: Remove emptyDir volume from deploymentconfig via oc set volumes
    Given I have a project
    When I run the :new_app client command with:
      | template | openshift/jenkins-ephemeral |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=jenkins |

    When I run the :set_volume client command with:
      | resource   | dc/jenkins   |
      | action     | --remove     |
      | name       | jenkins-data |
    Then the step should succeed
    And I wait for the resource "pod" named "<%= pod.name %>" to disappear
    And a pod becomes ready with labels:
      | name=jenkins |

    When I run the :get client command with:
      | resource | dc/jenkins                           |
      | o        | custom-columns=volume:..volumeMounts |
    Then the step should succeed
    And the output should not contain:
      | /var/lib/jenkins |
    When I execute on the pod:
      | mount |
    Then the step should succeed
    And the output should not contain "/var/lib/jenkins"
    When I execute on the pod:
      | df | -h |
    Then the step should succeed
    And the output should not contain "/var/lib/jenkins"
