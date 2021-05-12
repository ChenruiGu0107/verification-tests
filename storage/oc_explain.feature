Feature: oc explain resources for storage
  # @author lxia@redhat.com
  # @case_id OCP-27774
  Scenario: Use oc explain to see detailed documentation of basic storage resources
    Given the master version >= "4.1"
    And evaluation of `["PersistentVolume", "PersistentVolumeClaim", "pv", "pvc", "StorageClass", "sc"]` is stored in the :resources clipboard
    Given I repeat the following steps for each :resource in cb.resources:
    """
    When I run the :explain client command with:
      | resource | #{cb.resource} |
    Then the step should succeed
    And the output should contain:
      | apiVersion |
    And the output should not contain:
      | <empty> |
      | <none>  |
    """


  # @author lxia@redhat.com
  # @case_id OCP-27777
  Scenario: Use oc explain to see detailed documentation of CSI API related resources
    Given the master version >= "4.2"
    And evaluation of `["CSIDriver", "CSINode"]` is stored in the :resources clipboard
    Given I repeat the following steps for each :resource in cb.resources:
    """
    When I run the :explain client command with:
      | resource | #{cb.resource} |
    Then the step should succeed
    And the output should contain:
      | apiVersion |
    And the output should not contain:
      | <empty> |
      | <none>  |
    """


  # @author lxia@redhat.com
  # @case_id OCP-27779
  Scenario: Use oc explain to see detailed documentation of CSI snapshot related resources
    Given the master version >= "4.4"
    And evaluation of `["CSISnapshotController", "VolumeSnapshot", "VolumeSnapshotClass", "VolumeSnapshotContent"]` is stored in the :resources clipboard
    Given I repeat the following steps for each :resource in cb.resources:
    """
    When I run the :explain client command with:
      | resource | #{cb.resource} |
    Then the step should succeed
    And the output should contain:
      | apiVersion |
    And the output should not contain:
      | <empty> |
      | <none>  |
    """
