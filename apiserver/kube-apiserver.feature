Feature: KUBE API server related features
  # @author kewang@redhat.com
  # @case_id OCP-24698
  @admin
  Scenario: Check the http accessible /readyz for kube-apiserver
    Given I store the schedulable masters in the :nodes clipboard
    When I run the :project admin command with:
      | project_name | openshift-kube-apiserver |
    Then the output should contain:
      | project "openshift-kube-apiserver" on server |
    And I run the :port_forward background admin command with:
      | pod       | kube-apiserver-<%= cb.nodes[1].name %> |
      | port_spec | 6080                                   |
      | _timeout  | 60                                     |
    Then the step should succeed
    Given I wait up to 30 seconds for the steps to pass:
    """
    Given the expression should be true> @host = localhost
    And I run commands on the host:
      | curl http://127.0.0.1:6080/readyz --noproxy "127.0.0.1" |
    Then the step should succeed
    And the output should contain "ok"
    """

  # @author kewang@redhat.com
  # @case_id OCP-27665
  @admin
  Scenario: Check if the kube-storage-version-migrator operator related manifests has been loaded
    When I run the :get admin command with:
      | resource       | customresourcedefinition                          |
      | resource_name  | storagestates.migration.k8s.io                    |
      | resource_name  | storageversionmigrations.migration.k8s.io         |
      | resource_name  | kubestorageversionmigrators.operator.openshift.io |
    Then the step should succeed
    Given admin checks that the "kube-storage-version-migrator" clusteroperator exists
    When I run the :get admin command with:
      | resource      | configmap                                             |
      | resource_name | config                                                |
      | resource_name | openshift-kube-storage-version-migrator-operator-lock |
      | n             | openshift-kube-storage-version-migrator-operator      |
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | service                                          |
      | resource_name | metrics                                          |
      | n             | openshift-kube-storage-version-migrator-operator |
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | serviceaccount                                   |
      | resource_name | kube-storage-version-migrator-operator           |
      | n             | openshift-kube-storage-version-migrator-operator |
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | deployment                                       |
      | resource_name | kube-storage-version-migrator-operator           |
      | n             | openshift-kube-storage-version-migrator-operator |
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | serviceaccount                          |
      | resource_name | kube-storage-version-migrator-sa        |
      | n             | openshift-kube-storage-version-migrator |
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | deployment                              |
      | resource_name | migrator                                |
      | n             | openshift-kube-storage-version-migrator |
    Then the step should succeed

  # @author kewang@redhat.com
  # @case_id OCP-21246
  @admin
  Scenario Outline: Check the exposed prometheus metrics of operators
    When I run the :serviceaccounts_get_token admin command with:
      | serviceaccount_name | cluster-monitoring-operator |
      | n                   | openshift-monitoring        |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :sa_token clipboard

    # Get pod name of operators
    Given I switch to cluster admin pseudo user
    And I use the "<ns>" project
    Given a pod becomes ready with labels:
      | app=<label> |

    # Using snippet script to grab the data from the results
    Given a "snippet" file is created with the following lines:
    """
    curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://localhost:8443/metrics > /tmp/OCP-21246.metrics
    grep workqueue_depth /tmp/OCP-21246.metrics | head -n 5 > /tmp/OCP-21246.grep
    grep workqueue_adds /tmp/OCP-21246.metrics | head -n 5 >> /tmp/OCP-21246.grep
    grep workqueue_queue_duration /tmp/OCP-21246.metrics | head -n 5 >> /tmp/OCP-21246.grep
    grep workqueue_work_duration /tmp/OCP-21246.metrics | head -n 5 >> /tmp/OCP-21246.grep
    grep workqueue_retries /tmp/OCP-21246.metrics | head -n 5 >> /tmp/OCP-21246.grep
    cat /tmp/OCP-21246.grep
    """
    When I execute on the pod:
      | bash | -c | <%= File.read("snippet") %> |
    Then the step should succeed
    And the output should contain:
      | workqueue_depth          |
      | workqueue_adds           |
      | workqueue_queue_duration |
      | workqueue_work_duration  |
      | workqueue_retries        |

    Examples:
      | ns                                               | label                                  |
      | openshift-apiserver-operator                     | openshift-apiserver-operator           |
      | openshift-kube-apiserver-operator                | kube-apiserver-operator                |
      | openshift-kube-controller-manager-operator       | kube-controller-manager-operator       |
      | openshift-kube-storage-version-migrator-operator | kube-storage-version-migrator-operator |

  # @author kewang@redhat.com
  # @case_id OCP-33427
  @admin
  @destructive
  Scenario: customize audit config of apiservers
    Given I switch to cluster admin pseudo user
    Given evaluation of `Time.now.utc.strftime "%s"` is stored in the :now clipboard

    # Checking audit log default setting
    When I run the :get admin command with:
      | resource | apiserver/cluster              |
      | o        | jsonpath={.spec.audit.profile} |
    Then the step should succeed
    And the output should contain "Default"

    # To rerun the case at this step, following snippet_read/write maybe return non-zero because there are remnants of the past in audit.log
    # Solution: Only the records after timestamp of the current run are fetched from /var/log/kube-apiserver/audit.log'
    When I store the masters in the :masters clipboard
    And I use the "<%= cb.masters[0].name %>" node
    # Using snippet script to grab read verbs from the results
    Given a "snippet_read" file is created with the following lines:
    """
    grep -hE '"verb":"(get|list|watch)","user":.*(requestObject|responseObject)' /var/log/kube-apiserver/audit.log > /tmp/grep.json
    jq -c 'select (.requestReceivedTimestamp | .[0:19] + "Z" | fromdateiso8601 > <%= cb.now %>)' /tmp/grep.json | wc -l
    jq -c 'select (.requestReceivedTimestamp | .[0:19] + "Z" | fromdateiso8601 > <%= cb.now %>)' /tmp/grep.json | tail -n 1
    """
    When I run commands on the host:
      | <%= File.read("snippet_read") %> |
    Then the step should succeed
    And the expression should be true> @result[:response].split("\n")[0].to_i == 0

    # write verbs checking in audit log
    Given a "snippet_write" file is created with the following lines:
    """
    grep -hE '"verb":"(create|delete|patch|update)","user":.*(requestObject|responseObject)' /var/log/kube-apiserver/audit.log > /tmp/grep.json
    jq -c 'select (.requestReceivedTimestamp | .[0:19] + "Z" | fromdateiso8601 > <%= cb.now %>)' /tmp/grep.json | wc -l
    jq -c 'select (.requestReceivedTimestamp | .[0:19] + "Z" | fromdateiso8601 > <%= cb.now %>)' /tmp/grep.json | tail -n 1
    """
    When I run commands on the host:
      | <%= File.read("snippet_write") %> |
    Then the step should succeed
    And the expression should be true> @result[:response].split("\n")[0].to_i == 0

    When I use the "openshift-kube-apiserver" project
    And a pod becomes ready with labels:
      | app=openshift-kube-apiserver |
    When I run the :logs client command with:
      | resource_name | <%= pod.name %> |
      | c             | kube-apiserver  |
    And the output should contain:
      | --audit-policy-file="/etc/kubernetes/static-pod-resources/configmaps/kube-apiserver-audit-policies/default.yaml" |

    When I use the "openshift-apiserver" project
    And a pod becomes ready with labels:
      | app=openshift-apiserver-a |
    When I execute on the pod:
      | grep | /var/run/configmaps/audit/secure-oauth-storage-default.yaml | /var/run/configmaps/config/config.yaml |
    Then the step should succeed

    When I use the "openshift-oauth-apiserver" project
    And a pod becomes ready with labels:
      | app=openshift-oauth-apiserver |
    When I run the :get admin command with:
      | resource      | pod                                   |
      | resource_name | <%= pod.name %>                       |
      | o             | jsonpath='{.spec.containers[0].args}' |
    Then the step should succeed
    And the output should contain:
      | /var/run/configmaps/audit/secure-oauth-storage-default.yaml |

    # Set WriteRequestBodies profile to audit log
    Given as admin I successfully merge patch resource "apiserver/cluster" with:
      | {"spec": {"audit": {"profile": "WriteRequestBodies"}}} |
    And I register clean-up steps:
    # Set original Default profile to audti log
    """
    Given as admin I successfully merge patch resource "apiserver/cluster" with:
      | {"spec": {"audit": {"profile": "Default"}}} |
    Given I wait up to 100 seconds for the steps to pass:
      | the expression should be true> cluster_operator("kube-apiserver").condition(cached: false, type: 'Progressing')['status'] == "True" |
    Given I wait up to 1200 seconds for the steps to pass:
      | the expression should be true> cluster_operator("kube-apiserver").condition(cached: false, type: 'Progressing')['status'] == "False" |
    """

    Given I wait up to 100 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-apiserver").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    Given I wait up to 1200 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-apiserver").condition(cached: false, type: 'Progressing')['status'] == "False"
    """

    # Validation for WriteRequestBodies profile setting
    When I use the "openshift-apiserver" project
    And a pod becomes ready with labels:
      | app=openshift-apiserver-a |
    When I execute on the pod:
      | grep | /var/run/configmaps/audit/secure-oauth-storage-writerequestbodies.yaml | /var/run/configmaps/config/config.yaml |
    Then the step should succeed

    When I use the "openshift-oauth-apiserver" project
    And a pod becomes ready with labels:
      | app=openshift-oauth-apiserver |
    When I run the :get admin command with:
      | resource      | pod                                   |
      | resource_name | <%= pod.name %>                       |
      | o             | jsonpath='{.spec.containers[0].args}' |
    Then the step should succeed
    And the output should contain:
      | /var/run/configmaps/audit/secure-oauth-storage-writerequestbodies.yaml |

    When I use the "openshift-kube-apiserver" project
    And a pod becomes ready with labels:
      | app=openshift-kube-apiserver |
    When I run the :logs client command with:
      | resource_name | pod/<%= pod.name %> |
      | c             | kube-apiserver      |
    And the output should contain:
      | /etc/kubernetes/static-pod-resources/configmaps/kube-apiserver-audit-policies/writerequestbodies.yaml |
    # Relevant bug: 1879837
    When I execute on the pod:
      | bash | -c | grep -r '"managedFields":{' /var/log/kube-apiserver |
    Then the step should fail

    # Using snippet script to grab read verbs from the results
    When I run commands on the host:
      | <%= File.read("snippet_read") %> |
    Then the step should succeed
    And the expression should be true> @result[:response].split("\n")[0].to_i == 0

    # write verbs checking in audit log
    When I run commands on the host:
      | <%= File.read("snippet_write") %> |
    Then the step should succeed
    And the expression should be true> @result[:response].split("\n")[0].to_i > 0

    # Set AllRequestBodies profile for audit log
    Given as admin I successfully merge patch resource "apiserver/cluster" with:
      | {"spec": {"audit": {"profile": "AllRequestBodies"}}} |
    Given I wait up to 100 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-apiserver").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    Given I wait up to 1200 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-apiserver").condition(cached: false, type: 'Progressing')['status'] == "False"
    """

    # Validation for AllRequestBodies profile setting
    When I use the "openshift-apiserver" project
    And a pod becomes ready with labels:
      | app=openshift-apiserver-a |
    When I execute on the pod:
      | grep | secure-oauth-storage-allrequestbodies.yaml | /var/run/configmaps/config/config.yaml |
    Then the step should succeed

    When I use the "openshift-oauth-apiserver" project
    And a pod becomes ready with labels:
      | app=openshift-oauth-apiserver |
    When I run the :get admin command with:
      | resource      | pod                                   |
      | resource_name | <%= pod.name %>                       |
      | o             | jsonpath='{.spec.containers[0].args}' |
    Then the step should succeed
    And the output should contain:
      | /var/run/configmaps/audit/secure-oauth-storage-allrequestbodies.yaml |

    When I use the "openshift-kube-apiserver" project
    And a pod becomes ready with labels:
      | app=openshift-kube-apiserver |
    When I run the :logs client command with:
      | resource_name | pod/<%= pod.name %> |
      | c             | kube-apiserver      |
    And the output should contain:
      | /etc/kubernetes/static-pod-resources/configmaps/kube-apiserver-audit-policies/allrequestbodies.yaml |
    # Relevant bug: 1879837
    When I execute on the pod:
      | bash | -c | grep -r '"managedFields":{' /var/log/kube-apiserver |
    Then the step should fail

    # Using snippet script to grab read verbs from the results
    When I run commands on the host:
      | <%= File.read("snippet_read") %> |
    Then the step should succeed
    And the expression should be true> @result[:response].split("\n")[0].to_i > 0

    # write verbs checking in audit log
    When I run commands on the host:
      | <%= File.read("snippet_write") %> |
    Then the step should succeed
    And the expression should be true> @result[:response].split("\n")[0].to_i > 0

  # @author kewang@redhat.com
  # @case_id OCP-33830
  @admin
  Scenario: customize audit config of apiservers negative test
    # Set invalid profile for audit log
    Given I switch to cluster admin pseudo user

    When I use the "openshift-kube-apiserver" project
    And a pod becomes ready with labels:
      | app=openshift-kube-apiserver |
    # Get the revision of kube-apiserver before test
    When I run the :get admin command with:
      | resource      | pod                                    |
      | resource_name | <%= pod.name %>                        |
      | o             | jsonpath='{.metadata.labels.revision}' |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :before_change clipboard

    When I run the :patch admin command with:
      | resource | apiserver/cluster                             |
      | type     | merge                                         |
      | p        | {"spec": {"audit": {"profile": "myprofile"}}} |
    Then the step should fail
    And the output should contain:
      | Unsupported value: "myprofile" |
    When I run the :patch admin command with:
      | resource | apiserver/cluster |
      | type     | merge             |
      | p        | {"spec": {}}      |
    Then the step should succeed
    And the output should contain:
      | cluster patched (no change) |
    When I run the :delete admin command with:
      | object_type       | apiserver |
      | object_name_or_id | cluster   |
    Then the step should fail

    # After above test, the revision shouldn't be changed 
    Given I repeat the steps up to 90 seconds:
    """
    When I run the :get admin command with:
      | resource      | pod                                    |
      | resource_name | <%= pod.name %>                        |
      | o             | jsonpath='{.metadata.labels.revision}' |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :after_change clipboard
    Then the expression should be true> cb.after_change.to_i == cb.before_change.to_i
    """
