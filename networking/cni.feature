Feature: CNI related features
  # @author bmeng@redhat.com
  # @case_id OCP-18499
  @admin
  Scenario: Will not log error when deleting the docker container of hostnetwork pod
    Given I have a project
    And SCC "privileged" is added to the "default" service account
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/hostnetwork-pod.json |
    Then the step should succeed
    And the pod named "hostnetwork-pod" becomes ready
    And evaluation of `pod.node_name` is stored in the :node_name clipboard

    Given I use the "<%= cb.node_name %>" node
    When I run commands on the host:
      | docker rm -f `docker ps \| grep hostnetwork-pod \| awk '{print $1}'` \|\| crictl rm -f `crictl ps \| grep hostnetwork-pod \| awk '{print $1}'`|
    Then the step should succeed
    When I run commands on the host:
      | journalctl -l --since "5 min ago" -u atomic-openshift-node \| grep cni.go |
    Then the output should not contain "CNI failed to retrieve network namespace path"
    And the output should not contain "No such container"
