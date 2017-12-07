Feature: configMap
  # @author chezhang@redhat.com
  # @case_id OCP-10805
  @smoke
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
      | special.how  |
      | special.type |
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
  # @case_id OCP-11255
  @smoke
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
      | special.how  |
      | special.type |
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
  # @case_id OCP-11572
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
      | example.property.file |
      | example.property.1    |
      | example.property.2    |
    When I run the :patch client command with:
      | resource | configmap |
      | resource_name | example-config |
      | p | {"data":{"example.property.1":"hello_configmap_update"}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | configmap      |
      | name     | example-config |
    Then the output should match:
      | example.property.file |
      | example.property.1    |
      | example.property.2    |
    When I run the :delete client command with:
      | object_type | configmap         |
      | object_name_or_id | example-config |
    Then the step should succeed
    And the output should match:
      | configmap "example-config" deleted |

  # @author chezhang@redhat.com
  # @case_id OCP-9882
  @smoke
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
      | special.how  |
      | special.type |
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
  # @case_id OCP-9884
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
      | redis-config               |
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
  # @case_id OCP-9880
  @smoke
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
      | Name.*game-config-1 |
      | game.properties     |
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
      | Name.*game-config-2 |
      | game.properties     |
      | ui.properties       |
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
  # @case_id OCP-9881
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
      | special.how          |
      | special.type         |
    When I get project configmap named "special-config" as YAML
    Then the output by order should match:
      | special.how: very    |
      | special.type: charm  |
      | kind: ConfigMap      |
      | name: special-config |

  # @author chezhang@redhat.com
  # @case_id OCP-9879
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
      | Name.*game-config |
      | game.properties   |
      | ui.properties     |
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
  # @case_id OCP-10166
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
    Then the output should contain:
      | data-1 |
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
  # @case_id OCP-10167
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
    Then the output should contain:
      | data-1 |
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
    Then the output should contain:
      | data-1 |
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
  # @case_id OCP-10168
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
    Then the output should contain:
      | configs |
      | network |
      | start-script |
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
      
  # @author sijhu@redhat.com
  # @case_id OCP-13211
  Scenario: Negative test for Inject env var for all ConfigMap values
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/mdshuai/testfile-openshift/master/configmap/envfrom-cmap.yaml  |
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod                |
      | name     | config-env-example |
    Then the output should match:
      | Error syncing pod      |
      | "env-config" not found |
    """
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/mdshuai/testfile-openshift/master/configmap/cmap-for-env.yaml  |
    Then the step should succeed
    Given the pod named "config-env-example" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/mdshuai/testfile-openshift/master/configmap/invalid-envfrom-cmap.yaml   |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod                |
      | name     | invalid-config-env |
    Then the output should contain:
      | [may not contain '%'] |
    """

  # @author sijhu@redhat.com
  # @case_id OCP-13201
  Scenario: Inject env var for all ConfigMap values
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/cmap-for-env.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | configmap  |
      | name     | env-config |
    Then the output should contain:
      | REPLACE_ME:        | 
      | a value            |
      | duplicate_key:     |
      | FROM_CONFIG_MAP    |
      | number_of_members: | 
      | 1                  |
      | second_cmap_key:   | 
      | test               |
      | test:              |
      | jfjjf/*j!          |                  
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/envfrom-cmap.yaml |
    Then the step should succeed
    And the pod named "config-env-example" becomes ready
    When I execute on the "config-env-example" pod:
      | env |
    Then the step should succeed
    And the output should contain:
      | REPLACE_ME=a value     | 
      | expansion=a value      |
      | duplicate_key=FROM_ENV | 
      | number_of_members=1    |
      | second_cmap_key=test   | 
      | test=jfjjf/*j!         |

 # @author xiuli@redhat.com
 # @case_id OCP-16721
  Scenario: Changes to ConfigMap should be auto-updated into container	
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/pod-configmap-volume3.yaml |
    Then the step should succeed
    Given the pod named "dapi-test-pod-1" status becomes :running
    When I execute on the pod:
      | cat | /etc/config/special.how |
    Then the step should succeed
    And the output should contain:
      | very |
    When I run the :patch client command with:
      | resource      | configmap                       |
      | resource_name | special-config                  |
      | p             | {"data":{"special.how":"well"}} |
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the pod:
      | cat | /etc/config/special.how |
    Then the output should contain:
      | well |
    """
    Then the step should succeed
