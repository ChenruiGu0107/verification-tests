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
    Then the step should succeed
    And the master service is restarted on all master nodes
    And I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/infrastructure/podpreset/podpreset-simple.yaml |
      | n | <%= project.name %>                                                                                               |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/infrastructure/podpreset/hello-pod.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    Then I run the :describe client command with:
      | resource | pod       |
      | name     | hello-pod |
    And the output should match:
      | podpreset.admission.kubernetes.io/allow-database |
      | DB_PORT:\\s+6379                                 |
      | /cache from cache-volume                         |

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
    Then the step should succeed
    And the master service is restarted on all master nodes
    And I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/infrastructure/podpreset/configmap.yaml |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/infrastructure/podpreset/podpreset-configmap.yaml |
      | n | <%= project.name %>                                                                                                  |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/infrastructure/podpreset/hello-pod.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    Then I run the :describe client command with:
      | resource | pod       |
      | name     | hello-pod |
    And the output should match:
      | podpreset.admission.kubernetes.io/use-configmap |
      | Environment Variables from                      |
      | etcd-env-config\\s+ConfigMap                    |
      | DB_PORT:\\s+6379                                |
      | duplicate_key:\\s+FROM_ENV                      |
      | expansion:\\s+whoami                            |
      | /cache from cache-volume                        |
      | /etc/app/config.json from secret-volume         |
