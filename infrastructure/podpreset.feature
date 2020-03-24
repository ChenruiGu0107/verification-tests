Feature: podpreset

  # @author wmeng@redhat.com
  # @case_id OCP-14175
  @admin
  @destructive
  Scenario: Pod spec can be modified by PodPreset
  # Given the master version >= "3.6"
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        PodPreset:
          configuration:
            kind: DefaultAdmissionConfig
            apiVersion: v1
            disable: false

    kubernetesMasterConfig:
      apiServerArguments:
        runtime-config:
        - apis/settings.k8s.io/v1alpha1=true
    """
    And the master service is restarted on all master nodes
    And I have a project
    When I run the :create admin command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/podpreset/podpreset-simple.yaml |
      | n | <%= project.name %>                                                                                               |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/podpreset/hello-pod.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    Then I run the :describe client command with:
      | resource | pod       |
      | name     | hello-pod |
    And the output should match:
      | podpreset.admission.kubernetes.io/.*allow-database |
      | DB_PORT:\\s+6379                                   |
      | /cache from cache-volume                           |

  # @author wmeng@redhat.com
  # @case_id OCP-14178
  @admin
  @destructive
  Scenario: Pod spec with ConfigMap can be modified by Pod Preset
  # Given the master version >= "3.6"
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        PodPreset:
          configuration:
            kind: DefaultAdmissionConfig
            apiVersion: v1
            disable: false

    kubernetesMasterConfig:
      apiServerArguments:
        runtime-config:
        - apis/settings.k8s.io/v1alpha1=true
    """
    And the master service is restarted on all master nodes
    And I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/podpreset/configmap.yaml |
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/podpreset/podpreset-configmap.yaml |
      | n | <%= project.name %>                                                                                                  |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/podpreset/hello-pod.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    Then I run the :describe client command with:
      | resource | pod       |
      | name     | hello-pod |
    And the output should match:
      | podpreset.admission.kubernetes.io/.*use-configmap |
      | Environment Variables from                        |
      | etcd-env-config\\s+ConfigMap                      |
      | DB_PORT:\\s+6379                                  |
      | duplicate_key:\\s+FROM_ENV                        |
      | expansion:\\s+whoami                              |
      | /cache from cache-volume                          |
      | /etc/app/config.json from secret-volume           |

  # @author wmeng@redhat.com
  # @case_id OCP-15055
  @admin
  @destructive
  Scenario: pod can exclude from podpreset
    Given the master version >= "3.7"
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        PodPreset:
          configuration:
            kind: DefaultAdmissionConfig
            apiVersion: v1
            disable: false

    kubernetesMasterConfig:
      apiServerArguments:
        runtime-config:
        - apis/settings.k8s.io/v1alpha1=true
    """
    And the master service is restarted on all master nodes
    And I have a project
    When I run the :create admin command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/podpreset/podpreset-simple.yaml |
      | n | <%= project.name %>                                                                                               |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/podpreset/pod-no-podpreset.yaml |
    Then the step should succeed
    Given the pod named "no-podpreset" status becomes :running within 90 seconds
    Then I run the :describe client command with:
      | resource | pod          |
      | name     | no-podpreset |
    And the output should not match:
      | podpreset.admission.kubernetes.io/.*allow-database |
      | DB_PORT:\\s+6379                                   |
      | /cache from cache-volume                           |

  # @author wjiang@redhat.com
  # @case_id OCP-15054
  @admin
  @destructive
  Scenario: PodPreset should not modify pod in other project
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        PodPreset:
          configuration:
            kind: DefaultAdmissionConfig
            apiVersion: v1
            disable: false

    kubernetesMasterConfig:
      apiServerArguments:
        runtime-config:
        - apis/settings.k8s.io/v1alpha1=true
    """
    And the master service is restarted on all master nodes
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/podpreset/podpreset-simple.yaml |
    Then the step should succeed
    And I create a new project
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/podpreset/hello-pod.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    Then I run the :get client command with:
      | resource      | pod       |
      | resource_name | hello-pod |
      | o             | yaml      |
    And the output should not contain:
      | cache-volume |


  # @author wjiang@redhat.com
  # @case_id OCP-14702
  @admin
  @destructive
  Scenario: Pod spec is not modified by PodPreset when conflict
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        PodPreset:
          configuration:
            kind: DefaultAdmissionConfig
            apiVersion: v1
            disable: false

    kubernetesMasterConfig:
      apiServerArguments:
        runtime-config:
        - apis/settings.k8s.io/v1alpha1=true
    """
    And the master service is restarted on all master nodes
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/podpreset/podpreset-simple.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/podpreset/pod-volume.yaml |
    Then the step should succeed
    Given the pod named "pod-volume" becomes ready
    And I run the :describe client command with:
      | resource  | pod         |
      | name      | pod-volume  |
    And the output should match:
      | Duplicate mountPath   |


  # @author wjiang@redhat.com
  # @case_id OCP-14701
  @admin
  @destructive
  Scenario: Pod spec can be modified by multiple PodPresets
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        PodPreset:
          configuration:
            kind: DefaultAdmissionConfig
            apiVersion: v1
            disable: false

    kubernetesMasterConfig:
      apiServerArguments:
        runtime-config:
        - apis/settings.k8s.io/v1alpha1=true
    """
    And the master service is restarted on all master nodes
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/podpreset/podpreset-simple.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/podpreset/podpreset2.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/podpreset/hello-pod.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    When I run the :get client command with:
      | resource      | pod       |
      | resource_name | hello-pod |
      | o             | yaml      |
    Then the output should match:
      | proxy-volume          |
      | cache-volume          |
