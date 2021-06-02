Feature: CSI snapshot webhook related scenarios
  # @author wduan@redhat.com
  # @case_id OCP-37741
  @admin
  Scenario: [csi-snapshot-webhook] Should be installed by default and managed by CSO
    Given the master version >= "4.7"
    When I switch to cluster admin pseudo user
    And I use the "openshift-cluster-storage-operator" project
    Then a pod becomes ready with labels:
      | app=csi-snapshot-webhook |
    And evaluation of `pod.name` is stored in the :pod_name clipboard

    When I run the :delete client command with:
      | object_type       | deployment           |
      | object_name_or_id | csi-snapshot-webhook |
    And the step should succeed
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I wait for the resource "pod" named "<%= cb.pod_name %>" to disappear
    And a pod becomes ready with labels:
      | app=csi-snapshot-webhook |
    """


  # @author wduan@redhat.com
  # @case_id OCP-37742
  @admin
  Scenario: [csi-snapshot-webhook] Should support setting log level by csi-snapshot-controller operator	
    Given the master version >= "4.7"
    When I switch to cluster admin pseudo user
    And I use the "openshift-cluster-storage-operator" project
    Then a pod becomes ready with labels:
      | app=csi-snapshot-webhook |
      
    When I run the :patch client command with:
      | resource      | csisnapshotcontrollers            |
      | resource_name | cluster                           |
      | p             | {"spec":{"logLevel": "TraceAll"}} |
      | type          | merge                             |
    Given I wait up to 90 seconds for the steps to pass:
    """
    Given a pod becomes ready with labels:
      | app=csi-snapshot-webhook |
    When I run the :get client command with:
      | resource      | deployment           |
      | resource_name | csi-snapshot-webhook |
      | o             | json                 |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["spec"]["template"]["spec"]["containers"][0]["args"].include? "--v=8"
    """

    When I run the :patch client command with:
      | resource      | csisnapshotcontrollers         |
      | resource_name | cluster                        |
      | p             | {"spec":{"logLevel": "Debug"}} |
      | type          | merge                          |
    Given I wait up to 90 seconds for the steps to pass:
    """
    Given a pod becomes ready with labels:
      | app=csi-snapshot-webhook |
    When I run the :get client command with:
      | resource      | deployment           |
      | resource_name | csi-snapshot-webhook |
      | o             | json                 |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["spec"]["template"]["spec"]["containers"][0]["args"].include? "--v=4"
    """

    When I run the :patch client command with:
      | resource      | csisnapshotcontrollers          |
      | resource_name | cluster                         |
      | p             | {"spec":{"logLevel": "Normal"}} |
      | type          | merge                           |
    Given I wait up to 90 seconds for the steps to pass:
    """
    Given a pod becomes ready with labels:
      | app=csi-snapshot-webhook |
    When I run the :get client command with:
      | resource      | deployment           |
      | resource_name | csi-snapshot-webhook |
      | o             | json                 |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["spec"]["template"]["spec"]["containers"][0]["args"].include? "--v=2"
    """
