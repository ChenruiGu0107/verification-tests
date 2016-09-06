Feature: SCC policy related scenarios
  # @author xiaocwan@redhat.com
  # @case_id 511817
  @admin
  Scenario: Cluster-admin can add & remove user or group to from scc
    Given a 5 characters random string of type :dns is stored into the :scc_name clipboard
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/scc_privileged.yaml"
    And I replace lines in "scc_privileged.yaml":
      | scc-pri | <%= cb.scc_name %> |
    And I switch to cluster admin pseudo user
    Given the following scc policy is created: scc_privileged.yaml
    Then the step should succeed

    When I run the :oadm_policy_add_scc_to_user admin command with:
      | scc   | <%= cb.scc_name %>  |
      | user_name  | <%= user(0, switch: false).name %>  |
    And I run the :oadm_policy_add_scc_to_user admin command with:
      | scc   | <%= cb.scc_name %>  |
      | user_name  | <%= user(1, switch: false).name %>  |
    And I run the :oadm_policy_add_scc_to_user admin command with:
      | scc       | <%= cb.scc_name %>  |
      | user_name |             |
      | serviceaccount | system:serviceaccount:default:default |
    And I run the :oadm_policy_add_scc_to_user admin command with:
      | scc       | <%= cb.scc_name %>  |
      | user_name | system:admin |
    And I run the :oadm_policy_add_scc_to_group admin command with:
      | scc       | <%= cb.scc_name %>  |
      | group_name | system:authenticated |
    When I run the :get admin command with:
      | resource | scc |
      | resource_name | <%= cb.scc_name %>  |
      | o        | yaml |
    Then the output should contain:
      |  <%= user(0, switch: false).name %>     |
      |  <%= user(1, switch: false).name %>     |
      |  system:serviceaccount:default:default  |
      |  system:admin  |
      |  system:authenticated |

    When I run the :oadm_policy_remove_scc_from_user admin command with:
      | scc        | <%= cb.scc_name %>  |
      | user_name  | <%= user(0, switch: false).name %>  |
    And I run the :oadm_policy_remove_scc_from_user admin command with:
      | scc        | <%= cb.scc_name %>  |
      | user_name  | <%= user(1, switch: false).name %>  |
    And I run the :oadm_policy_remove_scc_from_user admin command with:
      | scc        | <%= cb.scc_name %>  |
      | user_name  |             |
      | serviceaccount | system:serviceaccount:default:default |
    And I run the :oadm_policy_remove_scc_from_user admin command with:
      | scc        | <%= cb.scc_name %>  |
      | user_name  | system:admin |
    And I run the :oadm_policy_remove_scc_from_group admin command with:
      | scc        | <%= cb.scc_name %>  |
      | group_name | system:authenticated |
    When I run the :get admin command with:
      | resource | scc |
      | resource_name | <%= cb.scc_name %>  |
      | o        | yaml |
    Then the output should not contain:
      |  <%= user(0, switch: false).name %>  |
      |  <%= user(1, switch: false).name %>  |
      |  system:serviceaccount:default:default  |
      |  system:admin  |
      |  system:authenticated  |

  # @author bmeng@redhat.com
  # @case_id 495027
  @admin
  Scenario: Add/drop capabilities for container when SC matches the SCC
    Given I have a project

    # Create pod without SCC allowed
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_cap_kill.json|
    Then the step should fail
    And the output should contain "capability may not be added"

    # Create SCC to allow KILL
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/scc_capabilities.yaml"
    And I replace lines in "scc_capabilities.yaml":
      |system:serviceaccounts:default|system:serviceaccounts:<%= project.name %>|
      |scc-cap|<%= rand_str(6, :dns) %>|
    Given the following scc policy is created: scc_capabilities.yaml

    # Create pod which match the allowed capability or not
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_cap_kill.json|
    Then the step should succeed
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_cap_chown.json|
    Then the step should fail
    And the output should contain:
      |CHOWN|
      |capability may not be added|

  # @author bmeng@redhat.com
  # @case_id 495028
  @admin
  Scenario: Pod can be created when its SC matches the SELinuxContextStrategy policy in SCC
    Given I have a project

    # Create pod which requests Selinux SecurityContext which does not match SCC SELinuxContext policy MustRunAs
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/scc_selinux_mustrunas.yaml"
    And I replace lines in "scc_selinux_mustrunas.yaml":
      |system:serviceaccounts:default|system:serviceaccounts:<%= project.name %>|
      |scc-selinux-mustrunas|<%= rand_str(6, :dns) %>|
    And the following scc policy is created: scc_selinux_mustrunas.yaml

    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_selinux.json|
    Then the step should fail
    And the output should contain:
      |does not match required user|
      |does not match required role|
      |does not match required level|
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_nothing.json|
    Then the step should succeed

    # Create pod which requests Selinux SecurityContext when the SCC SELinuxContext policy is RunAsAny
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/scc_runasany.yaml"
    And I replace lines in "scc_runasany.yaml":
      |system:serviceaccounts:default|system:serviceaccounts:<%= project.name %>|
      |scc-runasany|<%= rand_str(6, :dns) %>|
    And the following scc policy is created: scc_runasany.yaml
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_selinux.json|
    Then the step should succeed

  # @author bmeng@redhat.com
  # @case_id 495033
  @admin
  Scenario: The container with requests privileged in SC can be created only when the SCC allowed
    # Create privileged pod with default SCC
    Given I have a project
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_privileged.json|
    Then the step should fail
    And the output should contain "Privileged containers are not allowed"

    # Create new scc to allow the privileged pod for specify project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/scc_privileged.yaml"
    And I replace lines in "scc_privileged.yaml":
      |system:serviceaccounts:default|system:serviceaccounts:<%= project.name %>|
      |scc-pri|<%= rand_str(6, :dns) %>|
    And the following scc policy is created: scc_privileged.yaml

    # Create privileged pod again with new SCC
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_privileged.json|
    Then the step should succeed

  # @author bmeng@redhat.com
  # @case_id 495031
  @admin
  Scenario: Limit the created container to access the hostdir via SCC
    # Create pod which request hostdir mount permission with default SCC
    Given I have a project
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_hostdir.json|
    Then the step should fail
    And the output should match:
      |unable to validate against any security context constraint|
      |ost.*[Vv]olumes are not allowed |

    # Create new scc to allow the hostdir for pod in specify project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/scc_hostdir.yaml"
    And I replace lines in "scc_hostdir.yaml":
      |system:serviceaccounts:default|system:serviceaccounts:<%= project.name %>|
      |scc-hostdir|<%= rand_str(6, :dns) %>|
    And the following scc policy is created: scc_hostdir.yaml

    # Create hostdir pod again with new SCC
    When I run the :create client command with:
      |f|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_hostdir.json|
    Then the step should succeed

  # @author wjiang@redhat.com
  # @case_id 518942
  Scenario: [platformmanagement_public_586] Check if the capabilities work in pods
    Given I have a project
    When I run the :run client command with:
      |name|busybox|
      |image|openshift/busybox-http-app:latest|
    Then the step should succeed
    Given a pod becomes ready with labels:
      |deploymentconfig=busybox|
    When I get project pods
    Then the step should succeed
    When I execute on the pod:
      |sh|
      |-c|
      |mknod /tmp/sda b 8 0 && echo ok|
    Then the output should match "Operation not permitted"
    When I execute on the pod:
      |sh|
      |-c|
      |touch /tmp/random && chown :$RANDOM /tmp/random && echo ok|
    Then the output should match "Operation not permitted"
    When I execute on the pod:
      |sh|
      |-c|
      |touch /tmp/random && chown 0 /tmp/random && echo ok|
    Then the output should match "Operation not permitted"
    When I execute on the pod:
      |sh|
      |-c|
      |chroot /tmp && echo ok|
    Then the output should match "Operation not permitted"
    When I execute on the pod:
      |sh|
      |-c|
      |kill -9 1 && if [[ `ls /proc/\|grep ^1$` == "" ]]; then echo ok;else echo "not ok"; fi;|
    Then the output should match "not ok"

  # @author pruan@redhat.com
  # @case_id 510609
  @admin
  Scenario: deployment hook volume inheritance with hostPath volume
    Given I have a project
    # Create hostdir pod again with new SCC
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc510609/scc_hostdir.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc510609/tc_dc.json |
    And I register clean-up steps:
    """
    I run the :delete admin command with:
      | object_type       | scc         |
      | object_name_or_id | scc-hostdir |
    the step should succeed
    """
    And the pod named "hooks-1-deploy" status becomes :running
    And the pod named "hooks-1-hook-pre" status becomes :running
    # step 2, check the pre-hook pod
    When I get project pod named "hooks-1-hook-pre" as YAML
    Then the step should succeed
    And the expression should be true> @result[:parsed]['spec']['volumes'].any? {|p| p['name'] == "data"} && @result[:parsed]['spec']['volumes'].any? {|p| p['hostPath']['path'] == "/usr"}

  # @author mcurlej@redhat.com
  # @case_id 495039
  @admin
  Scenario: The SCC will take effect only when the user request the SC in the pod
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc495039/pod_not_privileged.json |
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
    """
    When I get project pod named "hello-nginx-docker"
    Then the step should succeed
    And the output should contain:
      | CrashLoopBackOff |
    """
    When I run the :delete client command with:
      | object_type | pod                     |
      | l           | name=hello-nginx-docker |
    Then the step should succeed
    When SCC "privileged" is added to the "default" user
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc495039/pod_not_privileged.json |
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
    """
    When I get project pod named "hello-nginx-docker"
    Then the step should succeed
    And the output should contain:
      | CrashLoopBackOff |
    """
    When I run the :delete client command with:
      | object_type | pod                     |
      | l           | name=hello-nginx-docker |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc495039/pod_privileged.json |
    Then the step should succeed
    And the pod named "hello-nginx-docker-1" becomes ready

  # @author mcurlej@redhat.com
  # @case_id 495037
  # The test only works when 'MustRunAsRange' policy is configured in SCC
  Scenario: pod should only be created with SC UID in the available range with the SCC restricted.
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_uid_outrange.json |
    Then the step should fail
    And the output should contain:
      | securityContext.runAsUser: Invalid value: 1000: UID on container pod-uid-outrange does not match required range. |
    And evaluation of `project.uid_range(user:user).split("/")[0].to_i + 1` is stored in the :scc_uid_inrange clipboard
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_uid_inrange.json
    Then the step should succeed

  # @author mcurlej@redhat.com
  # @case_id 495032, 495036
  @admin
  Scenario Outline: The process can be ran with the specified user when using MustRunAs or RunAsAny as the RunAsUserStrategy
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_uid_outrange.json |
    Then the step should fail
    And the output should contain:
      | UID                           |
      | does not match required range |
    When the following scc policy is created: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/<scc_file_name>.yaml
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_uid_outrange.json |
    Then the step should succeed

    Examples:
      | scc_file_name      |
      | scc-user-mustrunas |
      | scc-runasany       |

  # @author pruan@redhat.com
  # @case_id 521575
  @admin
  Scenario: Scc.allowhostdir should take precedence to allow or deny hostpath volume
    Given I have a project
    When the following scc policy is created: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc521575/scc_tc521575.yaml
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | scc          |
      | resource_name | scc-tc521575 |
      | o             | yaml         |
    Then the expression should be true> @result[:parsed]['volumes'].include? 'hostPath' and @result[:parsed]['allowHostDirVolumePlugin']
    When the following scc policy is created: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc521575/scc_tc521575_b.yaml
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | scc            |
      | resource_name | scc-tc521575-b |
      | o             | yaml           |
    Then the expression should be true> (!@result[:parsed]['volumes'].include? 'hostPath') and (!@result[:parsed]['allowHostDirVolumePlugin'])
    When the following scc policy is created: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc521575/scc_tc521575_c.yaml
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | scc            |
      | resource_name | scc-tc521575-c |
      | o             | yaml           |
    Then the expression should be true> !@result[:parsed]['volumes'].include? 'hostPath' and !@result[:parsed]['allowHostDirVolumePlugin']

  # @author pruan@redhat.com
  # @case_id 495030
  @admin
  Scenario: Different level of SCCs should have different scopes
    Given I have a project
    Given a 5 characters random string of type :dns is stored into the :scc_name_1 clipboard
    Given a 5 characters random string of type :dns is stored into the :scc_name_2 clipboard
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc495030/scc_1.json"
    And I replace lines in "scc_1.json":
       | "name": "restricted", | "name": "<%= cb.scc_name_1 %>", |
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc495030/scc_2.json"
    And I replace lines in "scc_2.json":
      | "name": "restricted", | "name": "<%= cb.scc_name_2 %>", |
    And I switch to cluster admin pseudo user
    Given the following scc policy is created: scc_1.json
    Then the step should succeed
    Given the following scc policy is created: scc_2.json
    Then the step should succeed
    Given I switch to the first user
    When I run the :oadm_policy_add_scc_to_user admin command with:
      | scc       | <%= cb.scc_name_1 %> |
      | user_name | <%= user.name %>     |
    Then the step should succeed
    When I run the :oadm_policy_add_scc_to_user admin command with:
      | scc       | <%= cb.scc_name_2 %> |
      | user_name | <%= user.name %>     |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc495030/pod1.json |
      | n | <%= project.name %>                                                                                     |
    Then the step should fail
    And the output should contain:
      | UID on container test-pod does not match required range        |
      | seLinuxOptions.level on test-pod does not match required level |
