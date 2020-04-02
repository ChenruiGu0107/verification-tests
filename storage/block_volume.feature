Feature: Scenarios specific for block volume support

  # @author lxia@redhat.com
  # @case_id OCP-26147
  @admin
  Scenario: VolumeMode defaults to Filesystem for manually provisioned volumes
    Given I have a project
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/iscsi/pv-rwx.json" where:
      | ["metadata"]["name"] | pv-<%= project.name %> |
    Then the step should succeed
    And the expression should be true> pv("pv-<%= project.name %>").volume_mode == "Filesystem"


  # @author lxia@redhat.com
  @admin
  Scenario Outline: User can manually create PV with specific VolumeMode
    Given I have a project
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/iscsi/pv-rwx.json" where:
      | ["metadata"]["name"]   | pv-<%= project.name %> |
      | ["spec"]["volumeMode"] | <volume-mode>          |
    Then the step should succeed
    And the expression should be true> pv("pv-<%= project.name %>").volume_mode == "<volume-mode>"
    Examples:
      | volume-mode |
      | Block       | # @case_id OCP-26143
      | Filesystem  | # @case_id OCP-26144


  # @author lxia@redhat.com
  # @case_id OCP-25861
  @admin
  Scenario: VolumeMode defaults to Filesystem for dynamic provisioned volumes
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["volumeBindingMode"] | Immediate |
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes :bound
    And the expression should be true> pvc.volume_mode == "Filesystem"
    And the expression should be true> pv(pvc.volume_name).volume_mode == "Filesystem"


  # @author lxia@redhat.com
  @admin
  Scenario Outline: User can create PVC with specific VolumeMode
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["volumeBindingMode"] | Immediate |
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["volumeMode"]       | <volume-mode>          |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes :bound
    And the expression should be true> pvc.volume_mode == "<volume-mode>"
    And the expression should be true> pv(pvc.volume_name).volume_mode == "<volume-mode>"
    Examples:
      | volume-mode |
      | Block       | # @case_id OCP-26148
      | Filesystem  | # @case_id OCP-26149
