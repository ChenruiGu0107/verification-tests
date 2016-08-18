Feature: Target pvc to a specific pv
	
  # @author chaoyang@redhat.com
  # @case_id 531523
  @admin
  @destructive
  Scenario: Target pvc to a specific pv with label selector
    Given I have a project
    And I register clean-up steps:
     | I run the :delete admin command with: |
     | ! object_type ! pv               !    |
     | ! l           ! usedFor=tc531523 !    |
     | the step should succeed               |

    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/labelmatch/pv1.json"
    Then I replace lines in "pv1.json":
      | nfs-pv-1a | nfspv1-<%= project.name %> |
      | nfs-pv-1b | nfspv2-<%= project.name %> |
    Then I run the :new_app admin command with:
      | file | pv1.json |
    Then the step should succeed
    Then I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/labelmatch/pvc1.json" replacing paths:
      | ["metadata"]["name"]| nfsc-<%= project.name %> |
    Then the step should succeed
    Then the "nfsc-<%= project.name %>" PVC becomes bound to the "nfspv1-<%= project.name %>" PV
    And the "nfspv2-<%= project.name %>" PV status is :available

  # @author chaoyang@redhat.com
  # @case_id 531521
  @admin
  @destructive
  Scenario: PVC could not bind PV with label selector matches but binding requirements are not met
    Given I have a project
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/labelmatch/pv2.json" where:
      | ["metadata"]["name"] | nfspv-<%= project.name %> |
    Then the step should succeed
    Then I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/labelmatch/pvc2.json" replacing paths:
      | ["items"][0]["metadata"]["name"] | nfsc1-<%= project.name %> |
      | ["items"][1]["metadata"]["name"] | nfsc2-<%= project.name %> |
    Then the step should succeed
    And the "nfsc1-<%= project.name %>" PVC becomes :pending
    And the "nfsc2-<%= project.name %>" PVC becomes :pending
    And the "nfspv-<%= project.name %>" PV status is :available

  # @author chaoyang@redhat.com
  # @case_id 531516
  @admin
  @destructive
  Scenario: PVC with less label selectors could bound to PV 
    Given I have a project
    And I register clean-up steps:
     | I run the :delete admin command with: |
     | ! object_type ! pv               !    |
     | ! l           ! usedFor=tc531516 !    |
     | the step should succeed               |

    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/labelmatch/pv3.json"
    Then I replace lines in "pv3.json":
      | nfs-pv-3a | nfspv1-<%= project.name %> |
      | nfs-pv-3b | nfspv2-<%= project.name %> |
    Then I run the :new_app admin command with:
      | file | pv3.json |
    Then the step should succeed
    Then I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/labelmatch/pvc3.json" replacing paths:
      | ["items"][0]["metadata"]["name"] | nfsc1-<%= project.name %> |
      | ["items"][1]["metadata"]["name"] | nfsc2-<%= project.name %> |
      | ["items"][2]["metadata"]["name"] | nfsc3-<%= project.name %> |
    Then the step should succeed
    And the "nfsc1-<%= project.name %>" PVC becomes bound to the "nfspv1-<%= project.name %>" PV
    And the "nfsc2-<%= project.name %>" PVC becomes :pending
    And the "nfsc3-<%= project.name %>" PVC becomes :pending
    And the "nfspv2-<%= project.name %>" PV status is :available

  # @author chaoyang@redhat.com
  # @case_id 531522
  @admin
  @destructive
  Scenario: Target pvc to a best fit size pv with same label selector
    Given I have a project
    And I register clean-up steps:
     | I run the :delete admin command with: |
     | ! object_type ! pv               !    |
     | ! l           ! usedFor=tc531522 !    |
     | the step should succeed               |

    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/labelmatch/pv4.json"
    Then I replace lines in "pv4.json":
      | nfs-pv-4a | nfspv1-<%= project.name %> |
      | nfs-pv-4b | nfspv2-<%= project.name %> |
    Then I run the :new_app admin command with:
      | file | pv4.json |
    Then the step should succeed
    Then I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/labelmatch/pvc4.json" replacing paths:
      | ["metadata"]["name"] | nfsc1-<%= project.name %> |
    Then the step should succeed
    And the "nfsc1-<%= project.name %>" PVC becomes bound to the "nfspv1-<%= project.name %>" PV
    And the "nfspv2-<%= project.name %>" PV status is :available

  # @author chaoyang@redhat.com
  # @case_id 531520
  @admin
  @destructive
  Scenario: PVC could bind prebound PV with mismatched label
    Given I have a project
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/labelmatch/pv5.json" where:
      | ["metadata"]["name"]              | nfspv1-<%= project.name %> |
      | ["spec"]["claimRef"]["namespace"] | <%= project.name %>        |
      | ["spec"]["claimRef"]["name"]      | nfsc1-<%= project.name %>  |
    Then the step should succeed
    Then I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/labelmatch/pvc5.json" replacing paths:
      | ["metadata"]["name"]   | nfsc1-<%= project.name %>  |
    Then the step should succeed
    And the "nfsc1-<%= project.name %>" PVC becomes bound to the "nfspv1-<%= project.name %>" PV

  # @author chaoyang@redhat.com
  # @case_id 531518
  @admin
  @destructive
  Scenario: Prebound PVC could bind to pv and ignore the label selector 
    Given I have a project
    And I register clean-up steps:
     | I run the :delete admin command with: |
     | ! object_type ! pv               !    |
     | ! l           ! usedFor=tc531518 !    |
     | the step should succeed               |

    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/labelmatch/pv6.json"
    Then I replace lines in "pv6.json":
      | nfs-pv-6a | nfspv1-<%= project.name %> |
      | nfs-pv-6b | nfspv2-<%= project.name %> |
    Then I run the :new_app admin command with:
      | file | pv6.json |
    Then the step should succeed
    Then I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/labelmatch/pvc6.json" replacing paths:
      | ["metadata"]["name"]   | nfsc1-<%= project.name %>  |
      | ["spec"]["volumeName"] | nfspv2-<%= project.name %> |
    Then the step should succeed
    And the "nfsc1-<%= project.name %>" PVC becomes bound to the "nfspv2-<%= project.name %>" PV
    And the "nfspv1-<%= project.name %>" PV status is :available

  # @author chaoyang@redhat.com
  # @case_id 531519
  @admin
  @destructive
  Scenario: PVC and PV still bound after remove the pv label
    Given I have a project
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/labelmatch/pv7.json" where:
      | ["metadata"]["name"] | nfspv1-<%= project.name %> |
    Then the step should succeed
    Then I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/labelmatch/pvc7.json" replacing paths:
      | ["metadata"]["name"]   | nfsc1-<%= project.name %>  |
    Then the step should succeed 
    And the "nfsc1-<%= project.name %>" PVC becomes bound to the "nfspv1-<%= project.name %>" PV
    Then I run the :label admin command with:
      | resource | pv                         |
      | name     | nfspv1-<%= project.name %> |
      | key_val  | aws-availability-zone-     |
    Then the step should succeed
    And I run the :label admin command with:
      | resource | pv                         |
      | name     | nfspv1-<%= project.name %> |
      | key_val  | ebs-volume-type-           |
    And the "nfsc1-<%= project.name %>" PVC becomes bound to the "nfspv1-<%= project.name %>" PV

  # @author chaoyang@redhat.com
  # @case_id 531524
  @admin
  @destructive
  Scenario: Target pvc to pv with same label selector and multi accessmode
    Given I have a project
    And I register clean-up steps:
     | I run the :delete admin command with: |
     | ! object_type ! pv               !    |
     | ! l           ! usedFor=tc531524 !    |
     | the step should succeed               |

    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/labelmatch/pv8.json"
    Then I replace lines in "pv8.json":
      | nfs-pv-8a | nfspv1-<%= project.name %> |
      | nfs-pv-8b | nfspv2-<%= project.name %> |
      | nfs-pv-8c | nfspv3-<%= project.name %> |
    Then I run the :new_app admin command with:
      | file | pv8.json |
    Then the step should succeed
    Then I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/labelmatch/pvc8.json" replacing paths:
      | ["items"][0]["metadata"]["name"] | nfsc1-<%= project.name %> |
      | ["items"][1]["metadata"]["name"] | nfsc2-<%= project.name %> |
      | ["items"][2]["metadata"]["name"] | nfsc3-<%= project.name %> |
    Then the step should succeed
    And the "nfsc1-<%= project.name %>" PVC becomes bound to the "nfspv1-<%= project.name %>" PV
    And the "nfsc2-<%= project.name %>" PVC becomes bound to the "nfspv2-<%= project.name %>" PV
    And the "nfsc3-<%= project.name %>" PVC becomes bound to the "nfspv3-<%= project.name %>" PV

  # @author chaoyang@redhat.com
  # @case_id 531517
  @admin
  @destructive
  Scenario: PVC without any VolumeSelector could bind a PV with any labels
    Given I have a project
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/labelmatch/pv2.json" where:
      | ["metadata"]["name"] | nfspv1-<%= project.name %> |
    Then the step should succeed
    Then I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/claim.json" replacing paths:
      | ["metadata"]["name"]                         | nfsc1-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                       |
    Then the step should succeed
    And the "nfsc1-<%= project.name %>" PVC becomes bound to the "nfspv1-<%= project.name %>" PV
