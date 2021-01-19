Feature: SCC policy related scenarios
  # @author xiaocwan@redhat.com
  # @case_id OCP-9720
  @admin
  Scenario: Cluster-admin can add & remove user or group to from scc
    Given a 5 characters random string of type :dns is stored into the :scc_name clipboard
    When I obtain test data file "authorization/scc/scc_privileged.yaml"
    And I replace lines in "scc_privileged.yaml":
      | scc-pri | <%= cb.scc_name %> |
    And I switch to cluster admin pseudo user
    Given the following scc policy is created: scc_privileged.yaml
    Then the step should succeed

    When I run the :oadm_policy_add_scc_to_user admin command with:
      | scc       | <%= cb.scc_name %>                 |
      | user_name | <%= user(0, switch: false).name %> |
    And I run the :oadm_policy_add_scc_to_user admin command with:
      | scc            | <%= cb.scc_name %> |
      | serviceaccount | builder            |
    And I run the :oadm_policy_add_scc_to_user admin command with:
      | scc       | <%= cb.scc_name %> |
      | user_name | system:admin       |
    And I run the :oadm_policy_add_scc_to_group admin command with:
      | scc        | <%= cb.scc_name %>   |
      | group_name | system:authenticated |
    When I run the :get admin command with:
      | resource      | ClusterRoleBinding                      |
      | resource_name | system:openshift:scc:<%= cb.scc_name %> |
      | o             | yaml                                    |
    Then the output should contain:
      | <%= user(0, switch: false).name %> |
      | builder                            |
      | system:admin                       |
      | system:authenticated               |

    When I run the :oadm_policy_remove_scc_from_user admin command with:
      | scc       | <%= cb.scc_name %>                 |
      | user_name | <%= user(0, switch: false).name %> |
    And I run the :oadm_policy_remove_scc_from_user admin command with:
      | scc       | <%= cb.scc_name %>                 |
      | user_name | <%= user(1, switch: false).name %> |
    And I run the :oadm_policy_remove_scc_from_user admin command with:
      | scc            | <%= cb.scc_name %> |
      | serviceaccount | builder            |
    And I run the :oadm_policy_remove_scc_from_user admin command with:
      | scc       | <%= cb.scc_name %> |
      | user_name | system:admin       |
    And I run the :oadm_policy_remove_scc_from_group admin command with:
      | scc        | <%= cb.scc_name %>   |
      | group_name | system:authenticated |
    When I run the :get admin command with:
      | resource      | ClusterRoleBinding                      |
      | resource_name | system:openshift:scc:<%= cb.scc_name %> |
      | o             | yaml                                    |
    Then the output should not contain:
      | <%= user(0, switch: false).name %>    |
      | <%= user(1, switch: false).name %>    |
      | system:serviceaccount:default:default |
      | system:admin                          |
      | system:authenticated                  |

  # @author bmeng@redhat.com
  # @case_id OCP-10647
  @admin
  Scenario: Add/drop capabilities for container when SC matches the SCC
    Given I have a project

    # Create pod without SCC allowed
    Given I obtain test data file "authorization/scc/pod_requests_cap_kill.json"
    When I run the :create client command with:
      |f|pod_requests_cap_kill.json|
    Then the step should fail
    And the output should contain "capability may not be added"

    # Create SCC to allow KILL
    Given I obtain test data file "authorization/scc/scc_capabilities.yaml"
    And I replace lines in "scc_capabilities.yaml":
      |system:serviceaccounts:default|system:serviceaccounts:<%= project.name %>|
      |scc-cap|<%= rand_str(6, :dns) %>|
    Given the following scc policy is created: scc_capabilities.yaml

    # Create pod which match the allowed capability or not
    Given I obtain test data file "authorization/scc/pod_requests_cap_kill.json"
    When I run the :create client command with:
      |f|pod_requests_cap_kill.json|
    Then the step should succeed
    Given I obtain test data file "authorization/scc/pod_requests_cap_chown.json"
    When I run the :create client command with:
      |f|pod_requests_cap_chown.json|
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
    Given I obtain test data file "authorization/scc/scc_selinux_mustrunas.yaml"
    And I replace lines in "scc_selinux_mustrunas.yaml":
      |system:serviceaccounts:default|system:serviceaccounts:<%= project.name %>|
      |scc-selinux-mustrunas|<%= rand_str(6, :dns) %>|
    And the following scc policy is created: scc_selinux_mustrunas.yaml

    Given I obtain test data file "authorization/scc/pod_requests_selinux.json"
    When I run the :create client command with:
      |f|pod_requests_selinux.json|
    Then the step should fail
    Given I obtain test data file "authorization/scc/pod_requests_nothing.json"
    When I run the :create client command with:
      |f|pod_requests_nothing.json|
    Then the step should succeed

    # Create pod which requests Selinux SecurityContext when the SCC SELinuxContext policy is RunAsAny
    Given I obtain test data file "authorization/scc/scc_runasany.yaml"
    And I replace lines in "scc_runasany.yaml":
      |system:serviceaccounts:default|system:serviceaccounts:<%= project.name %>|
      |scc-runasany|<%= rand_str(6, :dns) %>|
    And the following scc policy is created: scc_runasany.yaml
    Given I obtain test data file "authorization/scc/pod_requests_selinux.json"
    When I run the :create client command with:
      |f|pod_requests_selinux.json|
    Then the step should succeed

  # @author bmeng@redhat.com
  # @case_id OCP-12135
  @admin
  Scenario: The container with requests privileged in SC can be created only when the SCC allowed
    # Create privileged pod with default SCC
    Given I have a project
    Given I obtain test data file "authorization/scc/pod_requests_privileged.json"
    When I run the :create client command with:
      |f|pod_requests_privileged.json|
    Then the step should fail
    And the output should contain "Privileged containers are not allowed"

    # Create new scc to allow the privileged pod for specify project
    Given I obtain test data file "authorization/scc/scc_privileged.yaml"
    And I replace lines in "scc_privileged.yaml":
      |system:serviceaccounts:default|system:serviceaccounts:<%= project.name %>|
      |scc-pri|<%= rand_str(6, :dns) %>|
    And the following scc policy is created: scc_privileged.yaml

    # Create privileged pod again with new SCC
    Given I obtain test data file "authorization/scc/pod_requests_privileged.json"
    When I run the :create client command with:
      |f|pod_requests_privileged.json|
    Then the step should succeed

  # @author bmeng@redhat.com
  # @case_id OCP-11908
  @admin
  Scenario: Limit the created container to access the hostdir via SCC
    # Create pod which request hostdir mount permission with default SCC
    Given I have a project
    Given I obtain test data file "authorization/scc/pod_requests_hostdir.json"
    When I run the :create client command with:
      |f|pod_requests_hostdir.json|
    Then the step should fail
    And the output should match:
      |unable to validate against any security context constraint|
      |ost.*[Vv]olumes are not allowed |

    # Create new scc to allow the hostdir for pod in specify project
    Given I obtain test data file "authorization/scc/scc_hostdir.yaml"
    And I replace lines in "scc_hostdir.yaml":
      |system:serviceaccounts:default|system:serviceaccounts:<%= project.name %>|
      |scc-hostdir|<%= rand_str(6, :dns) %>|
    And the following scc policy is created: scc_hostdir.yaml

    # Create hostdir pod again with new SCC
    Given I obtain test data file "authorization/scc/pod_requests_hostdir.json"
    When I run the :create client command with:
      |f|pod_requests_hostdir.json|
    Then the step should succeed

  # @author wjiang@redhat.com
  # @case_id OCP-10780
  Scenario: [platformmanagement_public_586] Check if the capabilities work in pods
    Given I have a project
    When I run the :run client command with:
      | name  | busybox                       |
      | image | quay.io/openshifttest/busybox-http-app:latest |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | run=busybox |
    When I execute on the pod:
      | sh                   |
      | -c                   |
      | mknod /tmp/sda b 8 0 |
    Then the output should match "Operation not permitted"
    When I execute on the pod:
      | sh                                              |
      | -c                                              |
      | touch /tmp/random && chown :$RANDOM /tmp/random |
    Then the output should match "Operation not permitted"
    When I execute on the pod:
      | sh                                       |
      | -c                                       |
      | touch /tmp/random && chown 0 /tmp/random |
    Then the output should match "Operation not permitted"
    When I execute on the pod:
      | sh          |
      | -c          |
      | chroot /tmp |
    Then the output should match "Operation not permitted"
    When I execute on the pod:
      | sh                                         |
      | -c                                         |
      | kill -9 1 && [ ! -d /proc/1 ] && echo ok \|\| echo "not ok" |
    Then the output should match "not ok"

  # @author mcurlej@redhat.com
  # @case_id OCP-12361
  @admin
  Scenario: The SCC will take effect only when the user request the SC in the pod
    Given I have a project
    Given I obtain test data file "authorization/scc/pod_not_privileged.json"
    When I run the :create client command with:
      | f | pod_not_privileged.json |
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
    """
    When I get project pod named "hello-nginx-docker"
    Then the step should succeed
    And the output should contain:
      | CrashLoopBackOff |
    """
    Given I ensure "hello-nginx-docker" pod is deleted
    When SCC "privileged" is added to the "default" user
    Then the step should succeed
    Given I obtain test data file "authorization/scc/pod_not_privileged.json"
    When I run the :create client command with:
      | f | pod_not_privileged.json |
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
    Given I obtain test data file "authorization/scc/pod_privileged.json"
    When I run the :create client command with:
      | f | pod_privileged.json |
    Then the step should succeed
    And the pod named "hello-nginx-docker-1" becomes ready

  # @author mcurlej@redhat.com
  # @case_id OCP-12312
  # The test only works when 'MustRunAsRange' policy is configured in SCC
  Scenario: pod should only be created with SC UID in the available range with the SCC restricted.
    Given I have a project
    Given I obtain test data file "authorization/scc/pod_requests_uid_outrange.json"
    When I run the :create client command with:
      | f | pod_requests_uid_outrange.json |
    Then the step should fail
    And evaluation of `rand project.uid_range(user:user)` is stored in the :scc_uid_inrange clipboard
    Given I obtain test data file "authorization/scc/pod_requests_uid_inrange.json"
    When I run oc create over "pod_requests_uid_inrange.json" replacing paths:
      | ["spec"]["containers"][0]["securityContext"]["runAsUser"] | <%= cb.scc_uid_inrange %> |
    Then the step should succeed

  # @author mcurlej@redhat.com
  @admin
  Scenario Outline: The process can be ran with the specified user when using MustRunAs or RunAsAny as the RunAsUserStrategy
    Given I have a project
    Given I obtain test data file "authorization/scc/pod_requests_uid_outrange.json"
    When I run the :create client command with:
      | f | pod_requests_uid_outrange.json |
    Then the step should fail
    And the output should contain:
      | unable to validate against any security context constraint |
      | Invalid value: 1000                                        |
    Given I obtain test data file "authorization/scc/<scc_file_name>.yaml"
    When the following scc policy is created: <scc_file_name>.yaml
    Then the step should succeed
    Given I obtain test data file "authorization/scc/pod_requests_uid_outrange.json"
    When I run the :create client command with:
      | f | pod_requests_uid_outrange.json |
    Then the step should succeed

    Examples:
      | scc_file_name      |
      | scc-runasany       | # @case_id OCP-12039
      | scc-user-mustrunas | # @case_id OCP-12284

  # @author pruan@redhat.com
  # @case_id OCP-11785
  @admin
  Scenario: Scc.allowhostdir should take precedence to allow or deny hostpath volume
    Given I have a project
    Given I obtain test data file "authorization/scc/tc521575/scc_tc521575.yaml"
    When the following scc policy is created: scc_tc521575.yaml
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | scc          |
      | resource_name | scc-tc521575 |
      | o             | yaml         |
    Then the expression should be true> @result[:parsed]['volumes'].include? 'hostPath' and @result[:parsed]['allowHostDirVolumePlugin']
    Given I obtain test data file "authorization/scc/tc521575/scc_tc521575_b.yaml"
    When the following scc policy is created: scc_tc521575_b.yaml
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | scc            |
      | resource_name | scc-tc521575-b |
      | o             | yaml           |
    Then the expression should be true> (!@result[:parsed]['volumes'].include? 'hostPath') and (!@result[:parsed]['allowHostDirVolumePlugin'])
    Given I obtain test data file "authorization/scc/tc521575/scc_tc521575_c.yaml"
    When the following scc policy is created: scc_tc521575_c.yaml
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
    When I obtain test data file "authorization/scc/ocp11734/scc_1.json"
    And I replace lines in "scc_1.json":
       | "name": "restricted", | "name": "<%= cb.scc_name_1 %>", |
    When I obtain test data file "authorization/scc/ocp11734/scc_2.json"
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
    Given I obtain test data file "authorization/scc/ocp11734/pod1.json"
    When I run the :create client command with:
      | f | pod1.json |
      | n | <%= project.name %>                                                                                     |
    Then the step should fail

  # @author pruan@redhat.com
  # @case_id OCP-12060
  Scenario: Create pod with request capabilities conflict with the scc
    Given I have a project
    Given I obtain test data file "authorization/scc/ocp12060/add_and_drop.json"
    When I run the :create client command with:
      | f | add_and_drop.json |
    Then the step should fail
    And the output should match:
      | unable to validate against any security context constraint: \[.*capabilities.add |

    Given I obtain test data file "authorization/scc/ocp12060/failure_to_add.json"
    When I run the :create client command with:
      | f | failure_to_add.json |
    Then the step should fail
    And the output should match:
      | unable to validate against any security context constraint: \[.*capabilities.add |

  # @author pruan@redhat.com
  # @case_id OCP-10735
  Scenario: Container.securityContext should inherit the missing fields of securitycontext from PSC
    Given I have a project
    And evaluation of `project.uid_range(user: user).begin` is stored in the :uid_range clipboard
    And evaluation of `project.mcs(user: user)` is stored in the :proj_selinux_options clipboard
    Given I obtain test data file "authorization/scc/ocp10735/no_runasuser.json"
    When I run oc create over "no_runasuser.json" replacing paths:
      | ["spec"]["securityContext"]["runAsUser"] | <%= cb.uid_range %> |
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :running
    And evaluation of `pod('hello-openshift').sc_run_as_user(user: user)` is stored in the :sc_run_as_user clipboard
    Then the expression should be true> cb.sc_run_as_user == cb.uid_range
    Given I ensure "hello-openshift" pod is deleted
    Given I obtain test data file "authorization/scc/ocp10735/no_runasnonroot.json"
    When I run the :create client command with:
      | f | no_runasnonroot.json |
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :running
    Then the expression should be true> pod('hello-openshift').sc_run_as_nonroot(user: user)
    Given I ensure "hello-openshift" pod is deleted
    Given I obtain test data file "authorization/scc/ocp10735/no_selinux.json"
    When I run oc create over "no_selinux.json" replacing paths:
      | ["spec"]["securityContext"]["seLinuxOptions"]["level"] | <%= cb.proj_selinux_options %> |
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :running
    And evaluation of `pod('hello-openshift').sc_selinux_options(user: user)` is stored in the :pod_selinux_options clipboard
    Then the expression should be true> cb.pod_selinux_options['level'] == cb.proj_selinux_options

  # @author chezhang@redhat.com
  # @case_id OCP-10181
  Scenario: OpenShift SCC check, empty seccomp
    Given I have a project
    Given I obtain test data file "authorization/scc/pod_seccomp_1.yaml"
    When I run the :create client command with:
      | f | pod_seccomp_1.yaml |
    Then the step should fail
    And the output should match "unable to validate against any security context constraint.*Forbidden: seccomp may not be set pod"
    Given I obtain test data file "authorization/scc/pod_seccomp_2.yaml"
    When I run the :create client command with:
      | f | pod_seccomp_2.yaml |
    Then the step should succeed

  # @author chezhang@redhat.com
  # @case_id OCP-10182
  @admin
  Scenario: OpenShift SCC check, all seccomp allowed
    Given I have a project
    Given SCC "privileged" is added to the "default" user
    Given I obtain test data file "authorization/scc/pod_seccomp_1.yaml"
    When I run the :create client command with:
      | f | pod_seccomp_1.yaml |
    Then the step should succeed

  # @author pruan@redhat.com
  # @case_id OCP-10661
  @admin
  @destructive
  Scenario: limit the created container to access the hostnetwork via scc
    Given I have a project
    # scc restricted should have 'allowHostNetwork: false' as default already
    Given scc policy "restricted" is restored after scenario
    Given I obtain test data file "authorization/scc/ocp10661/pod.json"
    When I run the :create client command with:
      | f | pod.json |
    Then the step should fail
    And the output should contain:
      | unable to validate against any security context constraint |
      | Host ports are not allowed to be used                      |
    Given as admin I replace resource "scc" named "restricted":
      | allowHostNetwork: false | allowHostNetwork: true |
      | allowHostPorts: false   | allowHostPorts: true   |
    Given I obtain test data file "authorization/scc/ocp10661/pod.json"
    When I run the :create client command with:
      | f | pod.json |
    Then the step should succeed


  # @author pruan@redhat.com
  # @case_id OCP-11207
  Scenario: Container.securityContext should take precedence when it conflict with PSC
    Given I have a project
    And evaluation of `rand project.uid_range(user:user)` is stored in the :scc_uid clipboard
    And evaluation of `project.uid_range(user:user).begin` is stored in the :proj_scc_uid clipboard
    When I run oc create over ERB test file: authorization/scc/ocp11207/pod1.json
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :running
    Given I obtain test data file "networking/aosqe-pod-for-ping.json"
    Then I run the :create client command with:
      | f | aosqe-pod-for-ping.json |
    Then the step should succeed
    And evaluation of `pod('hello-openshift').container(user: user, name: 'hello-openshift', cached: true).spec.scc['runAsUser']` is stored in the :container_run_as_user clipboard
    Then the expression should be true> cb.container_run_as_user == cb.scc_uid
    Given I ensure "hello-openshift" pod is deleted
    When I run oc create over ERB test file: authorization/scc/ocp11207/pod2.json
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :running
    And evaluation of `pod('hello-openshift').container(user:user, name: 'hello-openshift').spec.scc['runAsNonRoot']` is stored in the :container_run_as_nonroot clipboard
    And evaluation of `pod('hello-openshift').sc_run_as_nonroot(user:user)` is stored in the :proj_run_as_nonroot clipboard
    Then the expression should be true> cb.container_run_as_nonroot

  # @author chuyu@redhat.com
  # @case_id OCP-11010
  Scenario: User can know if he can create podspec against the current scc rules via selfsubjectsccreview
    Given I have a project
    Given I obtain test data file "authorization/scc/PodSecurityPolicySubjectReview_privileged_false.json"
    When I perform the :post_pod_security_policy_self_subject_reviews rest request with:
      | project_name | <%= project.name %>                                                                                                             |
      | payload_file | PodSecurityPolicySubjectReview_privileged_false.json |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["status"]["allowedBy"]["name"] == "restricted"
    Given I obtain test data file "authorization/scc/PodSecurityPolicySubjectReview_privileged_true.json"
    When I perform the :post_pod_security_policy_self_subject_reviews rest request with:
      | project_name | <%= project.name %>                                                                                                            |
      | payload_file | PodSecurityPolicySubjectReview_privileged_true.json |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["status"]["reason"] == "CantAssignSecurityContextConstraintProvider"

  # @author chuyu@redhat.com
  # @case_id OCP-11398
  Scenario: User can know whether the PodSpec his describing will actually be allowed by the current SCC rules via subjectsccreview
    Given I have a project
    When I obtain test data file "authorization/scc/PodSecurityPolicySubjectReview.json"
    Then the step should succeed
    And I replace lines in "PodSecurityPolicySubjectReview.json":
      | "apiVersion": "v1" | "apiVersion": "security.openshift.io/v1" |
    Then the step should succeed
    When I perform the :post_pod_security_policy_subject_reviews rest request with:
      | project_name | <%= project.name %>                 |
      | payload_file | PodSecurityPolicySubjectReview.json |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["status"]["allowedBy"]["name"] == "restricted"

  # @author yinzhou@redhat.com
  # @case_id OCP-11237
  @admin
  Scenario: Cluster admin can configure the default capabilities for scc
    Given the first user is cluster-admin
    When I obtain test data file "authorization/scc/scc_with_all_cap.yaml"
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
    When I obtain test data file "authorization/scc/scc_drop_all_cap.yaml"
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

  # @author yinzhou@redhat.com
  # @case_id OCP-12064
  @admin
  Scenario: Wildcard SCC for volumes is respected
    Given I have a project
    And evaluation of `project.uid_range(user:user).begin` is stored in the :scc_limit clipboard
    Given I obtain test data file "authorization/scc/tc521575/scc_tc521575_c.yaml"
    And I replace lines in "scc_tc521575_c.yaml":
      |system:serviceaccounts:default|system:serviceaccounts:<%= project.name %>|
    Given the following scc policy is created: scc_tc521575_c.yaml

    When I obtain test data file "storage/gitrepo/gitrepo-selinux-fsgroup-test.json"
    And I replace lines in "gitrepo-selinux-fsgroup-test.json":
      | "runAsUser": 1000130000, | "runAsUser": <%= cb.scc_limit %>, |
      | "fsGroup": 123456        | "fsGroup":  <%= cb.scc_limit %>   |
    When I run the :create client command with:
      | f | gitrepo-selinux-fsgroup-test.json |
    Then the step should succeed

  # @author chuyu@redhat.com
  # @case_id OCP-13573
  @admin
  Scenario: Verify the privileged SCC allow to request any capabilities
    Given I have a project
    Given the first user is cluster-admin
    Given I use the first master host
    And I run the :get admin command with:
      | resource      | scc                             |
      | resource_name | privileged                      |
      | o             | jsonpath={.allowedCapabilities} |
    Then the step should succeed
    And the output should match:
      | [*] |
    Given I obtain test data file "authorization/scc/pod_requests_cap_fsetid.json"
    And I run the :create admin command with:
      | f | pod_requests_cap_fsetid.json |
      | n | <%= project.name %>                                                                            |
    Then the step should succeed
    When I get project pod named "pod-add-fsetid" as JSON
    Then the expression should be true> @result[:parsed]['spec']['containers'][0]['securityContext']['capabilities']['add'][0] == "FSETID"

  # @author mcurlej@redhat.com
  # @case_id OCP-11498
  @admin
  Scenario: Cannot run process with root in the container when using MustRunAsNonRoot as the RunAsUserStrategy
    Given I have a project
    Given I obtain test data file "authorization/scc/scc_user_mustrunasnonroot.yaml"
    When the following scc policy is created: scc_user_mustrunasnonroot.yaml
    Then the step should succeed
    When SCC "scc-user-mustrunasnonroot" is added to the "default" user
    Then the step should succeed
    Given I obtain test data file "authorization/scc/pod_requests_uid_root.json"
    When I run the :create client command with:
      | f | pod_requests_uid_root.json |
    Then the step should fail
    And the output should contain "forbidden"
    Given I obtain test data file "authorization/scc/pod_requests_uid_outrange.json"
    When I run the :create client command with:
      | f | pod_requests_uid_outrange.json |
    Then the step should succeed
    And the pod named "pod-uid-outrange" status becomes :running
    And the expression should be true> pod.container(name: "pod-uid-outrange").spec.scc["runAsUser"] == 1000

  # @author scheng@redhat.com
  # @case_id OCP-18828
  @admin
  Scenario: Allow scc access via RBAC at project level
    Given I have a project
    Given I obtain test data file "authorization/scc/OCP-18828/allow_scc_access_via_rbac_project.yaml"
    When I run the :create admin command with:
      | f | allow_scc_access_via_rbac_project.yaml |
      | n | <%= project.name %>                    |
    Then the step should succeed
    When I run the :create_rolebinding admin command with:
      | name | scc-rolebinding                    |
      | user | <%= user(0, switch: false).name %> |
      | role | role-18828                         |
      | n    | <%= project.name %>                |
    Then the step should succeed
    Given I switch to the first user
    Given I obtain test data file "authorization/scc/pod_privileged.json"
    When I run the :create client command with:
      | f | pod_privileged.json |
      | n | <%= project.name %> |
    Then the step should succeed
    Given I create 1 new projects
    Given I obtain test data file "authorization/scc/pod_privileged.json"
    When I run the :create client command with:
      | f | pod_privileged.json |
      | n | <%= project.name %> |
    Then the step should fail
    And the output should contain "unable to validate against any security context constraint"

  # @author scheng@redhat.com
  # @case_id OCP-18836
  @admin
  Scenario: Allow scc access via RBAC at cluster level
    Given a 5 characters random string of type :dns is stored into the :random_name clipboard
    And admin ensures "crole-18836-<%= cb.random_name %>" cluster_role is deleted after scenario
    And admin ensures "scc-crolebinding-<%= cb.random_name %>" cluster_role_binding is deleted after scenario

    Given I switch to cluster admin pseudo user
    Given I obtain test data file "authorization/scc/OCP-18836/allow_scc_access_via_rbac_cluster.yaml"
    When I run oc create over "allow_scc_access_via_rbac_cluster.yaml" replacing paths:
      | ["metadata"]["name"] | crole-18836-<%= cb.random_name %> |
    Then the step should succeed
    When I run the :create_clusterrolebinding client command with:
      | name         | scc-crolebinding-<%= cb.random_name %> |
      | user         | <%= user(0, switch: false).name %>     |
      | clusterrole  | crole-18836-<%= cb.random_name %>      |
    Then the step should succeed
    Given I switch to the first user
    Given I have a project
    Given I obtain test data file "authorization/scc/pod_privileged.json"
    When I run the :create client command with:
      | f |  pod_privileged.json |
    Then the step should succeed
    Given I switch to the second user
    Given I have a project
    Given I obtain test data file "authorization/scc/pod_privileged.json"
    When I run the :create client command with:
      | f |  pod_privileged.json |
    Then the step should fail
    And the output should contain "unable to validate against any security context constraint"

  # @author chuyu@redhat.com
  # @case_id OCP-19827
  @admin
  @destructive
  Scenario: SCC for allowPrivilegeEscalation parameter support
    Given scc policy "restricted" is restored after scenario
    Given I have a project
    Given I obtain test data file "authorization/scc/pod_request_allowprivilegeescalation.yaml"
    When I run the :create client command with:
      | f | pod_request_allowprivilegeescalation.yaml |
    Then the step should succeed
    Given I obtain test data file "authorization/scc/pod_request_non_allowprivilegeescalation.yaml"
    When I run the :create client command with:
      | f | pod_request_non_allowprivilegeescalation.yaml |
    Then the step should succeed
    Given I obtain test data file "authorization/scc/pod_request_nil_allowprivilegeescalation.yaml"
    When I run the :create client command with:
      | f | pod_request_nil_allowprivilegeescalation.yaml |
    Then the step should succeed
    When I run the :patch admin command with:
      | resource      | scc                                 |
      | resource_name | restricted                          |
      | p             | {"allowPrivilegeEscalation": false} |
      | type          | merge                               |
    Then the step should succeed
    Given I obtain test data file "authorization/scc/pod_request_allowprivilegeescalation.yaml"
    When I run the :create client command with:
      | f | pod_request_allowprivilegeescalation.yaml |
    Then the step should fail
    And the output should contain "unable to validate against any security context constraint:"
    Given I obtain test data file "authorization/scc/pod_request_non_allowprivilegeescalation.yaml"
    When  I run the :create client command with:
      | f | pod_request_non_allowprivilegeescalation.yaml |
    Then the step should succeed
    Given I obtain test data file "authorization/scc/pod_request_nil_allowprivilegeescalation.yaml"
    When I run the :create client command with:
      | f | pod_request_nil_allowprivilegeescalation.yaml |
    Then the step should succeed

  # @author chuyu@redhat.com
  # @case_id OCP-19832
  @admin
  @destructive
  Scenario: SCC for defaultAllowPrivilegeEscalation parameter support
    Given scc policy "restricted" is restored after scenario
    When I run the :patch admin command with:
      | resource      | scc                                       |
      | resource_name | restricted                                |
      | p             | {"defaultAllowPrivilegeEscalation": true} |
      | type          | merge                                     |
    Then the step should succeed
    Given I have a project
    Given I obtain test data file "authorization/scc/pod_no_request_allowprivilegeescalation.yaml"
    When I run the :create client command with:
      | f | pod_no_request_allowprivilegeescalation.yaml |
    Then the step should succeed
    When I run the :patch admin command with:
      | resource      | scc                                 |
      | resource_name | restricted                          |
      | p             | {"allowPrivilegeEscalation": false} |
      | type          | merge                               |
    Then the step should fail
    And the output should contain "Cannot set DefaultAllowPrivilegeEscalation to true without also setting AllowPrivilegeEscalation to true"
    When I run the :patch admin command with:
      | resource      | scc                                        |
      | resource_name | restricted                                 |
      | p             | {"defaultAllowPrivilegeEscalation": false} |
      | type          | merge                                      |
    Then the step should succeed
    When I run the :patch admin command with:
      | resource      | scc                                 |
      | resource_name | restricted                          |
      | p             | {"allowPrivilegeEscalation": false} |
      | type          | merge                               |
    Then the step should succeed
    Given I obtain test data file "authorization/scc/pod_no_request_allowprivilegeescalation.yaml"
    When I run the :create client command with:
      | f | pod_no_request_allowprivilegeescalation.yaml |
    Then the step should succeed
    When I run the :patch admin command with:
      | resource      | scc                                |
      | resource_name | restricted                         |
      | p             | {"allowPrivilegeEscalation": null} |
      | type          | merge                              |
    Then the step should succeed
    Given I obtain test data file "authorization/scc/pod_no_request_allowprivilegeescalation.yaml"
    When I run the :create client command with:
      | f | pod_no_request_allowprivilegeescalation.yaml |
    Then the step should succeed

  # @author chuyu@redhat.com
  # @case_id OCP-22485
  @admin
  Scenario: 4.x User can know which serviceaccount and SA groups can create the podspec against the current sccs
    Given I have a project
    Given SCC "restricted" is added to the "default" service account
    When I obtain test data file "authorization/scc/PodSecurityPolicyReview.json"
    And I replace lines in "PodSecurityPolicyReview.json":
      | "apiVersion": "v1" | "apiVersion": "security.openshift.io/v1" |
    Then the step should succeed
    When I perform the :post_pod_security_policy_reviews rest request with:
      | project_name | <%= project.name %>          |
      | payload_file | PodSecurityPolicyReview.json |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["status"]["allowedServiceAccounts"][0]["allowedBy"]["name"] == "restricted"

  # @author minmli@redhat.com
  # @case_id OCP-20316
  @admin
  @destructive
  Scenario: sysctl can be controlled by scc
    Given I switch to cluster admin pseudo user
    When I run the :label admin command with:
      | resource | machineconfigpool     |
      | name     | worker                |
      | key_val  | custom-kubelet=sysctl |
    Then the step should succeed
    And I register clean-up steps:
    """
    Given I switch to cluster admin pseudo user
    When I run the :label admin command with:
      | resource | machineconfigpool |
      | name     | worker            |
      | key_val  | custom-kubelet-   |
    Then the step should succeed
    """
    Given I obtain test data file "customresource/custom-kubelet-sysctl.yaml"
    When I run the :create client command with:
      | f | custom-kubelet-sysctl.yaml |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    Given evaluation of `machine_config_pool('worker').condition(type: 'Updating', cached: false)` is stored in the :mcp clipboard
    Then the expression should be true> cb.mcp["status"] == "True"
    """
    And I wait up to 1800 seconds for the steps to pass:
    """
    Given evaluation of `machine_config_pool('worker').condition(type: 'Updating', cached: false)` is stored in the :mcp clipboard
    Then the expression should be true> cb.mcp["status"] == "False"
    """

    Given as admin I successfully merge patch resource "scc/restricted" with:
      | {"forbiddenSysctls":["kernel.shm_rmid_forced", "net.ipv4.ip_local_port_range"]} |
    And I register clean-up steps:
    """
    Given as admin I successfully merge patch resource "scc/restricted" with:
      | {"forbiddenSysctls":null} |
    """
    Given I switch to the first user
    Given I have a project
    Given I obtain test data file "sysctls/safe-sysctl.yaml"
    When I run the :create client command with:
      | f | safe-sysctl.yaml |
    Then the step should fail
    And the output should match:
      | .*sysctl "kernel.shm_rmid_forced" is not allowed.*sysctl "net.ipv4.ip_local_port_range" is not allowed |
    Given I obtain test data file "sysctls/unsafe-sysctl.yaml"
    When I run the :create client command with:
      | f | unsafe-sysctl.yaml |
    Then the step should fail
    And the output should match:
      | .*sysctl "net.ipv4.ip_forward" is not allowed.*sysctl "kernel.msgmax" is not allowed |
    Given as admin I successfully merge patch resource "scc/restricted" with:
      | {"allowedUnsafeSysctls":["kernel.msg*", "net.ipv4*"],"forbiddenSysctls":null} |
    And I register clean-up steps:
    """
    Given as admin I successfully merge patch resource "scc/restricted" with:
      | {"allowedUnsafeSysctls":null} |
    """
    Given I switch to the first user
    Given I obtain test data file "sysctls/unsafe-sysctl.yaml"
    When I run the :create client command with:
      | f | unsafe-sysctl.yaml |
    Then the step should succeed
    And the pod named "hello-pod" becomes ready

