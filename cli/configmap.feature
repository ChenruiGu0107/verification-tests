Feature: configMap

  # @author wehe@redhat.com
  # @case_id OCP-10166
  Scenario: Consume ConfigMap via volume plugin with multiple volumes
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap-multi-volume.yaml |
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
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/pod-multi-volume.yaml |
    Then the step should succeed
    And the pod named "pod-configmapd" status becomes :running
    When I execute on the pod:
      | cat | /etc/configmap-volume/data-1 |
    Then the step should succeed
    And the output should contain:
      | value-1 |
    When I execute on the pod:
      | cat | /opt/qe-storage/data-1 |
    Then the step should succeed
    And the output should contain:
      | value-1 |

  # @author wehe@redhat.com
  # @case_id OCP-10167
  Scenario: Consume same name configMap via volum plugin on different namespaces
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap-multi-volume.yaml |
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
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/pod-configmap-same.yaml |
    Then the step should succeed
    And the pod named "pod-same-configmap" status becomes :running
    When I execute on the pod:
      | cat | /etc/storage-volume/data-1 |
    Then the step should succeed
    And the output should contain:
      | value-1 |
    When I create a new project
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap-multi-volume.yaml |
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
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/pod-configmap-same.yaml |
    Then the step should succeed
    And the pod named "pod-same-configmap" status becomes :running
    When I execute on the pod:
      | cat | /etc/storage-volume/data-1 |
    Then the step should succeed
    And the output should contain:
      | value-1 |

  # @author wehe@redhat.com
  # @case_id OCP-10168
  Scenario: Consume ConfigMap with multiple volumes through path
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap-path.yaml |
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
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/pod-configmap-path.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=mariadb |
    When I run the :logs client command with:
      | resource_name | <%= pod.name %> |
    Then the step should succeed
    And the output should contain:
      | multiconfigmap-path-testing |

  # @author sijhu@redhat.com
  # @case_id OCP-13201
  Scenario: Inject env var for all ConfigMap values
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/cmap-for-env.yaml |
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
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/envfrom-cmap.yaml |
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

