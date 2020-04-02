Feature: Target pvc to a specific pv
	
  # @author chaoyang@redhat.com
  # @author lxia@redhat.com
  # @case_id OCP-12220
  @admin
  Scenario: Target pvc to a specific pv with label selector
    Given I have a project
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pv.json" where:
      | ["metadata"]["name"]           | pv1-<%= project.name %> |
      | ["metadata"]["labels"]["type"] | mytype1                 |
      | ["spec"]["storageClassName"]   | sc-<%= project.name %>  |
    Then the step should succeed
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pv.json" where:
      | ["metadata"]["name"]         | pv2-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>  |
    Then the step should succeed

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pvc.json" replacing paths:
      | ["metadata"]["name"]                        | mypvc                  |
      | ["spec"]["storageClassName"]                | sc-<%= project.name %> |
      | ["spec"]["selector"]["matchLabels"]["type"] | mytype1                |
    Then the step should succeed
    Then the "mypvc" PVC becomes bound to the "pv1-<%= project.name %>" PV
    And the "pv2-<%= project.name %>" PV status is :available

  # @author chaoyang@redhat.com
  # @author lxia@redhat.com
  # @case_id OCP-12077
  @admin
  Scenario: PVC could not bind PV with label selector matches but binding requirements are not met
    Given I have a project
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pv.json" where:
      | ["metadata"]["name"]           | pv-<%= project.name %> |
      | ["metadata"]["labels"]["type"] | mytype1                |
      | ["spec"]["storageClassName"]   | sc-<%= project.name %> |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | mypvc1                 |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %> |
      | ["spec"]["selector"]["matchLabels"]["type"]  | mytype1                |
      | ["spec"]["resources"]["requests"]["storage"] | 2Gi                    |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pvc.json" replacing paths:
      | ["metadata"]["name"]                        | mypvc2                 |
      | ["spec"]["storageClassName"]                | sc-<%= project.name %> |
      | ["spec"]["selector"]["matchLabels"]["type"] | mytype1                |
      | ["spec"]["accessModes"][0]                  | ReadWriteMany          |
    Then the step should succeed
    And the "mypvc1" PVC becomes :pending
    And the "mypvc2" PVC becomes :pending
    And the "pv-<%= project.name %>" PV status is :available

  # @author chaoyang@redhat.com
  # @author lxia@redhat.com
  # @case_id OCP-10890
  @admin
  Scenario: PVC with less label selectors could bound to PV
    Given I have a project
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pv.json" where:
      | ["metadata"]["name"]           | pv1-<%= project.name %> |
      | ["metadata"]["labels"]["type"] | mytype1                 |
      | ["metadata"]["labels"]["zone"] | myzone1                 |
      | ["spec"]["storageClassName"]   | sc-<%= project.name %>  |
    Then the step should succeed
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pv.json" where:
      | ["metadata"]["name"]         | pv2-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>  |
    Then the step should succeed

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pvc.json" replacing paths:
      | ["metadata"]["name"]                        | mypvc1                 |
      | ["spec"]["storageClassName"]                | sc-<%= project.name %> |
      | ["spec"]["selector"]["matchLabels"]["type"] | mytype1                |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pvc.json" replacing paths:
      | ["metadata"]["name"]                        | mypvc2                 |
      | ["spec"]["storageClassName"]                | sc-<%= project.name %> |
      | ["spec"]["selector"]["matchLabels"]["type"] | mytype2                |
      | ["spec"]["selector"]["matchLabels"]["zone"] | myzone1                |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pvc.json" replacing paths:
      | ["metadata"]["name"]                        | mypvc3                 |
      | ["spec"]["storageClassName"]                | sc-<%= project.name %> |
      | ["spec"]["selector"]["matchLabels"]["type"] | mytype1                |
      | ["spec"]["selector"]["matchLabels"]["zone"] | myzone1                |
      | ["spec"]["selector"]["matchLabels"]["more"] | any-value              |
    Then the step should succeed

    And the "mypvc1" PVC becomes bound to the "pv1-<%= project.name %>" PV
    And the "mypvc2" PVC becomes :pending
    And the "mypvc3" PVC becomes :pending
    And the "pv2-<%= project.name %>" PV status is :available

  # @author chaoyang@redhat.com
  # @author lxia@redhat.com
  # @case_id OCP-12164
  @admin
  Scenario: Target pvc to a best fit size pv with same label selector
    Given I have a project
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pv.json" where:
      | ["metadata"]["name"]            | pv1-<%= project.name %> |
      | ["metadata"]["labels"]["type"]  | mytype1                 |
      | ["spec"]["storageClassName"]    | sc-<%= project.name %>  |
      | ["spec"]["capacity"]["storage"] | 101Gi                   |
    Then the step should succeed
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pv.json" where:
      | ["metadata"]["name"]            | pv2-<%= project.name %> |
      | ["metadata"]["labels"]["type"]  | mytype1                 |
      | ["spec"]["storageClassName"]    | sc-<%= project.name %>  |
      | ["spec"]["capacity"]["storage"] | 102Gi                   |
    Then the step should succeed

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | mypvc                  |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %> |
      | ["spec"]["selector"]["matchLabels"]["type"]  | mytype1                |
      | ["spec"]["resources"]["requests"]["storage"] | 100Gi                  |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv1-<%= project.name %>" PV
    And the "pv2-<%= project.name %>" PV status is :available

  # @author chaoyang@redhat.com
  # @author lxia@redhat.com
  # @case_id OCP-11971
  @admin
  Scenario: PVC could bind prebound PV with mismatched label
    Given I have a project
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pv5.json" where:
      | ["metadata"]["name"]              | pv-<%= project.name %> |
      | ["spec"]["storageClassName"]      | sc-<%= project.name %> |
      | ["spec"]["claimRef"]["namespace"] | <%= project.name %>    |
      | ["spec"]["claimRef"]["name"]      | mypvc                  |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pvc5.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV

  # @author chaoyang@redhat.com
  # @author lxia@redhat.com
  # @case_id OCP-11609
  @admin
  Scenario: Prebound PVC could bind to pv and ignore the label selector
    Given I have a project
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pv.json" where:
      | ["metadata"]["name"]           | pv1-<%= project.name %> |
      | ["metadata"]["labels"]["type"] | mytype1                 |
      | ["spec"]["storageClassName"]   | sc-<%= project.name %>  |
    Then the step should succeed
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pv.json" where:
      | ["metadata"]["name"]         | pv2-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>  |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pvc.json" replacing paths:
      | ["metadata"]["name"]                        | mypvc                   |
      | ["spec"]["storageClassName"]                | sc-<%= project.name %>  |
      | ["spec"]["volumeName"]                      | pv2-<%= project.name %> |
      | ["spec"]["selector"]["matchLabels"]["type"] | mytype1                 |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv2-<%= project.name %>" PV
    And the "pv1-<%= project.name %>" PV status is :available

  # @author chaoyang@redhat.com
  # @author lxia@redhat.com
  # @case_id OCP-11810
  @admin
  Scenario: PVC and PV still bound after remove the pv label
    Given I have a project
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pv.json" where:
      | ["metadata"]["name"]           | pv-<%= project.name %> |
      | ["metadata"]["labels"]["type"] | mytype1                |
      | ["spec"]["storageClassName"]   | sc-<%= project.name %> |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pvc.json" replacing paths:
      | ["metadata"]["name"]                        | mypvc                   |
      | ["spec"]["storageClassName"]                | sc-<%= project.name %>  |
      | ["spec"]["selector"]["matchLabels"]["type"] | mytype1                 |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV
    When I run the :label admin command with:
      | resource | pv                     |
      | name     | pv-<%= project.name %> |
      | key_val  | type-                  |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV

  # @author chaoyang@redhat.com
  # @author lxia@redhat.com
  # @case_id OCP-12268
  @admin
  Scenario: Target pvc to pv with same label selector and multi accessmode
    Given I have a project
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pv.json" where:
      | ["metadata"]["name"]           | pv-<%= project.name %> |
      | ["metadata"]["labels"]["type"] | mytype1                |
      | ["spec"]["storageClassName"]   | sc-<%= project.name %> |
      | ["spec"]["accessModes"][0]     | ReadWriteOnce          |
      | ["spec"]["accessModes"][1]     | ReadWriteMany          |
      | ["spec"]["accessModes"][2]     | ReadOnlyMany           |
    Then the step should succeed

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pvc.json" replacing paths:
      | ["metadata"]["name"]                        | mypvc                  |
      | ["spec"]["storageClassName"]                | sc-<%= project.name %> |
      | ["spec"]["selector"]["matchLabels"]["type"] | mytype1                |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV

  # @author chaoyang@redhat.com
  # @author lxia@redhat.com
  # @case_id OCP-11307
  @admin
  Scenario: PVC without any VolumeSelector could bind a PV with any labels
    Given I have a project
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pv.json" where:
      | ["metadata"]["name"]           | pv-<%= project.name %> |
      | ["metadata"]["labels"]["type"] | mytype1                |
      | ["spec"]["storageClassName"]   | sc-<%= project.name %> |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/labelmatch/pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV
