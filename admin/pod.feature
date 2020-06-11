Feature: pod related features
  # @author xiuli@redhat.com
  # @case_id OCP-13540
  Scenario: TolerationSeconds can only combine with NoExecute effect
    Given I have a project
    Given I obtain test data file "pods/tolerations/tolerationSeconds.yaml"
    When I run the :create client command with:
      | f | tolerationSeconds.yaml |
    Then the step should succeed
    Given I obtain test data file "pods/tolerations/tolerationSeconds-invalid1.yaml"
    When I run the :create client command with:
      | f | tolerationSeconds-invalid1.yaml |
    Then the step should fail
    And the output should contain "Invalid value"
    Given I obtain test data file "pods/tolerations/tolerationSeconds-invalid2.yaml"
    When I run the :create client command with:
      | f | tolerationSeconds-invalid2.yaml |
    Then the step should fail
    And the output should contain "Invalid value"

  # @author xiuli@redhat.com
  # @case_id OCP-12971
  Scenario: Pods creation is ordered in StatefulSet
    Given I have a project
    Given I obtain test data file "statefulset/hello-statefulset-60sec-ready.yaml"
    When I run the :create client command with:
      | f | hello-statefulset-60sec-ready.yaml |
    Then the step should succeed

    Given the pod named "hello-statefulset-0" becomes present
    And the pod status becomes :running
    When 30 seconds have passed
    Then the pod named "hello-statefulset-1" does not exist

    When the pod named "hello-statefulset-1" becomes present
    Then the pod named "hello-statefulset-0" is ready

    Given the pod named "hello-statefulset-1" becomes ready

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
      | resource  | pods                                |
      | l         | deploymentconfig=deployment-example |
      | key_val   | foo8=bar                            |
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
      | resource    | pod                                 |
      | l           | deploymentconfig=deployment-example |
    Then the step should succeed
    And the output should contain 5 times:
      | deployment-example |
    """
    When I run the :label client command with:
      | resource  | pods                                |
      | l         | deploymentconfig=deployment-example |
      | key_val   | foo8=bar                            |
      | overwrite | true                                |
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
      | resource    | pod                                 |
      | l           | deploymentconfig=deployment-example |
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
    When I run the :create_deploymentconfig client command with:
      | image | <%= project_docker_repo %>openshift/deployment-example |
      | name  | deployment-example                                     |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete
    Then I run the :scale client command with:
      | resource | dc                 |
      | name     | deployment-example |
      | replicas | 5                  |
    Then the step should succeed
    Given 5 pods become ready with labels:
      | deploymentconfig=deployment-example |
    When I run the :label client command with:
      | resource  | pods                                |
      | l         | deploymentconfig=deployment-example |
      | key_val   | foo8=bar                            |
      | overwrite | true                                |
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
    Given I obtain test data file "statefulset/hello-statefulset.yaml"
    When I run the :create client command with:
      | f | hello-statefulset.yaml |
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
    Given I obtain test data file "deployment/hello-deployment-1.yaml"
    When I run the :create client command with:
      | f | hello-deployment-1.yaml |
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
    Given I obtain test data file "replicaSet/tc533163/rs.yaml"
    When I run the :create client command with:
      | f | rs.yaml |
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
    Given I obtain test data file "pods/securityContext/pod-selinux.yaml"
    When I run the :create client command with:
      | f | pod-selinux.yaml |
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

