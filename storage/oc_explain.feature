Feature: oc explain resources for storage
  # @author lxia@redhat.com
  # @case_id OCP-27774
  Scenario Outline: Use oc explain to see detailed documentation of basic storage resources
    Given the master version >= "4.1"
    When I run the :explain client command with:
      | resource | <resource> |
    Then the step should succeed
    And the output should contain:
      | apiVersion |
    And the output should not contain:
      | <empty> |
      | <none>  |

    Examples:
      | resource              |
      | PersistentVolume      |
      | PersistentVolumeClaim |
      | pv                    |
      | pvc                   |
      | StorageClass          |
      | sc                    |


  # @author lxia@redhat.com
  # @case_id OCP-27777
  Scenario Outline: Use oc explain to see detailed documentation of CSI API related resources
    Given the master version >= "4.2"
    When I run the :explain client command with:
      | resource | <resource> |
    Then the step should succeed
    And the output should contain:
      | apiVersion |
    And the output should not contain:
      | <empty> |
      | <none>  |

    Examples:
      | resource  |
      | CSIDriver |
      | CSINode   |


  # @author lxia@redhat.com
  # @case_id OCP-27779
  Scenario Outline: Explain for CSI snapshot related resources
    Given the master version >= "4.4"
    When I run the :explain client command with:
      | resource | <resource> |
    Then the step should succeed
    And the output should contain:
      | apiVersion |
    And the output should not contain:
      | <empty> |
      | <none>  |

    Examples:
      | resource              |
      | CSISnapshotController |
      | VolumeSnapshot        |
      | VolumeSnapshotClass   |
      | VolumeSnapshotContent |
