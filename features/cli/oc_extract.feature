Feature: oc extract related scenarios
  # @author chezhang@redhat.com
  # @case_id OCP-11815
  Scenario: Extract configmap or secret from file
    Given I have a project
    Given a "secret.yaml" file is created with the following lines:
    """
    apiVersion: v1
    kind: Secret
    metadata:
      name: test-secret
    data:
      data-1: dmFsdWUtMQ0K
      data-2: dmFsdWUtMg0KDQo=
    """
    Given a "configmap.yaml" file is created with the following lines:
    """
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: special-config
    data:
      special.how: very
      special.type: charm
    """
    When I run the :extract client command with:
      | f        | secret.yaml    |
    Then the step should succeed
    Given evaluation of `File.read("data-1")` is stored in the :data1_log clipboard
    Then the expression should be true> /value-1/ =~ cb.data1_log
    Given evaluation of `File.read("data-2")` is stored in the :data2_log clipboard
    Then the expression should be true> /value-2/ =~ cb.data2_log
    When I run the :extract client command with:
      | filename | configmap.yaml |
      | keys     | special.type   |
    Then the step should succeed
    Given evaluation of `File.read("special.type")` is stored in the :specialtype_log clipboard
    Then the expression should be true> /charm/ =~ cb.specialtype_log
    When I run the :extract client command with:
      | filename | no-exist       |
    Then the step should fail
    And the output should contain:
      | "no-exist" does not exist |

  # @author chezhang@redhat.com
  # @case_id OCP-11976
  Scenario: Extract configmap or secret to appointed directory
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/secret.yaml |
    Then the step should succeed
    When I run the :extract client command with:
      | resource | secret/test-secret       |
    Then the step should succeed
    Given evaluation of `File.read("data-1")` is stored in the :data1_log clipboard
    Then the expression should be true> /value-1/ =~ cb.data1_log
    Given evaluation of `File.read("data-2")` is stored in the :data2_log clipboard
    Then the expression should be true> /value-2/ =~ cb.data2_log
    When I run the :extract client command with:
      | resource | configmap/special-config |
    Then the step should succeed
    Given evaluation of `File.read("special.how")` is stored in the :specialhow_log clipboard
    Then the expression should be true> /very/ =~ cb.specialhow_log
    Given evaluation of `File.read("special.type")` is stored in the :specialtype_log clipboard
    Then the expression should be true> /charm/ =~ cb.specialtype_log
    When I run the :extract client command with:
      | resource | secret/not-exist         |
    Then the step should fail
    And the output should contain:
      | secrets "not-exist" not found       |
    When I run the :extract client command with:
      | resource | configmap/not-exist      |
    Then the step should fail
    And the output should contain:
      | configmaps "not-exist" not found    |
    Given I create the "tmp" directory
    When I run the :extract client command with:
      | resource | secret/test-secret       |
      | resource | configmap/special-config |
      | to       | tmp                      |
    Then the step should succeed
    Given evaluation of `File.read("tmp/data-1")` is stored in the :tmpdata1_log clipboard
    Then the expression should be true> /value-1/ =~ cb.tmpdata1_log
    Given evaluation of `File.read("tmp/data-2")` is stored in the :tmpdata2_log clipboard
    Then the expression should be true> /value-2/ =~ cb.tmpdata2_log
    Given evaluation of `File.read("tmp/special.how")` is stored in the :tmpspecialhow_log clipboard
    Then the expression should be true> /very/ =~ cb.tmpspecialhow_log
    Given evaluation of `File.read("tmp/special.type")` is stored in the :tmpspecialtype_log clipboard
    Then the expression should be true> /charm/ =~ cb.tmpspecialtype_log
    When I run the :extract client command with:
      | resource | secret/test-secret       |
      | resource | configmap/special-config |
      | to       | not-exist                |
    Then the step should fail
    And the output should contain:
      | not-exist: no such file or directory |
    When I run the :extract client command with:
      | resource | secret/test-secret       |
      | resource | configmap/special-config |
      | to       | tmp                      |
    Then the step should fail
    And the output should contain:
      | data-1: file exists       |
      | data-2: file exists       |
      | special.how: file exists  |
      | special.type: file exists |
    When I run the :extract client command with:
      | resource | secret/test-secret       |
      | resource | configmap/special-config |
      | to       | tmp                      |
      | confirm  | true                     |
    Then the step should succeed

  # @author chezhang@redhat.com
  # @case_id OCP-12081
  Scenario: Extract only the keys from configmap or secret to directory
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/secret.yaml |
    Then the step should succeed
    When I run the :extract client command with:
      | resource | secret/test-secret      |
      | keys     | data-1                  |
    Then the step should succeed
    Given evaluation of `File.read("data-1")` is stored in the :data1_log clipboard
    Then the expression should be true> /value-1/ =~ cb.data1_log
    When I run the :extract client command with:
      | resource | secret/test-secret       |
      | resource | configmap/special-config |
      | keys     | data-2,special.type      |
    Then the step should succeed
    Given evaluation of `File.read("data-2")` is stored in the :data2_log clipboard
    Then the expression should be true> /value-2/ =~ cb.data2_log
    Given evaluation of `File.read("special.type")` is stored in the :specialtype_log clipboard
    Then the expression should be true> /charm/ =~ cb.specialtype_log
