Feature: genericbuild.feature

  # @author wewang@redhat.com
  # @case_id OCP-17484
  @admin
  @destructive
  Scenario: Specify default tolerations via the BuildOverrides plugin
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        BuildOverrides:
          configuration:
            apiVersion: v1
            kind: BuildOverridesConfig
            tolerations:
            - key: key1
              value: value1
              effect: NoSchedule
              operator: Equal
            - key: key2
              value: value2
              effect: NoSchedule
              operator: Equal
    """
    And the master service is restarted on all master nodes	
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | https://github.com/openshift/ruby-hello-world |
    Then the step should succeed
    And the "ruby-hello-world-1" build completed
    When I run the :describe client command with:
      | resource | pod                      |
      | name     | ruby-hello-world-1-build |
    Then the step should succeed
    Then the output should contain:
      | Tolerations:     key1=value1:NoSchedule |
      |                  key2=value2:NoSchedule |

  # @author wewang@redhat.com
  # @case_id OCP-15353
  Scenario: Setting ports using parameter in template and set parameter value with string
    Given I have a project
    And I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/build/tc15352_15353/service.yaml |
      | p | PROTOCOL=UDP                                                                                        |
      | p | CONTAINER_PORT=abc                                                                                  |
      | p | EXT_PORT=efg                                                                                        |
      | p | NODE_TEMPLATE_NAME=bug-param                                                                        |
    And the step should fail
    Then the output should match "v1.ServicePort.Port: readUint32: unexpected character"

  # @author wewang@redhat.com
  # @case_id OCP-15352
  Scenario: Setting ports using parameter in template and set parameter value with number
    Given I have a project
    And I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/build/tc15352_15353/service.yaml |
      | p | PROTOCOL=UDP                                                                     |
      | p | CONTAINER_PORT=888                                                               |
      | p | EXT_PORT=999                                                                     |
      | p | NODE_TEMPLATE_NAME=bug-param                                                     |
    And the step should succeed
    When I run the :get client command with:
      | resource  | service |
    And the step should succeed
    Then the output should contain:
      | NAME       |
      | bug-param  |

  # @author wewang@redhat.com
  # @case_id OCP-20221
  Scenario: Using Secrets for Environment Variables in Build Configs
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/build/OCP-20221/mysecret.yaml |
    Then the step should succeed
    When I run the :new_build client command with:
      | app_repo    | openshift/ruby:2.3~https://github.com/sclorg/ruby-ex.git |
    Then the step should succeed
    And the "ruby-ex-1" build completed
    When I run the :patch client command with:
      | resource      | buildconfig |
      | resource_name | ruby-ex     |
      | p | {"spec": {"strategy": {"sourceStrategy": {"env": [{"name": "MYVALKEY","valueFrom": {"secretKeyRef": {"key": "username","name": "mysecret"}}},{"name": "MYVALVALUE","valueFrom": {"secretKeyRef": {"key": "password","name": "mysecret"}}}]}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    And the "ruby-ex-2" build completed
    When I run the :set_env client command with:
      | resource | pod/ruby-ex-2-build |
      | list     | true                |
      | all      | true                |
    And the output should contain:
      | {"name":"MYVALKEY","value":"developer"}  |
      | {"name":"MYVALVALUE","value":"password"} |

  # @author wewang@redhat.com
  # @case_id OCP-20223
  Scenario: Using Configmap for Environment Variables in Build Configs
    Given I have a project
    When I run the :create_configmap client command with:
      | name         | special-config     |
      | from_literal | special.how=very   |
      | from_literal | special.type=charm |
    Then the step should succeed
    When I run the :new_build client command with:
      | app_repo    | openshift/ruby:2.3~https://github.com/sclorg/ruby-ex.git |
    Then the step should succeed
    And the "ruby-ex-1" build completed
    When I run the :patch client command with:
      | resource      | buildconfig |
      | resource_name | ruby-ex     |
      | p | {"spec": {"strategy": {"sourceStrategy": {"env": [{"name": "SPECIAL_LEVEL_KEY","valueFrom": {"configMapKeyRef": {"key": "special.how","name": "special-config"}}},{"name": "SPECIAL_TYPE_KEY","valueFrom": {"configMapKeyRef": {"key": "special.type","name": "special-config"}}}]}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    And the "ruby-ex-2" build completed
    When I run the :set_env client command with:
      | resource | pod/ruby-ex-2-build |
      | list     | true                |
      | all      | true                |
    And the output should contain:
      | {"name":"SPECIAL_LEVEL_KEY","value":"very"} |
      | {"name":"SPECIAL_TYPE_KEY","value":"charm"} |

  # @author wewang@redhat.com
  # @case_id OCP-20224
  Scenario: Using file for Environment Variables in Build Configs
    Given I have a project
    When I run the :new_build client command with:
      | app_repo    | openshift/ruby:2.3~https://github.com/sclorg/ruby-ex.git |
    Then the step should succeed
    And the "ruby-ex-1" build completed
    When I run the :patch client command with:
      | resource      | buildconfig |
      | resource_name | ruby-ex     |
      | p | {"spec": {"strategy": {"sourceStrategy": {"env": [{"name": "PODNAME","valueFrom": {"fieldRef": {"fieldPath": "metadata.name"}}}]}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    And the "ruby-ex-2" build completed
    When I run the :set_env client command with:
      | resource | pod/ruby-ex-2-build |
      | list     | true                |
      | all      | true                |
    And the output should contain:
      | "name":"PODNAME"    |
      | "value":"ruby-ex-2" |

  # @author wewang@redhat.com
  # @case_id OCP-22575
  Scenario: Using oc new-build with multistage dockerfile
    Given I have a project
    When I run the :new_build client command with:
      | binary | true            |
      | name   | multistage-test |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | multistage-test                                                              |
      | from_dir    | <%= BushSlicer::HOME %>/features/tierN/testdata/build/OCP-22575/olm-testing/ |
    Then the step should succeed
    And the "multistage-test-1" build completed
