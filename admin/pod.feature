Feature: pod related features
  # @author xiuli@redhat.com
  # @case_id OCP-13540
  Scenario: TolerationSeconds can only combine with NoExecute effect
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/tolerationSeconds.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/tolerationSeconds-invalid1.yaml |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/tolerations/tolerationSeconds-invalid2.yaml |
    Then the step should fail
    And the output should contain "Invalid value"

  # @author xiuli@redhat.com
  # @case_id OCP-12971
  Scenario: Pods creation is ordered in StatefulSet
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/statefulset/hello-statefulset-60sec-ready.yaml |
    Then the step should succeed

    Given the pod named "hello-statefulset-0" becomes present
    And the pod status becomes :running
    When 30 seconds have passed
    Then the pod named "hello-statefulset-1" does not exist

    When the pod named "hello-statefulset-1" becomes present
    Then the pod named "hello-statefulset-0" is ready

    Given the pod named "hello-statefulset-1" becomes ready

  # @author pruan@redhat.com
  # @case_id OCP-11262
  @admin
  Scenario: Create pod with podspec.containers[].securityContext.ReadOnlyRootFileSystem = nil|false|true should succeed with scc.ReadOnlyRootFilesystem=false
    Given I have a project
    And I select a random node's host
    And I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/authorization/scc/tc521573/readonly_false.json |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=disk-pod |
    And evaluation of `pod.container(user: user, name: 'disk-pod').id` is stored in the :container_id clipboard
    When I run commands on the host:
      | docker inspect <%= cb.container_id %> \|grep only |
    Then the step should succeed
    Then the output should match:
      | "ReadonlyRootfs":\s+false |
    And I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/authorization/scc/tc521573/readonly_true.json |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=disk-pod-true |
    And evaluation of `pod.container(user: user, name: 'disk-pod-true').id` is stored in the :container_id_2 clipboard
    When I run commands on the host:
      | docker inspect <%= cb.container_id_2 %> \|grep only |
    Then the step should succeed
    Then the output should match:
      | "ReadonlyRootfs":\s+true |

  # @author yinzhou@redhat.com
  # @case_id OCP-11395
  @admin
  Scenario: PDB take effective with absolute number
    Given I have a project
    Given I obtain test data file "pods/tc538208/pdb_positive_absolute_number.yaml"
    And I replace lines in "pdb_positive_absolute_number.yaml":
      | minAvailable: 2|minAvailable: 5|
    Then I run the :create admin command with:
      | f | pdb_positive_absolute_number.yaml |
      | n | <%= project.name %>               |
    Then the step should succeed
    When I run the :new_app client command with:
      | docker_image   | <%= project_docker_repo %>openshift/deployment-example |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete
    Then I run the :scale client command with:
      | resource | dc                 |
      | name     | deployment-example |
      | replicas | 6                  |
    Then the step should succeed
    Given I wait until number of replicas match "6" for replicationController "deployment-example-1"
    When I run the :label client command with:
      | resource  | pods     |
      | all       | true     |
      | key_val   | foo8=bar |
      | overwrite | true     |
    Then the step should succeed
    Given cluster role "cluster-admin" is added to the "first" user
    Given a pod becomes ready with labels:
      | foo8=bar |
    And evaluation of `pod.name` is stored in the :pod clipboard
    Given I obtain test data file "admin/Eviction.json"
    And I replace lines in "Eviction.json":
      | "name": "",    |"name": "<%= cb.pod %>",          |
      | "namespace": ""|"namespace": "<%= project.name %>"|
    When I perform the :create_pod_eviction rest request with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= cb.pod %>       |
      | payload_file | Eviction.json       |
    Then the step should succeed
    Then I run the :scale client command with:
      | resource | dc                 |
      | name     | deployment-example |
      | replicas | 5                  |
    Then the step should succeed
    Given I wait until number of replicas match "5" for replicationController "deployment-example-1"
    When I run the :label client command with:
      | resource  | pods     |
      | all       | true     |
      | key_val   | foo8=bar |
      | overwrite | true     |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | foo8=bar |
    And evaluation of `pod.name` is stored in the :pod1 clipboard
    And I replace lines in "Eviction.json":
      | "name": "<%= cb.pod %>",|"name": "<%= cb.pod1 %>",|
    When I perform the :create_pod_eviction rest request with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= cb.pod1 %>      |
      | payload_file | Eviction.json       |
    Then the step should fail
    Then I run the :scale client command with:
      | resource | dc                 |
      | name     | deployment-example |
      | replicas | 3                  |
    Then the step should succeed
    Given I wait until number of replicas match "3" for replicationController "deployment-example-1"
    Given a pod becomes ready with labels:
      | foo8=bar |
    And evaluation of `pod.name` is stored in the :pod2 clipboard
    And I replace lines in "Eviction.json":
      | "name": "<%= cb.pod1 %>",|"name": "<%= cb.pod2 %>",|
    When I perform the :create_pod_eviction rest request with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= cb.pod2 %>      |
      | payload_file | Eviction.json       |
    Then the step should fail
    And the output should contain "429"

  # @author yinzhou@redhat.com
  # @case_id OCP-11664
  @admin
  Scenario: PDB take effective with percentage number
    Given I have a project
    Given I obtain test data file "pods/tc538208/pdb_positive_absolute_number.yaml"
    And I replace lines in "pdb_positive_absolute_number.yaml":
      | minAvailable: 2|minAvailable: "80%"|
    Then I run the :create admin command with:
      | f | pdb_positive_absolute_number.yaml |
      | n | <%= project.name %>               |
    Then the step should succeed
    When I run the :new_app client command with:
      | docker_image   | <%= project_docker_repo %>openshift/deployment-example |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete
    Then I run the :scale client command with:
      | resource | dc                 |
      | name     | deployment-example |
      | replicas | 5                  |
    Then the step should succeed
    Given I wait until number of replicas match "5" for replicationController "deployment-example-1"
    When I run the :label client command with:
      | resource  | pods     |
      | all       | true     |
      | key_val   | foo8=bar |
      | overwrite | true     |
    Then the step should succeed
    Given cluster role "cluster-admin" is added to the "first" user
    Given a pod becomes ready with labels:
      | foo8=bar |
    And evaluation of `pod.name` is stored in the :pod clipboard
    Given I obtain test data file "admin/Eviction.json"
    And I replace lines in "Eviction.json":
      | "name": "",    |"name": "<%= cb.pod %>",          |
      | "namespace": ""|"namespace": "<%= project.name %>"|
    When I perform the :create_pod_eviction rest request with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= cb.pod %>       |
      | payload_file | Eviction.json       |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | foo8=bar |
    And evaluation of `pod.name` is stored in the :pod2 clipboard
    And I replace lines in "Eviction.json":
      | "name": "<%= cb.pod %>",|"name": "<%= cb.pod2 %>",|
    When I perform the :create_pod_eviction rest request with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= cb.pod2 %>      |
      | payload_file | Eviction.json       |
    Then the step should fail
    And the output should contain "429"

  # @author chezhang@redhat.com
  # @case_id OCP-11366
  @admin
  @destructive
  Scenario: NodeStatus and PodStatus show correct imageID while pulling by tag
    Given I store the schedulable nodes in the :nodes clipboard
    Given I use the "<%= cb.nodes[0].name %>" node
    Given I run commands on the host:
      | docker rmi -f  docker.io/ocpqe/hello-pod:latest                                                                  |
      | docker rmi -f  docker.io/ocpqe/hello-pod@sha256:04b6af86b03c1836211be2589db870dba09b7811c197c47c07fbbe33c7f80ef7 |
      | docker images --digests \| grep docker.io/ocpqe/hello-pod                                                        |
    Then the step should fail
    Given I have a project
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    Then the step should succeed
    Given I obtain test data file "pods/pod-hostname.yaml"
    When I replace lines in "pod-hostname.yaml":
      | image: docker.io/deshuai/hello-pod:latest | image: docker.io/ocpqe/hello-pod:latest |
      | HOSTNAME                                  | <%= cb.nodes[0].name %>                 |
    Then I run the :create client command with:
      | f | pod-hostname.yaml |
    And the step should succeed
    When the pod named "pod-hostname" status becomes :running
    Then I wait up to 30 seconds for the steps to pass:
    """
    When I run the :get admin command with:
      | resource      | no                      |
      | resource_name | <%= cb.nodes[0].name %> |
      | o             | yaml                    |
    Then the output should contain:
      | - docker.io/ocpqe/hello-pod@sha256:04b6af86b03c1836211be2589db870dba09b7811c197c47c07fbbe33c7f80ef7 |
      | - docker.io/ocpqe/hello-pod:latest                                                                  |
    """
    When I run the :get client command with:
      | resource      | po           |
      | resource_name | pod-hostname |
      | o             | yaml         |
    Then the output should match:
      | - containerID: docker://                                                                          |
      | image: docker.io/ocpqe/hello-pod:latest                                                           |
      | imageID: docker-pullable.*sha256:04b6af86b03c1836211be2589db870dba09b7811c197c47c07fbbe33c7f80ef7 |

  # @author chuyu@redhat.com
  # @case_id OCP-12898
  @admin
  Scenario: PDB take effective with absolute number with beta1
    Given I have a project
    Given I obtain test data file "pods/ocp12897/pdb_positive_absolute_number.yaml"
    And I replace lines in "pdb_positive_absolute_number.yaml":
      | minAvailable: 2|minAvailable: 5|
    Then I run the :create admin command with:
      | f | pdb_positive_absolute_number.yaml |
      | n | <%= project.name %>               |
    Then the step should succeed
    When I run the :new_app client command with:
      | docker_image   | <%= project_docker_repo %>openshift/deployment-example |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete
    Then I run the :scale client command with:
      | resource | dc                 |
      | name     | deployment-example |
      | replicas | 6                  |
    Then the step should succeed
    Given I wait until number of replicas match "6" for replicationController "deployment-example-1"
    When I run the :label client command with:
      | resource  | pods     |
      | l         | app      |
      | key_val   | foo8=bar |
    Then the step should succeed
    Given cluster role "cluster-admin" is added to the "first" user
    Given 6 pods become ready with labels:
      | foo8=bar |
    And evaluation of `pod.name` is stored in the :pod clipboard
    Given I obtain test data file "admin/Eviction.json"
    And I replace lines in "Eviction.json":
      | "apiVersion": "policy/v1alpha1", | "apiVersion": "policy/v1beta1",    |
      | "name": "",                      | "name": "<%= cb.pod %>",           |
      | "namespace": ""                  | "namespace": "<%= project.name %>" |
    When I perform the :create_pod_eviction rest request with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= cb.pod %>       |
      | payload_file | Eviction.json       |
    Then the step should succeed
    Then I run the :scale client command with:
      | resource | dc                 |
      | name     | deployment-example |
      | replicas | 5                  |
    Then the step should succeed
    # Fix to ensure being-Terminating pod not labeled and cached
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource    | pod    |
      | l           | app    |
    Then the step should succeed
    And the output should contain 5 times:
      | deployment-example |
    """
    When I run the :label client command with:
      | resource  | pods     |
      | l         | app      |
      | key_val   | foo8=bar |
      | overwrite | true     |
    Then the step should succeed
    And a pod becomes ready with labels:
      | foo8=bar |
    And evaluation of `pod.name` is stored in the :pod1 clipboard
    And I replace lines in "Eviction.json":
      | "name": "<%= cb.pod %>",|"name": "<%= cb.pod1 %>",|
    When I perform the :create_pod_eviction rest request with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= cb.pod1 %>      |
      | payload_file | Eviction.json       |
    Then the step should fail
    Then I run the :scale client command with:
      | resource | dc                 |
      | name     | deployment-example |
      | replicas | 3                  |
    Then the step should succeed
    # Fix to ensure being-Terminating pod not cached
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource    | pod    |
      | l           | app    |
    Then the step should succeed
    And the output should contain 3 times:
      | deployment-example |
    """
    And a pod becomes ready with labels:
      | foo8=bar |
    And evaluation of `pod.name` is stored in the :pod2 clipboard
    And I replace lines in "Eviction.json":
      | "name": "<%= cb.pod1 %>",|"name": "<%= cb.pod2 %>",|
    When I perform the :create_pod_eviction rest request with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= cb.pod2 %>      |
      | payload_file | Eviction.json       |
    Then the step should fail
    And the expression should be true> @result[:exitstatus] == 429

  # @author chuyu@redhat.com
  # @case_id OCP-12900
  @admin
  Scenario: PDB take effective with percentage number with beta1
    Given I have a project
    Given I obtain test data file "pods/ocp12897/pdb_positive_absolute_number.yaml"
    And I replace lines in "pdb_positive_absolute_number.yaml":
      | minAvailable: 2|minAvailable: "80%"|
    Then I run the :create admin command with:
      | f | pdb_positive_absolute_number.yaml |
      | n | <%= project.name %>               |
    Then the step should succeed
    When I run the :new_app client command with:
      | docker_image   | <%= project_docker_repo %>openshift/deployment-example |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete
    Then I run the :scale client command with:
      | resource | dc                 |
      | name     | deployment-example |
      | replicas | 5                  |
    Then the step should succeed
    Given 5 pods become ready with labels:
      | app=deployment-example  |
    When I run the :label client command with:
      | resource  | pods                   |
      | l         | app=deployment-example |
      | key_val   | foo8=bar               |
      | overwrite | true                   |
    Then the step should succeed
    Given cluster role "cluster-admin" is added to the "first" user
    Given a pod becomes ready with labels:
      | foo8=bar |
    And evaluation of `pod.name` is stored in the :pod clipboard
    Given I obtain test data file "admin/Eviction.json"
    And I replace lines in "Eviction.json":
      | "apiVersion": "policy/v1alpha1", | "apiVersion": "policy/v1beta1",   |
      | "name": "",                      |"name": "<%= cb.pod %>",           |
      | "namespace": ""                  |"namespace": "<%= project.name %>" |
    When I perform the :create_pod_eviction rest request with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= cb.pod %>       |
      | payload_file | Eviction.json       |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | foo8=bar |
    And evaluation of `pod.name` is stored in the :pod2 clipboard
    And I replace lines in "Eviction.json":
      | "name": "<%= cb.pod %>",|"name": "<%= cb.pod2 %>",|
    When I perform the :create_pod_eviction rest request with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= cb.pod2 %>      |
      | payload_file | Eviction.json       |
    Then the step should fail
    And the expression should be true> @result[:exitstatus] == 429

  # @author chuyu@redhat.com
  # @case_id OCP-13289
  @admin
  Scenario: PDBs represent percentage in StatefulSet
    Given I have a project
    Given I obtain test data file "pods/ocp12897/pdb_positive_absolute_number.yaml"
    And I replace lines in "pdb_positive_absolute_number.yaml":
      | minAvailable: 2|minAvailable: "80%"|
    Then I run the :create admin command with:
      | f | pdb_positive_absolute_number.yaml |
      | n | <%= project.name %>               |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/statefulset/hello-statefulset.yaml |
    Then the step should succeed
    Then I run the :scale client command with:
      | resource | statefulset       |
      | name     | hello-statefulset |
      | replicas | 5                 |
    Then the step should succeed
    Given 5 pods become ready with labels:
      | app=hello-pod  |
    When I run the :label client command with:
      | resource  | pods     |
      | all       | true     |
      | key_val   | foo8=bar |
      | overwrite | true     |
    Then the step should succeed
    Given cluster role "cluster-admin" is added to the "first" user
    Given a pod becomes ready with labels:
      | foo8=bar |
    And evaluation of `pod.name` is stored in the :pod clipboard
    Given I obtain test data file "admin/Eviction.json"
    And I replace lines in "Eviction.json":
      | "apiVersion": "policy/v1alpha1", | "apiVersion": "policy/v1beta1",    |
      | "name": "",                      | "name": "<%= cb.pod %>",           |
      | "namespace": ""                  | "namespace": "<%= project.name %>" |
    When I perform the :create_pod_eviction rest request with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= cb.pod %>       |
      | payload_file | Eviction.json       |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | foo8=bar |
    And evaluation of `pod.name` is stored in the :pod2 clipboard
    And I replace lines in "Eviction.json":
      | "name": "<%= cb.pod %>",|"name": "<%= cb.pod2 %>",|
    When I perform the :create_pod_eviction rest request with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= cb.pod2 %>      |
      | payload_file | Eviction.json       |
    Then the step should fail
    And the expression should be true> @result[:exitstatus] == 429

  # @author chuyu@redhat.com
  # @case_id OCP-13303
  @admin
  Scenario: PDBs represent percentage in Deployment
    Given I have a project
    Given I obtain test data file "pods/ocp12897/pdb_positive_absolute_number.yaml"
    And I replace lines in "pdb_positive_absolute_number.yaml":
      | minAvailable: 2|minAvailable: "90%"|
    Then I run the :create admin command with:
      | f | pdb_positive_absolute_number.yaml |
      | n | <%= project.name %>               |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/hello-deployment-1.yaml |
    Then the step should succeed
    And I wait until number of replicas match "10" for deployment "hello-openshift"
    Given 10 pods become ready with labels:
      | app=hello-openshift  |
    When I run the :label client command with:
      | resource  | pods     |
      | all       | true     |
      | key_val   | foo8=bar |
      | overwrite | true     |
    Then the step should succeed
    Given cluster role "cluster-admin" is added to the "first" user
    Given a pod becomes ready with labels:
      | foo8=bar |
    And evaluation of `pod.name` is stored in the :pod clipboard
    Given I obtain test data file "admin/Eviction.json"
    And I replace lines in "Eviction.json":
      | "apiVersion": "policy/v1alpha1", | "apiVersion": "policy/v1beta1",    |
      | "name": "",                      | "name": "<%= cb.pod %>",           |
      | "namespace": ""                  | "namespace": "<%= project.name %>" |
    When I perform the :create_pod_eviction rest request with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= cb.pod %>       |
      | payload_file | Eviction.json       |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | foo8=bar |
    And evaluation of `pod.name` is stored in the :pod2 clipboard
    And I replace lines in "Eviction.json":
      | "name": "<%= cb.pod %>",|"name": "<%= cb.pod2 %>",|
    When I perform the :create_pod_eviction rest request with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= cb.pod2 %>      |
      | payload_file | Eviction.json       |
    Then the step should fail
    And the expression should be true> @result[:exitstatus] == 429

  # @author chuyu@redhat.com
  # @case_id OCP-13305
  @admin
  Scenario: PDBs represent percentage in ReplicaSet
    Given I have a project
    Given I obtain test data file "pods/ocp12897/pdb_positive_absolute_number.yaml"
    And I replace lines in "pdb_positive_absolute_number.yaml":
      | minAvailable: 2|minAvailable: "80%"|
    Then I run the :create admin command with:
      | f | pdb_positive_absolute_number.yaml |
      | n | <%= project.name %>               |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/replicaSet/tc533163/rs.yaml |
    Then the step should succeed
    Then I run the :scale client command with:
      | resource | replicaset |
      | name     | frontend   |
      | replicas | 5          |
    Then the step should succeed
    Given 5 pods become ready with labels:
      | app=guestbook  |
    When I run the :label client command with:
      | resource  | pods     |
      | all       | true     |
      | key_val   | foo8=bar |
      | overwrite | true     |
    Then the step should succeed
    Given cluster role "cluster-admin" is added to the "first" user
    Given a pod becomes ready with labels:
      | foo8=bar |
    And evaluation of `pod.name` is stored in the :pod clipboard
    Given I obtain test data file "admin/Eviction.json"
    And I replace lines in "Eviction.json":
      | "apiVersion": "policy/v1alpha1", | "apiVersion": "policy/v1beta1",   |
      | "name": "",                      |"name": "<%= cb.pod %>",           |
      | "namespace": ""                  |"namespace": "<%= project.name %>" |
    When I perform the :create_pod_eviction rest request with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= cb.pod %>       |
      | payload_file | Eviction.json       |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | foo8=bar |
    And evaluation of `pod.name` is stored in the :pod2 clipboard
    And I replace lines in "Eviction.json":
      | "name": "<%= cb.pod %>",|"name": "<%= cb.pod2 %>",|
    When I perform the :create_pod_eviction rest request with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= cb.pod2 %>      |
      | payload_file | Eviction.json       |
    Then the step should fail
    And the expression should be true> @result[:exitstatus] == 429

  # @author chezhang@redhat.com
  # @case_id OCP-13117
  @admin
  Scenario: SeLinuxOptions in pod should apply to container correctly
    Given I have a project
    Given SCC "privileged" is added to the "default" user
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/securityContext/pod-selinux.yaml |
    Then the step should succeed
    Given the pod named "selinux-pod" becomes ready
    When I run the :get client command with:
      | resource      | pod         |
      | resource_name | selinux-pod |
      | o             | json        |
    Then the step should succeed
    And the output by order should contain:
      | "securityContext"      |
      | "seLinuxOptions"       |
      |"level": "s0:c25,c968"  |
      | "role": "unconfined_r" |
      | "user": "unconfined_u" |
    And evaluation of `pod('selinux-pod').container(user: user, name: 'hello-pod', cached: true).id` is stored in the :containerID clipboard
    Given evaluation of `pod("selinux-pod").node_name(user: user)` is stored in the :node clipboard
    Given I use the "<%= cb.node %>" node
    Given I run commands on the host:
      | docker inspect <%= cb.containerID %>\|\| cat /run/containers/storage/overlay-containers/<%= cb.containerID.split("/").last %>/userdata/config.json |
    Then the step should succeed
    And the output should match:
      | unconfined_u:unconfined_r:(container_file_t\|svirt_lxc_net_t):s0:c25,c968 |

