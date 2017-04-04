Feature: NodeSelector related tests

  # @author: chezhang@redhat.com
  # @case_id OCP-12793
  @admin
  @destructive
  Scenario: ClusterDefaultNodeSelector will be ignored if namespace nodeSelector exist		
    Given I use the "<%= env.master_hosts.first.hostname %>" node
    And the "/etc/origin/master/admission-control-config-file.cfg" path is removed on the host after scenario
    And admin ensures "ns1" project is deleted after scenario
    Given I run commands on the host:
      | touch /etc/origin/master/admission-control-config-file.cfg                                              |
      | echo "podNodeSelectorPluginConfig:" > /etc/origin/master/admission-control-config-file.cfg              |
      | echo " clusterDefaultNodeSelector: region=west" >> /etc/origin/master/admission-control-config-file.cfg |
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        PodNodeSelector:
          location: /etc/origin/master/admission-control-config-file.cfg
        BuildDefaults:
          configuration:
            apiVersion: v1
            env: []
            kind: BuildDefaultsConfig
            resources:
              limits: {}
              requests: {}
        BuildOverrides:
          configuration:
            apiVersion: v1
            kind: BuildOverridesConfig
    """
    And the master service is restarted on all master nodes
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/admission/podnodeselector/ns1.yaml |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/admission/podnodeselector/pod-nodeSelector1.yaml |
      | n | ns1 |   
    Then the step should succeed
    When I run the :get admin command with:
      | resource  | pod  |
      | namespace | ns1  |
      | o         | json |
    Then the output should match:
      | "env": "test"     |
      | "infra": "fedora" |
      | "os": "fedora"    |
    And the output should not match:
      | "region": "west"  |

  # @author: chezhang@redhat.com
  # @case_id OCP-12792
  @admin
  @destructive
  Scenario: NodeSelector in pod should merge with clusterDefaultNodeSelector		
    Given I use the "<%= env.master_hosts.first.hostname %>" node
    And the "/etc/origin/master/admission-control-config-file.cfg" path is removed on the host after scenario
    And admin ensures "ns1" project is deleted after scenario
    Given I run commands on the host:
      | touch /etc/origin/master/admission-control-config-file.cfg                                              |
      | echo "podNodeSelectorPluginConfig:" > /etc/origin/master/admission-control-config-file.cfg              |
      | echo " clusterDefaultNodeSelector: region=west" >> /etc/origin/master/admission-control-config-file.cfg |
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        PodNodeSelector:
          location: /etc/origin/master/admission-control-config-file.cfg
        BuildDefaults:
          configuration:
            apiVersion: v1
            env: []
            kind: BuildDefaultsConfig
            resources:
              limits: {}
              requests: {}
        BuildOverrides:
          configuration:
            apiVersion: v1
            kind: BuildOverridesConfig
    """
    And the master service is restarted on all master nodes
    Given I have a project
    When I run the :new_project admin command with:
      | project_name | ns1 |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/admission/podnodeselector/pod-nodeSelector1.yaml |
      | n | ns1 |   
    Then the step should succeed
    When I run the :get admin command with:
      | resource  | pod  |
      | namespace | ns1  |
      | o         | json |
    Then the output should match:
      | "env": "test"    |
      | "os": "fedora"   |
      | "region": "west" |
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/admission/podnodeselector/pod-nodeSelector2.yaml |
      | n | ns1 |   
    Then the step should fail
    And the output should match:
      | forbidden: pod node label selector conflicts with its namespace node label selector |

  # @author: chezhang@redhat.com
  # @case_id OCP-12791
  @admin
  @destructive
  Scenario: NodeSelector in pod should merge with namespace nodeSelector			
    Given I use the "<%= env.master_hosts.first.hostname %>" node
    And the "/etc/origin/master/admission-control-config-file.cfg" path is removed on the host after scenario
    And admin ensures "ns1" project is deleted after scenario
    Given I run commands on the host:
      | touch /etc/origin/master/admission-control-config-file.cfg |
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        PodNodeSelector:
          location: /etc/origin/master/admission-control-config-file.cfg
        BuildDefaults:
          configuration:
            apiVersion: v1
            env: []
            kind: BuildDefaultsConfig
            resources:
              limits: {}
              requests: {}
        BuildOverrides:
          configuration:
            apiVersion: v1
            kind: BuildOverridesConfig
    """
    And the master service is restarted on all master nodes
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/admission/podnodeselector/ns1.yaml |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/admission/podnodeselector/pod-nodeSelector1.yaml |
      | n | ns1 |   
    Then the step should succeed
    When I run the :get admin command with:
      | resource  | pod  |
      | namespace | ns1  |
      | o         | json |
    Then the output should match:
      | "env": "test"     |
      | "infra": "fedora" |
      | "os": "fedora"    |
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/admission/podnodeselector/pod-nodeSelector2.yaml |
      | n | ns1 |   
    Then the step should fail
    And the output should match:
      | forbidden: pod node label selector conflicts with its namespace node label selector |

  # @author: chezhang@redhat.com
  # @case_id OCP-12790
  @admin
  @destructive
  Scenario: Pod create should fail when nodeSelector conflicts with whitelist				
    Given I use the "<%= env.master_hosts.first.hostname %>" node
    And the "/etc/origin/master/admission-control-config-file.cfg" path is removed on the host after scenario
    And admin ensures "ns1" project is deleted after scenario
    Given I run commands on the host:
      | touch /etc/origin/master/admission-control-config-file.cfg                                                     |
      | echo "podNodeSelectorPluginConfig:" > /etc/origin/master/admission-control-config-file.cfg                     |
      | echo " clusterDefaultNodeSelector: region=west" >> /etc/origin/master/admission-control-config-file.cfg        |
      | echo " ns1: region=west,env=test,infra=fedora,role=vm" >> /etc/origin/master/admission-control-config-file.cfg |
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        PodNodeSelector:
          location: /etc/origin/master/admission-control-config-file.cfg
        BuildDefaults:
          configuration:
            apiVersion: v1
            env: []
            kind: BuildDefaultsConfig
            resources:
              limits: {}
              requests: {}
        BuildOverrides:
          configuration:
            apiVersion: v1
            kind: BuildOverridesConfig
    """
    And the master service is restarted on all master nodes
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/admission/podnodeselector/ns1.yaml |
    Then the step should succeed
   When I run the :get admin command with:
      | resource      | namespace |
      | resource_name | ns1       |
      | o             | json      |
    Then the output should match:
      | "scheduler.alpha.kubernetes.io/node-selector": "env=test,infra=fedora" |
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/admission/podnodeselector/pod-nodeSelector3.yaml |
      | n | ns1 |   
    Then the step should succeed
    When I run the :get admin command with:
      | resource  | pod  |
      | namespace | ns1  |
      | o         | json |
    Then the output should match:
      | "env": "test"     |
      | "infra": "fedora" |
      | "role": "vm"      |
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/admission/podnodeselector/pod-nodeSelector4.yaml |
      | n | ns1 |   
    Then the step should fail
    And the output should match:
      | forbidden: pod node label selector labels conflict with its namespace whitelist |
