Feature: configMap
  # @author chezhang@redhat.com
  # @case_id 520893
  Scenario: Consume ConfigMap in environment variables
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.yaml |
      | n | <%= project.name %>                                                                   |
    Then the step should succeed
    When I run the :get client command with:
      | resource | configmap |
    Then the output should match:
      | NAME.*DATA        |
      | special-config.*2 |
    When I run the :describe client command with:
      | resource | configmap      |
      | name     | special-config |
    Then the output should match:
      | special.how.*4 bytes  |
      | special.type.*5 bytes |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/pod-configmap-env.yaml |
    Then the step should succeed
    And the pod named "dapi-test-pod" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | dapi-test-pod |
    Then the step should succeed
    And the output should contain:
      | SPECIAL_TYPE_KEY=charm |
      | SPECIAL_LEVEL_KEY=very |

  # @author chezhang@redhat.com
  # @case_id 520894
  Scenario: Consume ConfigMap via volume plugin
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.yaml |
      | n | <%= project.name %>                                                                   |
    Then the step should succeed
    When I run the :get client command with:
      | resource | configmap |
    Then the output should match:
      | NAME.*DATA        |
      | special-config.*2 |
    When I run the :describe client command with:
      | resource | configmap      |
      | name     | special-config |
    Then the output should match:
      | special.how.*4 bytes  |
      | special.type.*5 bytes |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/pod-configmap-volume1.yaml |
    Then the step should succeed
    And the pod named "dapi-test-pod-1" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | dapi-test-pod-1 |
    Then the step should succeed
    And the output should contain:
      | very |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/pod-configmap-volume2.yaml |
    Then the step should succeed
    And the pod named "dapi-test-pod-2" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | dapi-test-pod-2 |
    Then the step should succeed
    And the output should contain:
      | charm |

  # @author chezhang@redhat.com
  # @case_id 520895
  Scenario: Perform CRUD operations against a ConfigMap resource
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap-example.yaml |
      | n | <%= project.name %>                                                                   |
    Then the step should succeed
    When I run the :get client command with:
      | resource | configmap |
    Then the output should match:
      | NAME.*DATA        |
      | example-config.*3 |
    When I run the :describe client command with:
      | resource | configmap      |
      | name     | example-config |
    Then the output should match:
      | example.property.file.*56 bytes |
      | example.property.1.*5 bytes     |
      | example.property.2.*5 bytes     |
    When I run the :patch client command with:
      | resource | configmap |
      | resource_name | example-config |
      | p | {"data":{"example.property.1":"hello_configmap_update"}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | configmap      |
      | name     | example-config |
    Then the output should match:
      | example.property.file.*56 bytes |
      | example.property.1.*22 bytes    |
      | example.property.2.*5 bytes     |
    When I run the :delete client command with:
      | object_type | configmap         |
      | object_name_or_id | example-config |
    Then the step should succeed
    And the output should match:
      | configmap "example-config" deleted |

  # @author chezhang@redhat.com
  # @case_id 520903
  Scenario: Set command-line arguments with ConfigMap
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.yaml |
      | n | <%= project.name %>                                                                   |
    Then the step should succeed
    When I run the :get client command with:
      | resource | configmap |
    Then the output should match:
      | NAME.*DATA        |
      | special-config.*2 |
    When I run the :describe client command with:
      | resource | configmap      |
      | name     | special-config |
    Then the output should match:
      | special.how.*4 bytes  |
      | special.type.*5 bytes |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/pod-configmap-command.yaml |
    Then the step should succeed
    And the pod named "dapi-test-pod" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | dapi-test-pod |
    Then the step should succeed
    And the output should contain:
      | very charm |

  # @author chezhang@redhat.com
  # @case_id 520909
  Scenario: Configuring redis using ConfigMap
    Given I have a project
    Given a "redis-config" file is created with the following lines:
    """
    maxmemory 2mb
    maxmemory-policy allkeys-lru
    """
    When I run the :create_configmap client command with:
      | name      | example-redis-config |
      | from_file | redis-config         |
    Then the step should succeed
    When I run the :describe client command with:
      | resource  | configmap            |
      | name      | example-redis-config |
    Then the output should match:
      | Name.*example-redis-config |
      | redis-config.*bytes        |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/pod-configmap-redis.yaml |
    Then the step should succeed
    Given the pod named "redis" becomes ready
    When I execute on the pod:
      | redis-cli | CONFIG | GET | maxmemory |
    Then the output should match:
      | maxmemory |
      | 2097152   |
    When I execute on the pod:
      | redis-cli | CONFIG | GET | maxmemory-policy |
    Then the output should match:
      | maxmemory-policy |
      | allkeys-lru      |

  # @author chezhang@redhat.com
  # @case_id 520897
  Scenario: Create ConfigMap from file
    Given I have a project
    Given I create the "configmap-test" directory
    Given a "configmap-test/game.properties" file is created with the following lines:
    """
    enemies=aliens
    lives=3
    enemies.cheat=true
    enemies.cheat.level=noGoodRotten
    secret.code.passphrase=UUDDLRLRBABAS
    secret.code.allowed=true
    secret.code.lives=30
    """
    Given a "configmap-test/ui.properties" file is created with the following lines:
    """
    color.good=purple
    color.bad=yellow
    allow.textmode=true
    how.nice.to.look=fairlyNice
    """
    When I run the :create_configmap client command with:
      | name      | game-config-1                  |
      | from_file | configmap-test/game.properties |
    Then the step should succeed
    When I run the :describe client command with:
      | resource  | configmap     |
      | name      | game-config-1 |
    Then the output should match:
      | Name.*game-config-1       |
      | game.properties.*bytes    |
    When I get project configmap named "game-config-1" as YAML
    Then the output by order should match:
      | game.properties: \|                  |
      | enemies=aliens                       |
      | lives=3                              |
      | enemies.cheat=true                   |
      | enemies.cheat.level=noGoodRotten     |
      | secret.code.passphrase=UUDDLRLRBABAS |
      | secret.code.allowed=true             |
      | secret.code.lives=30                 |
      | name: game-config-1                  |
    When I run the :create_configmap client command with:
      | name      | game-config-2                  |
      | from_file | configmap-test/game.properties |
      | from_file | configmap-test/ui.properties   |
    Then the step should succeed
    When I run the :describe client command with:
      | resource  | configmap     |
      | name      | game-config-2 |
    Then the output should match:
      | Name.*game-config-2       |
      | game.properties.*bytes    |
      | ui.properties.*bytes      |
    When I get project configmap named "game-config-2" as YAML
    Then the output by order should match:
      | game.properties: \|                  |
      | enemies=aliens                       |
      | lives=3                              |
      | enemies.cheat=true                   |
      | enemies.cheat.level=noGoodRotten     |
      | secret.code.passphrase=UUDDLRLRBABAS |
      | secret.code.allowed=true             |
      | secret.code.lives=30                 |
      | ui.properties: \|                    |
      | color.good=purple                    |
      | color.bad=yellow                     |
      | allow.textmode=true                  |
      | how.nice.to.look=fairlyNice          |
      | name: game-config-2                  |
    When I run the :create_configmap client command with:
      | name      | game-config-3                                   |
      | from_file | game-special-key=configmap-test/game.properties |
    Then the step should succeed
    When I get project configmap named "game-config-3" as YAML
    Then the output by order should match:
      | game-special-key: \|                 |
      | enemies=aliens                       |
      | lives=3                              |
      | enemies.cheat=true                   |
      | enemies.cheat.level=noGoodRotten     |
      | secret.code.passphrase=UUDDLRLRBABAS |
      | secret.code.allowed=true             |
      | secret.code.lives=30                 |
      | name: game-config-3                  |
    When I run the :delete client command with:
      | object_type       | configmap     |
      | object_name_or_id | game-config-1 |
      | object_name_or_id | game-config-2 |
      | object_name_or_id | game-config-3 |
    Then the step should succeed

  # @author chezhang@redhat.com
  # @case_id 520901
  Scenario: Create ConfigMap from literal values
    Given I have a project
    When I run the :create_configmap client command with:
      | name         | special-config     |
      | from_literal | special.how=very   |
      | from_literal | special.type=charm |
    Then the step should succeed
    When I run the :describe client command with:
      | resource  | configmap      |
      | name      | special-config |
    Then the output should match:
      | Name.*special-config |
      | special.how.*bytes   |
      | special.type.*bytes  |
    When I get project configmap named "special-config" as YAML
    Then the output by order should match:
      | special.how: very    |
      | special.type: charm  |
      | kind: ConfigMap      |
      | name: special-config |

  # @author chezhang@redhat.com
  # @case_id 520896
  Scenario: Create ConfigMap from directories
    Given I have a project
    Given I create the "configmap-test" directory
    Given a "configmap-test/game.properties" file is created with the following lines:
    """
    enemies=aliens
    lives=3
    enemies.cheat=true
    enemies.cheat.level=noGoodRotten
    secret.code.passphrase=UUDDLRLRBABAS
    secret.code.allowed=true
    secret.code.lives=30
    """
    Given a "configmap-test/ui.properties" file is created with the following lines:
    """
    color.good=purple
    color.bad=yellow
    allow.textmode=true
    how.nice.to.look=fairlyNice
    """
    When I run the :create_configmap client command with:
      | name      | game-config    |
      | from_file | configmap-test |
    Then the step should succeed
    When I run the :describe client command with:
      | resource  | configmap   |
      | name      | game-config |
    Then the output should match:
      | Name.*game-config       |
      | game.properties.*bytes  |
      | ui.properties.*bytes    |
    When I get project configmap named "game-config" as YAML
    Then the output by order should match:
      | game.properties: \|                  |
      | enemies=aliens                       |
      | lives=3                              |
      | enemies.cheat=true                   |
      | enemies.cheat.level=noGoodRotten     |
      | secret.code.passphrase=UUDDLRLRBABAS |
      | secret.code.allowed=true             |
      | secret.code.lives=30                 |
      | ui.properties: \|                    |
      | color.good=purple                    |
      | color.bad=yellow                     |
      | allow.textmode=true                  |
      | how.nice.to.look=fairlyNice          |
      | name: game-config                    |

  # @author wehe@redhat.com
  # @case_id 533089
  Scenario: Consume ConfigMap via volume plugin with multiple volumes 
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap-multi-volume.yaml | 
    Then the step should succeed
    When I run the :get client command with:
      | resource | configmap |
    Then the output should match:
      | NAME.*DATA              |
      | configmap-test-multi.*1 |
    When I run the :describe client command with:
      | resource | configmap            |
      | name     | configmap-test-multi |
    Then the output should match:
      | data-1.*7 bytes |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/pod-multi-volume.yaml | 
    Then the step should succeed
    And the pod named "pod-configmapd" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | pod-configmapd |
    Then the step should succeed
    And the output should contain:
      | value-1 |

  # @author wehe@redhat.com
  # @case_id 533098 
  Scenario: Consume same name configMap via volum plugin on different namespaces 
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap-multi-volume.yaml | 
    Then the step should succeed
    When I run the :get client command with:
      | resource | configmap |
    Then the output should match:
      | NAME.*DATA              |
      | configmap-test-multi.*1 |
    When I run the :describe client command with:
      | resource | configmap            |
      | name     | configmap-test-multi |
    Then the output should match:
      | data-1.*7 bytes |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/pod-configmap-same.yaml | 
    Then the step should succeed
    And the pod named "pod-same-configmap" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | pod-same-configmap |
    Then the step should succeed
    And the output should contain:
      | value-1 |
    When I create a new project
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap-multi-volume.yaml | 
    Then the step should succeed
    When I run the :get client command with:
      | resource | configmap |
    Then the output should match:
      | NAME.*DATA              |
      | configmap-test-multi.*1 |
    When I run the :describe client command with:
      | resource | configmap            |
      | name     | configmap-test-multi |
    Then the output should match:
      | data-1.*7 bytes |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/pod-configmap-same.yaml | 
    Then the step should succeed
    And the pod named "pod-same-configmap" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | pod-same-configmap |
    Then the step should succeed
    And the output should contain:
      | value-1 |

  # @author wehe@redhat.com
  # @case_id 533100 
  Scenario: Consume ConfigMap with multiple volumes through path 
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap-path.yaml | 
    Then the step should succeed
    When I run the :get client command with:
      | resource | configmap |
    Then the output should match:
      | NAME.*DATA       |
      | default-files.*3 |
    When I run the :describe client command with:
      | resource | configmap     |
      | name     | default-files |
    Then the output should match:
      | configs.*7 bytes       |
      | network.*7 bytes       |
      | start-script.*29 bytes |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/pod-configmap-path.yaml | 
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=mariadb |
    When I run the :logs client command with:
      | resource_name | <%= pod.name %> |
    Then the step should succeed
    And the output should contain:
      | multiconfigmap-path-testing |
