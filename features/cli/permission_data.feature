Feature: Permission Data

  # @author chezhang@redhat.com
  # @case_id OCP-11014
  @admin
  Scenario: User can specify a default permission mode for the whole configmap volume
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.yaml |
    Then the step should succeed
    Given SCC "anyuid" is added to the "default" user
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/permission-data/configmap-permission-pod.yaml |
    Then the step should succeed
    Given the pod named "configmap-permission-pod" becomes ready
    When I execute on the pod:
      | sh |
      | -c |
      | stat -c %a /etc/config; cat /etc/config/..data/special.how; echo; stat -c %a /etc/config/..data/special.how; cat /etc/config/..data/special.type; echo; stat -c %a /etc/config/..data/special.type   |
    Then the output by order should match:
      | 777   |
      | very  |
      | 400   |
      | charm |
      | 400   |

  # @author chezhang@redhat.com
  # @case_id OCP-11401
  @admin
  Scenario: User can specify a default permission mode for the whole downward API volume
    Given I have a project
    Given SCC "anyuid" is added to the "default" user
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/permission-data/dapi-permission-pod.yaml |
    Then the step should succeed
    Given the pod named "dapi-permission-pod" becomes ready
    When I execute on the pod:
      | sh |
      | -c |
      |stat -c %a /var/tmp/podinfo; cat /var/tmp/podinfo/..data/labels; echo; stat -c %a /var/tmp/podinfo/..data/labels; cat /var/tmp/podinfo/..data/annotations; echo; stat -c %a /var/tmp/podinfo/..data/annotations; cat /var/tmp/podinfo/..data/name; echo; stat -c %a /var/tmp/podinfo/..data/name; cat /var/tmp/podinfo/..data/namespace; echo; stat -c %a /var/tmp/podinfo/..data/namespace |
    Then the output by order should match:
      | 1777                         |
      | rack="a111"                  |
      | region="r1"                  |
      | zone="z11"                   |
      | 400                          |
      | build="one"                  |
      | builder="qe-one"             |
      | kubernetes.io/config.seen=   |
      | kubernetes.io/config.source= |
      | openshift.io/scc=            |
      | 400                          |
      | dapi-permission-pod          |
      | 400                          |
      | <%= project.name %>          |
      | 400                          |

  # @author chezhang@redhat.com
  # @case_id OCP-11669
  @admin
  Scenario: User can specify a default permission mode for the whole secret volume
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/secret.yaml |
    Then the step should succeed
    Given SCC "anyuid" is added to the "default" user
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/permission-data/secret-permission-pod.yaml"
    Then I run the :create client command with:
      | f | secret-permission-pod.yaml |
    And the step should succeed
    Given the pod named "secret-permission-pod" becomes ready
    When I execute on the pod:
      | sh |
      | -c |
      | stat -c %a /etc/foo; cat /etc/foo/..data/data-1; stat -c %a /etc/foo/..data/data-1;  cat /etc/foo/..data/data-2; stat -c %a /etc/foo/..data/data-2 |
    Then the output by order should match:
      | 1777    |
      | value-1 |
      | 744     |
      | value-2 |
      | 744     |
    Given I ensure "secret-permission-pod" pod is deleted
    When I replace lines in "secret-permission-pod.yaml":
      | defaultMode: 0744 | defaultMode: 00a7 |
    Then I run the :create client command with:
      | f | secret-permission-pod.yaml |
    And the step should fail
    And the output should match:
      | expect char.*but got char 'a' |
    When I replace lines in "secret-permission-pod.yaml":
      | defaultMode: 00a7 | defaultMode: 1/2 |
    Then I run the :create client command with:
      | f | secret-permission-pod.yaml |
    And the step should fail
    And the output should match:
      | expect char.*but got char '/' |
    When I replace lines in "secret-permission-pod.yaml":
      | defaultMode: 1/2 | defaultMode: 0.5 |
    Then I run the :create client command with:
      | f | secret-permission-pod.yaml |
    And the step should fail
    And the output should match:
      | fractional integer |
    When I replace lines in "secret-permission-pod.yaml":
      | defaultMode: 0.5 | defaultMode: -1 |
    Then I run the :create client command with:
      | f | secret-permission-pod.yaml |
    And the step should fail
    And the output should match:
      | Invalid value.*-1.*must be a number between 0 and 0777 |
    When I replace lines in "secret-permission-pod.yaml":
      | defaultMode: -1 | defaultMode: 0778 |
    Then I run the :create client command with:
      | f | secret-permission-pod.yaml |
    And the step should fail
    And the output should match:
      | Invalid value.*778.*must be a number between 0 and 0777 |
    When I replace lines in "secret-permission-pod.yaml":
      | defaultMode: 0778 | defaultMode: 0 |
    Then I run the :create client command with:
      | f | secret-permission-pod.yaml |
    And the step should succeed
    Given the pod named "secret-permission-pod" becomes ready
    When I execute on the pod:
      | sh |
      | -c |
      | stat -c %a /etc/foo; cat /etc/foo/..data/data-1; stat -c %a /etc/foo/..data/data-1;  cat /etc/foo/..data/data-2; stat -c %a /etc/foo/..data/data-2 |
    Then the output by order should match:
      | 1777    |
      | value-1 |
      | 0       |
      | value-2 |
      | 0       |
    Given I ensure "secret-permission-pod" pod is deleted
    When I replace lines in "secret-permission-pod.yaml":
      | defaultMode: 0 | defaultMode: 0000007 |
    Then I run the :create client command with:
      | f | secret-permission-pod.yaml |
    And the step should succeed
    Given the pod named "secret-permission-pod" becomes ready
    When I execute on the pod:
      | sh |
      | -c |
      | stat -c %a /etc/foo; cat /etc/foo/..data/data-1; stat -c %a /etc/foo/..data/data-1;  cat /etc/foo/..data/data-2; stat -c %a /etc/foo/..data/data-2 |
    Then the output by order should match:
      | 1777    |
      | value-1 |
      | 7       |
      | value-2 |
      | 7       |
    Given I ensure "secret-permission-pod" pod is deleted
    When I replace lines in "secret-permission-pod.yaml":
      | defaultMode: 0000007 | defaultMode: 0008 |
    Then I run the :create client command with:
      | f | secret-permission-pod.yaml |
    And the step should succeed
    Given the pod named "secret-permission-pod" becomes ready
    When I execute on the pod:
      | sh |
      | -c |
      | stat -c %a /etc/foo; cat /etc/foo/..data/data-1; stat -c %a /etc/foo/..data/data-1;  cat /etc/foo/..data/data-2; stat -c %a /etc/foo/..data/data-2 |
    Then the output by order should match:
      | 1777    |
      | value-1 |
      | 10      |
      | value-2 |
      | 10      |
    Given I ensure "secret-permission-pod" pod is deleted
    When I replace lines in "secret-permission-pod.yaml":
      | defaultMode: 0008 | defaultMode: 400 |
    Then I run the :create client command with:
      | f | secret-permission-pod.yaml |
    And the step should succeed
    Given the pod named "secret-permission-pod" becomes ready
    When I execute on the pod:
      | sh |
      | -c |
      | stat -c %a /etc/foo; cat /etc/foo/..data/data-1; stat -c %a /etc/foo/..data/data-1;  cat /etc/foo/..data/data-2; stat -c %a /etc/foo/..data/data-2 |
    Then the output by order should match:
      | 1777    |
      | value-1 |
      | 620     |
      | value-2 |
      | 620     |
    Given I ensure "secret-permission-pod" pod is deleted
    When I replace lines in "secret-permission-pod.yaml":
      | defaultMode: 400 | defaultMode: |
    Then I run the :create client command with:
      | f | secret-permission-pod.yaml |
    And the step should succeed
    Given the pod named "secret-permission-pod" becomes ready
    When I execute on the pod:
      | sh |
      | -c |
      | stat -c %a /etc/foo; cat /etc/foo/..data/data-1; stat -c %a /etc/foo/..data/data-1;  cat /etc/foo/..data/data-2; stat -c %a /etc/foo/..data/data-2 |
    Then the output by order should match:
      | 1777    |
      | value-1 |
      | 644     |
      | value-2 |
      | 644     |

  # @author chezhang@redhat.com
  # @case_id OCP-11853
  @admin
  Scenario: User can specify different permission for different files in configmap volume
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.yaml |
    Then the step should succeed
    Given SCC "anyuid" is added to the "default" user
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/permission-data/configmap-keys-permission-pod.yaml |
    Then the step should succeed
    Given the pod named "configmap-keys-permission-pod" becomes ready
    When I execute on the pod:
      | sh |
      | -c |
      | stat -c %a /etc/config; cat /etc/config/..data/myconfigmap/share; echo; stat -c %a /etc/config/..data/myconfigmap/share; cat /etc/config/..data/myconfigmap/private; echo; stat -c %a /etc/config/..data/myconfigmap/private |
    Then the output by order should match:
      | 777   |
      | very  |
      | 755   |
      | charm |
      | 700   |

  # @author chezhang@redhat.com
  # @case_id OCP-12001
  @admin
  Scenario: User can specify different permission for different files in downward API volume
    Given I have a project
    Given SCC "anyuid" is added to the "default" user
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/permission-data/dapi-keys-permission-pod.yaml |
    Then the step should succeed
    Given the pod named "dapi-keys-permission-pod" becomes ready
    When I execute on the pod:
      | sh |
      | -c |
      | stat -c %a /var/tmp/podinfo; cat /var/tmp/podinfo/..data/labels; echo; stat -c %a /var/tmp/podinfo/..data/labels; cat /var/tmp/podinfo/..data/annotations; echo; stat -c %a /var/tmp/podinfo/..data/annotations; cat /var/tmp/podinfo/..data/name; echo; stat -c %a /var/tmp/podinfo/..data/name; cat /var/tmp/podinfo/..data/namespace; echo; stat -c %a /var/tmp/podinfo/..data/namespace |
    Then the output by order should match:
      | 1777                         |
      | rack="a111"                  |
      | region="r1"                  |
      | zone="z11"                   |
      | 400                          |
      | build="one"                  |
      | builder="qe-one"             |
      | kubernetes.io/config.seen=   |
      | kubernetes.io/config.source= |
      | openshift.io/scc=            |
      | 501                          |
      | dapi-keys-permission-pod     |
      | 511                          |
      | <%= project.name %>          |
      | 100                          |

  # @author chezhang@redhat.com
  # @case_id OCP-12105
  @admin
  Scenario: User can specify different permission for different files in secret volume
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/secret.yaml |
    Then the step should succeed
    Given SCC "anyuid" is added to the "default" user
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/permission-data/secret-keys-permission-pod.yaml |
    Then the step should succeed
    Given the pod named "secret-keys-permission-pod" becomes ready
    When I execute on the pod:
      | sh |
      | -c |
      | stat -c %a /etc/foo; cat /etc/foo/..data/mysecret/share; stat -c %a /etc/foo/..data/mysecret/share;  cat /etc/foo/..data/mysecret/private; stat -c %a /etc/foo/..data/mysecret/private |
    Then the output by order should match:
      | 1777    |
      | value-1 |
      | 777     |
      | value-2 |
      | 500     |

  # @author chezhang@redhat.com
  # @case_id OCP-12180
  @admin
  Scenario: User can specify right files permission when a default mode is supplied and the mode for a particular file is explicitly set
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/secret.yaml |
    Then the step should succeed
    Given SCC "anyuid" is added to the "default" user
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/permission-data/secret-mix-permission-pod.yaml |
    Then the step should succeed
    Given the pod named "secret-mix-permission-pod" becomes ready
    When I execute on the pod:
      | sh |
      | -c |
      | stat -c %a /etc/foo; cat /etc/foo/..data/mysecret/share; stat -c %a /etc/foo/..data/mysecret/share;  cat /etc/foo/..data/mysecret/private; stat -c %a /etc/foo/..data/mysecret/private |
    Then the output by order should match:
      | 1777    |
      | value-1 |
      | 777     |
      | value-2 |
      | 500     |

  # @author chezhang@redhat.com
  # @case_id OCP-11043
  Scenario: Permission mode work well in "privileged" policy with fsGroup
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/permission-data/dapi-keys-permission-pod.yaml |
    Then the step should succeed
    Given the pod named "dapi-keys-permission-pod" becomes ready
    When I execute on the pod:
      | sh |
      | -c |
      | stat -c %a /var/tmp/podinfo; cat /var/tmp/podinfo/..data/labels; echo; stat -c %a /var/tmp/podinfo/..data/labels; cat /var/tmp/podinfo/..data/annotations; echo; stat -c %a /var/tmp/podinfo/..data/annotations; cat /var/tmp/podinfo/..data/name; echo; stat -c %a /var/tmp/podinfo/..data/name; cat /var/tmp/podinfo/..data/namespace; echo; stat -c %a /var/tmp/podinfo/..data/namespace |
    Then the output by order should match:
      | 3777                         |
      | rack="a111"                  |
      | region="r1"                  |
      | zone="z11"                   |
      | 440                          |
      | build="one"                  |
      | builder="qe-one"             |
      | kubernetes.io/config.seen=   |
      | kubernetes.io/config.source= |
      | openshift.io/scc=            |
      | 541                          |
      | dapi-keys-permission-pod     |
      | 551                          |
      | <%= project.name %>          |
      | 540                          |
