Feature: All in one volume

  # @author chezhang@redhat.com
  # @case_id OCP-12395
  Scenario: Collisions when one path is explicit and the other is automatically projected
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/configmap.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/secret.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/allinone-collisions-pod-1.yaml |
    Then the step should succeed
    Given the pod named "allinone-collisions-1" becomes ready
    When I execute on the pod:
      | sh |
      | -c |
      | stat -c %a /all-in-one; cat /all-in-one/data-1; echo; stat -c %a /all-in-one/..data/data-1; cat /all-in-one/data-2; stat -c %a /all-in-one/..data/data-2; stat -c %a /all-in-one/..data/myconfigmap; cat /all-in-one/myconfigmap/private-config; echo; stat -c %a /all-in-one/..data/myconfigmap/private-config |
    Then the output by order should match:
      | ^3777$  |
      | very    |
      | ^644$   |
      | value-2 |
      | ^644$   |
      | ^2755$  |
      | charm   |
      | ^644$   |
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/allinone-collisions-pod-2.yaml |
    Then the step should succeed
    Given the pod named "allinone-collisions-2" becomes ready
    When I execute on the pod:
      | sh |
      | -c |
      | stat -c %a /all-in-one; cat /all-in-one/data-1; stat -c %a /all-in-one/..data/data-1; cat /all-in-one/data-2; stat -c %a /all-in-one/..data/data-2; stat -c %a /all-in-one/..data/myconfigmap; cat /all-in-one/myconfigmap/private-config; echo; stat -c %a /all-in-one/..data/myconfigmap/private-config |
    Then the output by order should match:
      | ^3777$  |
      | value-1 |
      | ^644$   |
      | value-2 |
      | ^644$   |
      | ^2755$  |
      | charm   |
      | ^644$   |

  # @author chezhang@redhat.com
  # @case_id OCP-12412
  Scenario: using a non-absolute path in volumeMounts
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/configmap.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/secret.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/allinone-opposite-path-pod.yaml |
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod                    |
      | name     | allinone-opposite-path |
    Then the output should match:
      | mount path must be absolute |
    """

  # @author chezhang@redhat.com
  # @case_id OCP-12438
  Scenario: Project secrets, configmap not explicitly defining keys for pathing within a volume
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/configmap.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/secret.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/allinone-no-keypath-pod.yaml |
    Then the step should succeed
    Given the pod named "allinone-no-keypath" becomes ready
    When I execute on the pod:
      | sh |
      | -c |
      | stat -c %a /all-in-one; cat /all-in-one/data-1; stat -c %a /all-in-one/..data/data-1; cat /all-in-one/data-2; stat -c %a /all-in-one/..data/data-2; cat /all-in-one/special.how; echo; stat -c %a /all-in-one/..data/special.how; cat /all-in-one/special.type; echo; stat -c %a /all-in-one/..data/special.type |
    Then the output by order should match:
      | ^3777$  |
      | value-1 |
      | ^644$   |
      | value-2 |
      | ^644$   |
      | very    |
      | ^644$   |
      | charm   |
      | ^644$   |
    When I run the :delete client command with:
      | object_type | configmap            |
      | object_name_or_id | special-config |
    Then the step should succeed
    Given I ensure "allinone-no-keypath" pod is deleted
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/configmap-with-samekey.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/allinone-no-keypath-pod.yaml |
    Then the step should succeed
    Given the pod named "allinone-no-keypath" becomes ready
    When I execute on the pod:
      | sh |
      | -c |
      | stat -c %a /all-in-one; cat /all-in-one/data-1; echo; stat -c %a /all-in-one/..data/data-1; cat /all-in-one/data-2; stat -c %a /all-in-one/..data/data-2; cat /all-in-one/special.type; echo; stat -c %a /all-in-one/..data/special.type |
    Then the output by order should match:
      | ^3777$  |
      | very    |
      | ^644$   |
      | value-2 |
      | ^644$   |
      | charm   |
      | ^644$   |

  # @author chezhang@redhat.com
  # @case_id OCP-12447
  Scenario: Project secrets, configmap with a same path of keys within a volume
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/configmap.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/secret.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/allinone-same-path-pod.yaml |
    Then the step should fail
    And the output should match:
      | projected: Invalid value: "special-config": conflicting duplicate paths |
      | Not found: "all-in-one"                                                 |

  # @author chezhang@redhat.com
  # @case_id OCP-12456
  Scenario: using invalid volume name
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/configmap.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/secret.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/allinone-negative-pod-1.yaml |
    Then the step should fail
    And the output should match:
      | Invalid value: "all-in-one abc" |
      | Not found: "all-in-one abc"     |
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/allinone-negative-pod-2.yaml |
    Then the step should fail
    And the output should match:
      | Invalid value.*<%= Regexp.escape("all-in-one!@$#$%^&") %> |
      | Not found.*<%= Regexp.escape("all-in-one!@$#$%^&") %>     |

  # @author chezhang@redhat.com
  # @case_id OCP-12427
  @admin
  Scenario: Permission mode work well in whole volume and individual resources
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/configmap.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/secret.yaml |
    Then the step should succeed
    Given SCC "anyuid" is added to the "default" user
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/allinone-volume/allinone-permission-mode-pod.yaml |
    Then the step should succeed
    Given the pod named "allinone-permission-mode" becomes ready
    When I execute on the pod:
      | sh |
      | -c |
      | stat -c %a /all-in-one; stat -c %a /all-in-one/..data/mysecret; cat /all-in-one/mysecret/my-username; stat -c %a /all-in-one/..data/mysecret/my-username; cat /all-in-one/mysecret/my-passwd; stat -c %a /all-in-one/..data/mysecret/my-passwd; stat -c %a /all-in-one/..data/mydapi; cat /all-in-one/mydapi/labels; echo; stat -c %a /all-in-one/..data/mydapi/labels; cat /all-in-one/mydapi/name; echo; stat -c %a /all-in-one/..data/mydapi/name; cat /all-in-one/mydapi/cpu_limit; echo; stat -c %a /all-in-one/..data/mydapi/cpu_limit; stat -c %a /all-in-one/..data/myconfigmap; cat /all-in-one/myconfigmap/shared-config; echo; stat -c %a /all-in-one/..data/myconfigmap/shared-config; cat /all-in-one/myconfigmap/private-config; echo; stat -c %a /all-in-one/..data/myconfigmap/private-config |
    Then the output by order should match:
      | ^1777$                   |
      | ^755$                    |
      | value-1                  |
      | ^400$                    |
      | value-2                  |
      | ^400$                    |
      | ^755$                    |
      | region="one"             |
      | ^400$                    |
      | allinone-permission-mode |
      | ^400$                    |
      | ^500$                    |
      | ^400$                    |
      | ^755$                    |
      | very                     |
      | ^777$                    |
      | charm                    |
      | ^700$                    |
