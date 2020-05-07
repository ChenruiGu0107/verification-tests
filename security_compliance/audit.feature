Feature: Audit logs related scenarios
  # @author pdhamdhe@redhat.com
  # @case_id OCP-25829
  @admin
  Scenario: from log, we can specify what user from the specific IdP did a certain action in the cluster
    Given the master version >= "4.3"
    # Create a new project and deploy application using normal user
    And evaluation of `user(0).uid` is stored in the :users_uid clipboard
    Given I have a project
    When I run the :new_app client command with:
      | docker_image | quay.io/openshifttest/hello-openshift@sha256:424e57db1f2e8e8ac9087d2f5e8faea6d73811f0b6f96301bc94293680897073 |
    Then the step should succeed
    And the pod named "hello-openshift-1-deploy" becomes present

    # Repeat the same step and it should fail
    When I run the :new_app client command with:
      | docker_image | quay.io/openshifttest/hello-openshift@sha256:424e57db1f2e8e8ac9087d2f5e8faea6d73811f0b6f96301bc94293680897073 |
    Then the step should fail

    # Scale deploymentconfig
    When I run the :scale client command with:
      | resource | dc                  |
      | name     | hello-openshift     |
      | replicas | 2                   |
    Then the step should succeed
    And the output should contain "hello-openshift scaled"
    And I wait until the status of deployment "hello-openshift" becomes :complete

    # Rollout deploymentconfig
    When I run the :rollout_latest client command with:
      | resource | dc/hello-openshift  |
    Then the step should succeed
    And the output should contain "rolled out"

    Given I store the masters in the :masters clipboard
    When I run the :debug admin command with:
      | resource | no/<%= cb.masters[0].name %> |
      | dry_run  | true                         |
      | o        | yaml                         |
    Then the step should succeed
    And I save the output to file> debug_pod.yaml
    When I run the :oadm_release_info admin command with:
      | image_for  | cli                                     |
      | image_name | <%= cluster_version('version').image %> |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :cli_image clipboard
    Given I have a project
    And I replace lines in "debug_pod.yaml":
      | /name.*debug/   | name: mypod                    |
      | /namespace: .*/ | namespace: <%= project.name %> |
      | /image: .*/     | image: <%= cb.cli_image %>     |
    Then the step should succeed
    When I run the :create admin command with:
      | f | debug_pod.yaml |
    Then the step should succeed
    And the pod named "mypod" becomes ready

    Given cluster role "cluster-admin" is added to the "system:serviceaccount:<%= project.name %>:default" service account

    # Verify if the normal user login entry captures in openshift-apiserver audit logs
    When admin executes on the pod:
      | bash | -c | oc adm node-logs --role=master --path=openshift-apiserver/audit.log \| grep "<%= cb.users_uid %>" |
    Then the step should succeed
    And the output should contain:
      | "user":{"name":"<%= user.name %>","uid":"<%= cb.users_uid %>"} |

    # Verify whatever action takes by normal user, the log entry captures in kube-apiserver audit logs
    When admin executes on the pod:
      | bash  | -c | oc adm node-logs --role=master --path=kube-apiserver/audit.log \| grep hello-openshift.*<%= cb.users_uid %> \| tail -5 |
    Then the step should succeed
    And the output should contain:
      | "namespace":"<%= project.name %>","name":"hello-openshift" |
    When admin executes on the pod:
      | bash  | -c | oc adm node-logs --role=master --path=kube-apiserver/audit.log \| grep <%= cb.users_uid %>.*AlreadyExists \| tail -5 |
    Then the step should succeed
    And the output should contain:
      | "status":"Failure","reason":"AlreadyExists","code":409 |
    When admin executes on the pod:
      | bash  | -c | oc adm node-logs --role=master --path=kube-apiserver/audit.log \| grep openshift/scale.*<%= cb.users_uid %> \| tail -5 |
    Then the step should succeed
    And the output should contain:
      | "subresource":"scale" |
    When admin executes on the pod:
      | bash  | -c | oc adm node-logs --role=master --path=kube-apiserver/audit.log \| grep <%= cb.users_uid %>.*replicationcontrollers \| tail -5 |
    Then the step should succeed
    And the output should contain:
      | "resource":"replicationcontrollers","namespace":"<%= project.name %>" |
