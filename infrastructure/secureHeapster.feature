Feature: Secure Heapster APIs scenarios
  # @author wjiang@redhat.com
  # @case_id OCP-13451
  @admin
  @destructive
  Scenario: heapster apis should be allowed if requestheader-username is granted via RBAC
    Given I have a project
    # Create configmap to use in heapster and the curl pod
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/logging_metrics/secure_heapster/cert-configmap.yaml |
    # Grant necessary permission to heapster serviceaccount
    Given cluster role "system:heapster" is added to the "heapster" service account
    Given cluster role "system:auth-delegator" is added to the "heapster" service account
    Given cluster role "system:node-reader" is added to the "heapster" service account
    # Setup heapster
    Given I obtain test data file "logging_metrics/secure_heapster/heapster_grafana_influxdb.yaml"
    And I replace lines in "heapster_grafana_influxdb.yaml":
      | kube-system | <%= project.name %>   |
    When I run the :create client command with:
      | f | heapster_grafana_influxdb.yaml  |
    Then the step should succeed
    # Wait all pods is up
    Given status becomes :running of 1 pods labeled:
      | k8s-app=heapster                  |
    Given status becomes :running of 1 pods labeled:
      | k8s-app=grafana                   |
    Given status becomes :running of 1 pods labeled:
      | k8s-app=influxdb                  |
    # Create the heapster-client pod to do the curl command in the pod
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/logging_metrics/secure_heapster/heapster-client.yaml |
    Then the step should succeed
    And the pod named "heapster-client" becomes ready
    Given I use the "heapster" service
    When I execute on the pod:
      | curl                                                              |
      | -sk                                                               |
      | https://<%= service.ip(user: user) %>/apis/metrics/v1alpha1/nodes |
    Then the step should succeed
    And the output should contain:
      | User "system:anonymous" cannot list nodes.metrics at the cluster scope. |
    When I execute on the pod:
      | curl                                                              |
      | -sk                                                               |
      | --cert                                                            |
      | /var/run/kubernetes/request-header-client.crt                     |
      | --key                                                             |
      | /var/run/kubernetes/request-header-client.key                     |
      | https://<%= service.ip(user: user) %>/apis/metrics/v1alpha1/nodes |
    Then the step should succeed
    And the output should contain:
      | User "system:anonymous" cannot list nodes.metrics at the cluster scope. |
    Given I select a random node's host
    Given I wait up to 150 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl                                                              |
      | -sk                                                               |
      | --cert                                                            |
      | /var/run/kubernetes/request-header-client.crt                     |
      | --key                                                             |
      | /var/run/kubernetes/request-header-client.key                     |
      | -H                                                                |
      | X-Remote-User: system:admin                                       |
      | https://<%= service.ip(user: user) %>/apis/metrics/v1alpha1/nodes |
    Then the output should contain:
      | <%= node.name %>                  |
    """

  # @author wjiang@redhat.com
  # @case_id OCP-13452
  @admin
  @destructive
  Scenario: heapster should support customized requestheader in authn/authz
    Given I have a project
    # Create configmap to use in heapster and the curl pod
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/logging_metrics/secure_heapster/cert-configmap.yaml |
    # Grant necessary permission to heapster serviceaccount
    Given cluster role "system:heapster" is added to the "heapster" service account
    Given cluster role "system:auth-delegator" is added to the "heapster" service account
    Given cluster role "system:node-reader" is added to the "heapster" service account
    # Setup heapster
    Given I obtain test data file "logging_metrics/secure_heapster/heapster_grafana_influxdb.yaml"
    And I replace lines in "heapster_grafana_influxdb.yaml":
      | kube-system | <%= project.name %> |
      | User      | Username              |
      | Group     | Groupname             |
    When I run the :create client command with:
      | f | heapster_grafana_influxdb.yaml    |
    Then the step should succeed
    # Wait all pods is up
    Given status becomes :running of 1 pods labeled:
      | k8s-app=heapster                  |
    Given status becomes :running of 1 pods labeled:
      | k8s-app=grafana                   |
    Given status becomes :running of 1 pods labeled:
      | k8s-app=influxdb                  |
    # Create the heapster-client pod to do the curl command in the pod
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/logging_metrics/secure_heapster/heapster-client.yaml |
    Then the step should succeed
    And the pod named "heapster-client" becomes ready
    Given I use the "heapster" service
    When I execute on the pod:
      | curl                                                              |
      | -sk                                                               |
      | --cert                                                            |
      | /var/run/kubernetes/request-header-client.crt                     |
      | --key                                                             |
      | /var/run/kubernetes/request-header-client.key                     |
      | -H                                                                |
      | X-Remote-User: system:admin                                       |
      | https://<%= service.ip(user: user) %>/apis/metrics/v1alpha1/nodes |
    Then the output should contain:
      | User "system:anonymous" cannot list nodes.metrics at the cluster scope  |
    Given I select a random node's host
    Given I wait up to 150 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl                                                              |
      | -sk                                                               |
      | --cert                                                            |
      | /var/run/kubernetes/request-header-client.crt                     |
      | --key                                                             |
      | /var/run/kubernetes/request-header-client.key                     |
      | -H                                                                |
      | X-Remote-Username: system:admin                                   |
      | https://<%= service.ip(user: user) %>/apis/metrics/v1alpha1/nodes |
    Then the output should contain:
      | <%= node.name %>                  |
    """
    When I execute on the pod:
      | curl                                                              |
      | -sk                                                               |
      | --cert                                                            |
      | /var/run/kubernetes/request-header-client.crt                     |
      | --key                                                             |
      | /var/run/kubernetes/request-header-client.key                     |
      | -H                                                                |
      | X-Remote-Username: <%= user.name %>                               |
      | -H                                                                |
      | X-Remote-Group: system:cluster-admins                             |
      | https://<%= service.ip(user: user) %>/apis/metrics/v1alpha1/nodes |
    Then the output should contain:
      | User "<%= user.name %>" cannot list nodes.metrics at the cluster scope |
    When I execute on the pod:
      | curl                                                              |
      | -sk                                                               |
      | --cert                                                            |
      | /var/run/kubernetes/request-header-client.crt                     |
      | --key                                                             |
      | /var/run/kubernetes/request-header-client.key                     |
      | -H                                                                |
      | X-Remote-Username: <%= user.name %>                               |
      | -H                                                                |
      | X-Remote-Groupname: system:cluster-admins                         |
      | https://<%= service.ip(user: user) %>/apis/metrics/v1alpha1/nodes |
    Then the output should contain:
      | <%= node.name%>                   |


  # @author wjiang@redhat.com
  # @case_id OCP-14836
  @admin
  @destructive
  Scenario: heapster apis should be allowed with all auth method(token, cert, requestheader)
    Given I have a project
    # Create configmap to use in heapster and the curl pod
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/logging_metrics/secure_heapster/cert-configmap.yaml |
    # Grant necessary permission to heapster serviceaccount
    Given cluster role "system:heapster" is added to the "heapster" service account
    Given cluster role "system:auth-delegator" is added to the "heapster" service account
    Given cluster role "system:node-reader" is added to the "heapster" service account
    # Setup heapster
    Given I obtain test data file "logging_metrics/secure_heapster/heapster_grafana_influxdb.yaml"
    And I replace lines in "heapster_grafana_influxdb.yaml":
      | kube-system | <%= project.name %>   |
      | tls-ca      | client-ca             |
    When I run the :create client command with:
      | f | heapster_grafana_influxdb.yaml  |
    Then the step should succeed
    # Wait all pods is up
    Given status becomes :running of 1 pods labeled:
      | k8s-app=heapster                  |
    Given status becomes :running of 1 pods labeled:
      | k8s-app=grafana                   |
    Given status becomes :running of 1 pods labeled:
      | k8s-app=influxdb                  |
    # Create the heapster-client pod to do the curl command in the pod
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/logging_metrics/secure_heapster/heapster-client.yaml |
    Then the step should succeed
    And the pod named "heapster-client" becomes ready
    Given I use the "heapster" service
    Given I select a random node's host
    # check requestheader authn
    Given I wait up to 150 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl                                                              |
      | -sk                                                               |
      | --cert                                                            |
      | /var/run/kubernetes/request-header-client.crt                     |
      | --key                                                             |
      | /var/run/kubernetes/request-header-client.key                     |
      | -H                                                                |
      | X-Remote-User: system:admin                                       |
      | https://<%= service.ip(user: user) %>/apis/metrics/v1alpha1/nodes |
    Then the output should contain:
      | <%= node.name %>                  |
    """
    # Check x509 authn
    When I execute on the pod:
      | curl                                                              |
      | -sk                                                               |
      | --cert                                                            |
      | /var/run/kubernetes/admin.crt                                     |
      | --key                                                             |
      | /var/run/kubernetes/admin.key                                     |
      | https://<%= service.ip(user: user) %>/apis/metrics/v1alpha1/nodes |
    Then the output should contain:
      | <%= node.name %>                  |
    # Check token authn
    When I run the :oadm_policy_add_role_to_user admin command with:
      | role_name | cluster-admin         |
      | user_name | <%= user.name %>      |
      | namespace | <%= project.name %>   |
    Then the step should succeed
    Given I wait up to 150 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl                                                                                            |
      | -sk                                                                                             |
      | -H                                                                                              |
      | Authorization: Bearer <%= user.cached_tokens.first %>                                        |
      | https://<%= service.ip(user: user) %>/apis/metrics/v1alpha1/namespaces/<%= project.name %>/pods |
    Then the output should contain:
      | <%= pod.name %>                   |
    """

  # @author wjiang@redhat.com
  # @case_id OCP-14850
  @admin
  @destructive
  Scenario: heapster apis should be allowed with namespace level authz
    Given I have a project
    # Create configmap to use in heapster and the curl pod
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/logging_metrics/secure_heapster/cert-configmap.yaml |
    # Grant necessary permission to heapster serviceaccount
    Given cluster role "system:heapster" is added to the "heapster" service account
    Given cluster role "system:auth-delegator" is added to the "heapster" service account
    Given cluster role "system:node-reader" is added to the "heapster" service account
    # Setup heapster
    Given I obtain test data file "logging_metrics/secure_heapster/heapster_grafana_influxdb.yaml"
    And I replace lines in "heapster_grafana_influxdb.yaml":
      | kube-system | <%= project.name %>     |
    When I run the :create client command with:
      | f | heapster_grafana_influxdb.yaml    |
    Then the step should succeed
    # Wait all pods is up
    Given status becomes :running of 1 pods labeled:
      | k8s-app=heapster                  |
    Given status becomes :running of 1 pods labeled:
      | k8s-app=grafana                   |
    Given status becomes :running of 1 pods labeled:
      | k8s-app=influxdb                  |
    # Create the heapster-client pod to do the curl command in the pod
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/logging_metrics/secure_heapster/heapster-client.yaml |
    Then the step should succeed
    And the pod named "heapster-client" becomes ready
    Given I use the "heapster" service
    When I execute on the pod:
      | curl                                                                                            |
      | -sk                                                                                             |
      | --cert                                                                                          |
      | /var/run/kubernetes/request-header-client.crt                                                   |
      | --key                                                                                           |
      | /var/run/kubernetes/request-header-client.key                                                   |
      | -H                                                                                              |
      | X-Remote-User: <%= env.users[word_to_num('second')].name %>                                     |
      | https://<%= service.ip(user: user) %>/apis/metrics/v1alpha1/namespaces/<%= project.name %>/pods |
    Then the output should contain:
      | User "<%= env.users[word_to_num('second')].name %>" cannot list pods.metrics in the namespace "<%= project.name %>" |
    And I run the :oadm_policy_add_role_to_user admin command with:
      | role_name | cluster-admin                                 |
      | user_name | <%= env.users[word_to_num("second")].name %>  |
      | namespace | <%= project.name %>                           |
    Then the step should succeed
    Given I wait up to 150 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl                                                                                            |
      | -sk                                                                                             |
      | --cert                                                                                          |
      | /var/run/kubernetes/request-header-client.crt                                                   |
      | --key                                                                                           |
      | /var/run/kubernetes/request-header-client.key                                                   |
      | -H                                                                                              |
      | X-Remote-User: <%= env.users[word_to_num("second")].name %>                                     |
      | https://<%= service.ip(user: user) %>/apis/metrics/v1alpha1/namespaces/<%= project.name %>/pods |
    Then the output should contain:
      | <%= pod.name %>                   |
    """
    Given I create a new project
    When I execute on the pod:
      | curl                                                                                            |
      | -sk                                                                                             |
      | --cert                                                                                          |
      | /var/run/kubernetes/request-header-client.crt                                                   |
      | --key                                                                                           |
      | /var/run/kubernetes/request-header-client.key                                                   |
      | -H                                                                                              |
      | X-Remote-User: <%= user(word_to_num("second")).name %>                                          |
      | https://<%= service.ip(user: user) %>/apis/metrics/v1alpha1/namespaces/<%= project.name %>/pods |
    Then the output should contain:
      | User "<%= env.users[word_to_num('second')].name %>" cannot list pods.metrics in the namespace "<%= project.name %>" |
