Feature: SCC policy related scenarios
  # @author xiaocwan@redhat.com
  # @case_id OCP-9720
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
  # @case_id OCP-10647
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
  # @case_id OCP-11145
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
  # @case_id OCP-12135
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
  # @case_id OCP-11908
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
  # @case_id OCP-10780
  Scenario: [platformmanagement_public_586] Check if the capabilities work in pods
    Given I have a project
    When I run the :run client command with:
      |name|busybox|
      |image|openshift/busybox-http-app:latest|
    Then the step should succeed
    Given a pod becomes ready with labels:
      |deploymentconfig=busybox|
    When I execute on the pod:
      |sh|
      |-c|
      |mknod /tmp/sda b 8 0|
    Then the output should match "Operation not permitted"
    When I execute on the pod:
      |sh|
      |-c|
      |touch /tmp/random && chown :$RANDOM /tmp/random|
    Then the output should match "Operation not permitted"
    When I execute on the pod:
      |sh|
      |-c|
      |touch /tmp/random && chown 0 /tmp/random|
    Then the output should match "Operation not permitted"
    When I execute on the pod:
      |sh|
      |-c|
      |chroot /tmp|
    Then the output should match "Operation not permitted"
    When I execute on the pod:
      |sh|
      |-c|
      |kill -9 1 && [ ! -d /proc/1 ] && echo ok \|\| echo "not ok"|
    Then the output should match "not ok"

  # @author pruan@redhat.com
  # @case_id OCP-11762
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
  # @case_id OCP-12361
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
  # @case_id OCP-12312
  # The test only works when 'MustRunAsRange' policy is configured in SCC
  Scenario: pod should only be created with SC UID in the available range with the SCC restricted.
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_uid_outrange.json |
    Then the step should fail
    And the output should contain:
      | securityContext.runAsUser: Invalid value: 1000: UID on container pod-uid-outrange does not match required range. |
    And evaluation of `rand project.uid_range(user:user)` is stored in the :scc_uid_inrange clipboard
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_uid_inrange.json
    Then the step should succeed

  # @author mcurlej@redhat.com
  # @case_id OCP-12039, OCP-12284
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
  # @case_id OCP-11785
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
  # @case_id OCP-11734
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

  # @author pruan@redhat.com
  # @case_id OCP-12060
  Scenario: Create pod with request capabilities conflict with the scc
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc518947/add_and_drop.json |
    Then the step should fail
    And the output should match:
      | unable to validate against any security context constraint: \[capabilities.add |

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc518947/failure_to_add.json |
    Then the step should fail
    And the output should match:
      | unable to validate against any security context constraint: \[capabilities.add |

  # @author pruan@redhat.com
  # @case_id OCP-10735
  Scenario: Container.securityContext should inherit the missing fields of securitycontext from PSC
    Given I have a project
    And evaluation of `project.uid_range(user: user).begin` is stored in the :uid_range clipboard
    And evaluation of `project.mcs(user: user)` is stored in the :proj_selinux_options clipboard
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc511601/no_runasuser.json
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :running
    And evaluation of `pod('hello-openshift').sc_run_as_user(user: user)` is stored in the :sc_run_as_user clipboard
    Then the expression should be true> cb.sc_run_as_user == cb.uid_range
    Given I ensure "hello-openshift" pod is deleted
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc511601/no_runasnonroot.json |
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :running
    Then the expression should be true> pod('hello-openshift').sc_run_as_nonroot(user: user)
    Given I ensure "hello-openshift" pod is deleted
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc511601/no_selinux.json
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :running
    And evaluation of `pod('hello-openshift').sc_selinux_options(user: user)` is stored in the :pod_selinux_options clipboard
    Then the expression should be true> cb.pod_selinux_options['level'] == cb.proj_selinux_options

  # @author chezhang@redhat.com
  # @case_id OCP-10181
  Scenario: OpenShift SCC check, empty seccomp
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_seccomp_1.yaml |
    Then the step should fail
    And the output should match "unable to validate against any security context constraint.*Forbidden: seccomp may not be set pod"
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_seccomp_2.yaml |
    Then the step should succeed

  # @author chezhang@redhat.com
  # @case_id OCP-10182
  @admin
  Scenario: OpenShift SCC check, all seccomp allowed
    Given I have a project
    Given SCC "privileged" is added to the "default" user
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_seccomp_1.yaml |
    Then the step should succeed

  # @author pruan@redhat.com
  # @case_id OCP-10661
  @admin
  @destructive
  Scenario: limit the created container to access the hostnetwork via scc
    Given I have a project
    # scc restricted should have 'allowHostNetwork: false' as default already
    Given scc policy "restricted" is restored after scenario
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc498208/pod.json |
    Then the step should fail
    And the output should contain:
      | unable to validate against any security context constraint |
      | Host ports are not allowed to be used                      |
    Given as admin I replace resource "scc" named "restricted":
      | allowHostNetwork: false | allowHostNetwork: true |
      | allowHostPorts: false   | allowHostPorts: true   |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc498208/pod.json |
    Then the step should succeed


  # @author pruan@redhat.com
  # @case_id OCP-11207
  Scenario: Container.securityContext should take precedence when it conflict with PSC
    Given I have a project
    And evaluation of `rand project.uid_range(user:user)` is stored in the :scc_uid clipboard
    And evaluation of `project.uid_range(user:user).begin` is stored in the :proj_scc_uid clipboard
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc511602/pod1.json
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :running
    Then I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/aosqe-pod-for-ping.json |
    Then the step should succeed
    And evaluation of `pod('hello-openshift').container(user: user, name: 'hello-openshift', cached: true).scc['runAsUser']` is stored in the :container_run_as_user clipboard
    Then the expression should be true> cb.container_run_as_user == cb.scc_uid
    Given I ensure "hello-openshift" pod is deleted
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc511602/pod2.json
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :running
    And evaluation of `pod('hello-openshift').container(user:user, name: 'hello-openshift').scc['runAsNonRoot']` is stored in the :container_run_as_nonroot clipboard
    And evaluation of `pod('hello-openshift').sc_run_as_nonroot(user:user)` is stored in the :proj_run_as_nonroot clipboard
    Then the expression should be true> cb.container_run_as_nonroot

  # @author wjiang@redhat.com
  # @case_id OCP-11557
  @admin
  @destructive
  Scenario: Cluster-admin can reconcile the bootstrap scc
    Given system verification steps are used:
    """
    When I run the :get admin command with:
      | resource                | scc              |
      | o                       | yaml             |
    Then the step should succeed
    And the output should not contain:
      | <%= user.name %>        |
    And the output should match:
      | \sanyuid\s              |
    """
    And scc policy "anyuid" is restored after scenario
    When I run the :delete admin command with:
      | object_type             | scc              |
      | object_name_or_id       | anyuid           |
    Then the step should succeed
    When I run the :get admin command with:
      | resource                | scc              |
    Then the step should succeed
    And the output should not match:
      | \sanyuid\s              |
    When I run the :oadm_policy_add_scc_to_user admin command with:
      | scc                     | privileged       |
      | user_name               | <%= user.name %> |
    Then the step should succeed
    When I run the :oadm_policy_reconcile_sccs admin command with:
      | additive_only           | true             |
    Then the step should succeed
    When I run the :get admin command with:
      | resource                | scc              |
    Then the step should succeed
    And the output should not match:
      | \sanyuid\s              |
    When I run the :oadm_policy_reconcile_sccs admin command with:
      | additive_only           | true             |
      | confirm                 | true             |
    Then the step should succeed
    When I run the :get admin command with:
      | resource                | scc              |
      | o                       | yaml             |
    Then the step should succeed
    And the output should match:
      | \sanyuid\s              |
    And the output should contain:
      | <%= user.name %>        |
    When I run the :oadm_policy_reconcile_sccs admin command with:
      | additive_only           | false            |
    Then the step should succeed
    And the output should not contain:
      | <%= user.name %>        |
    When I run the :get admin command with:
      | resource                | scc              |
      | o                       | yaml             |
    And the output should contain:
      | <%= user.name %>        |
    When I run the :oadm_policy_reconcile_sccs admin command with:
      | additive_only           | false            |
      | confirm                 |                  |
    And the step should succeed
    When I run the :get admin command with:
      | resource                | scc              |
      | o                       | yaml             |
    Then the step should succeed
    And the output should not contain:
      | <%= user.name %>        |

  # @author: chuyu@redhat.com
  # @case_id: OCP-11010
  Scenario: User can know if he can create podspec against the current scc rules via selfsubjectsccreview
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc538262/PodSecurityPolicySubjectReview_privileged_false.json"
    Then the step should succeed
    When I perform the :post_pod_security_policy_self_subject_reviews rest request with:
      | project_name | <%= project.name %>                                  |
      | payload_file | PodSecurityPolicySubjectReview_privileged_false.json |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["status"]["allowedBy"]["name"] == "restricted"
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc538262/PodSecurityPolicySubjectReview_privileged_true.json"
    Then the step should succeed
    When I perform the :post_pod_security_policy_self_subject_reviews rest request with:
      | project_name | <%= project.name %>                                 |
      | payload_file | PodSecurityPolicySubjectReview_privileged_true.json |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["status"]["reason"] == "CantAssignSecurityContextConstraintProvider"

  # @author: chuyu@redhat.com
  # @case_id: OCP-11398
  Scenario: User can know whether the PodSpec his describing will actually be allowed by the current SCC rules via subjectsccreview
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc538263/PodSecurityPolicySubjectReview.json"
    Then the step should succeed
    When I perform the :post_pod_security_policy_subject_reviews rest request with:
      | project_name | <%= project.name %>                 |
      | payload_file | PodSecurityPolicySubjectReview.json |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["status"]["allowedBy"]["name"] == "restricted"

  # @author: chuyu@redhat.com
  # @case_id: OCP-11667
  @admin
  Scenario: User can know which serviceaccount and SA groups can create the podspec against the current sccs
    Given I have a project
    Given SCC "restricted" is added to the "default" service account
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc538264/PodSecurityPolicyReview.json"
    Then the step should succeed
    When I perform the :post_pod_security_policy_reviews rest request with:
      | project_name | <%= project.name %>          |
      | payload_file | PodSecurityPolicyReview.json |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["status"]["allowedServiceAccounts"][0]["allowedBy"]["name"] == "restricted"

  # @author: yinzhou@redhat.com
  # @case_id: OCP-11237
  @admin
  Scenario: Cluster admin can configure the default capabilities for scc
    Given the first user is cluster-admin
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/scc_with_all_cap.yaml"
    Given the following scc policy is created: scc_with_all_cap.yaml
    And I replace lines in "scc_with_all_cap.yaml":
      | - KILL | |
    When I run the :replace client command with:
      | f | scc_with_all_cap.yaml |
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | scc              |
      | resource_name | scc-with-all-cap |
      | o             | yaml             |
    And the output should not contain:
      | KILL |
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/scc_drop_all_cap.yaml"
    Given the following scc policy is created: scc_drop_all_cap.yaml
    And I replace lines in "scc_drop_all_cap.yaml":
      | - SETPCAP | |
    When I run the :replace client command with:
      | f | scc_drop_all_cap.yaml |
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | scc              |
      | resource_name | scc-drop-all-cap |
      | o             | yaml             |
    And the output should not contain:
      | SETPCAP |

  # @author: yinzhou@redhat.com
  # @case_id: OCP-11775
  @admin
  Scenario: Create or update scc with illegal capability name should fail with prompt message
    Given I have a project
    Given admin ensures "scc-cap" scc is deleted after scenario
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/scc_capabilities.yaml"
    And I replace lines in "scc_capabilities.yaml":
      |system:serviceaccounts:default|system:serviceaccounts:<%= project.name %>|
      |scc-cap|<%= rand_str(6, :dns) %>|
      |KILL|KILLtest|
    And the following scc policy is created: scc_capabilities.yaml
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/pod_requests_cap_chown.json"
    And I replace lines in "pod_requests_cap_chown.json":
      |CHOWN|KILLtest|
    When I run the :create client command with:
      |f|pod_requests_cap_chown.json|
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When  I run the :describe client command with:
      | resource | pod           |
      | name     | pod-add-chown |
    Then the output should match:
      | Unknown capability to add  |
      | CAP_KILLtest               |
    """
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/scc_with_confilict_capabilities.yaml"
    And I replace lines in "scc_with_confilict_capabilities.yaml":
      |system:serviceaccounts:default|system:serviceaccounts:<%= project.name %>|
    When I run the :create admin command with:
       | f | scc_with_confilict_capabilities.yaml |
    Then the step should fail
    And the output should contain "capability is listed in defaultAddCapabilities and requiredDropCapabilities"
    And I replace lines in "scc_with_confilict_capabilities.yaml":
      |defaultAddCapabilities:||
    When I run the :create admin command with:
      | f | scc_with_confilict_capabilities.yaml |
    Then the step should fail
    And the output should contain "capability is listed in allowedCapabilities and requiredDropCapabilities"
