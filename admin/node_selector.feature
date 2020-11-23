Feature: NodeSelector related tests

  # @author chezhang@redhat.com
  # @case_id OCP-12793
  @admin
  @destructive
  Scenario: ClusterDefaultNodeSelector will be ignored if namespace nodeSelector exist		
    Given I use the first master host
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
    Given I obtain test data file "admission/podnodeselector/ns1.yaml"
    When I run the :create admin command with:
      | f | ns1.yaml |
    Then the step should succeed
    Given I obtain test data file "admission/podnodeselector/pod-nodeSelector1.yaml"
    When I run the :create admin command with:
      | f | pod-nodeSelector1.yaml |
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

  # @author chezhang@redhat.com
  # @case_id OCP-12792
  @admin
  @destructive
  Scenario: NodeSelector in pod should merge with clusterDefaultNodeSelector		
    Given I use the first master host
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
    Given I obtain test data file "admission/podnodeselector/pod-nodeSelector1.yaml"
    When I run the :create admin command with:
      | f | pod-nodeSelector1.yaml |
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
    Given I obtain test data file "admission/podnodeselector/pod-nodeSelector2.yaml"
    When I run the :create admin command with:
      | f | pod-nodeSelector2.yaml |
      | n | ns1 |
    Then the step should fail
    And the output should match:
      | forbidden: pod node label selector conflicts with its namespace node label selector |

  # @author chezhang@redhat.com
  # @case_id OCP-12791
  @admin
  @destructive
  Scenario: NodeSelector in pod should merge with namespace nodeSelector			
    Given I use the first master host
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
    Given I obtain test data file "admission/podnodeselector/ns1.yaml"
    When I run the :create admin command with:
      | f | ns1.yaml |
    Then the step should succeed
    Given I obtain test data file "admission/podnodeselector/pod-nodeSelector1.yaml"
    When I run the :create admin command with:
      | f | pod-nodeSelector1.yaml |
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
    Given I obtain test data file "admission/podnodeselector/pod-nodeSelector2.yaml"
    When I run the :create admin command with:
      | f | pod-nodeSelector2.yaml |
      | n | ns1 |
    Then the step should fail
    And the output should match:
      | forbidden: pod node label selector conflicts with its namespace node label selector |

  # @author chezhang@redhat.com
  # @case_id OCP-12790
  @admin
  @destructive
  Scenario: Pod create should fail when nodeSelector conflicts with whitelist				
    Given I use the first master host
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
    Given I obtain test data file "admission/podnodeselector/ns1.yaml"
    When I run the :create admin command with:
      | f | ns1.yaml |
    Then the step should succeed
   When I run the :get admin command with:
      | resource      | namespace |
      | resource_name | ns1       |
      | o             | json      |
    Then the output should match:
      | "scheduler.alpha.kubernetes.io/node-selector": "env=test,infra=fedora" |
    Given I obtain test data file "admission/podnodeselector/pod-nodeSelector3.yaml"
    When I run the :create admin command with:
      | f | pod-nodeSelector3.yaml |
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
    Given I obtain test data file "admission/podnodeselector/pod-nodeSelector4.yaml"
    When I run the :create admin command with:
      | f | pod-nodeSelector4.yaml |
      | n | ns1 |
    Then the step should fail
    And the output should match:
      | forbidden: pod node label selector labels conflict with its namespace whitelist |

  # @author chezhang@redhat.com
  # @case_id OCP-12794
  @admin
  Scenario: Create namespace with node selector
    Given evaluation of `rand_str(5, :dns)` is stored in the :project1 clipboard
    And admin ensures "<%= cb.project1 %>" project is deleted after scenario
    Given I obtain test data file "projects/valid-namesapce.yaml"
    When I run oc create as admin over "valid-namesapce.yaml" replacing paths:
      | ["metadata"]["name"] | <%= cb.project1 %> |
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | ns                 |
      | resource_name | <%= cb.project1 %> |
      | o             | json               |
    Then the output should match:
      | "scheduler.alpha.kubernetes.io/node-selector": "region=east,country=china" |
    Given evaluation of `rand_str(5, :dns)` is stored in the :project2 clipboard
    And admin ensures "<%= cb.project2 %>" project is deleted after scenario
    Given I obtain test data file "projects/invalid-namespace.yaml"
    When I run oc create as admin over "invalid-namespace.yaml" replacing paths:
      | ["metadata"]["name"] | <%= cb.project2 %> |
    Then the step should succeed

  # @author chezhang@redhat.com
  # @case_id OCP-12795
  @admin
  Scenario: Should update node-selector after create namespace
    Given evaluation of `rand_str(5, :dns)` is stored in the :project clipboard
    And admin ensures "<%= cb.project %>" project is deleted after scenario
    Given I obtain test data file "projects/ns1.yaml"
    When I run oc create as admin over "ns1.yaml" replacing paths:
      | ["metadata"]["name"] | <%= cb.project %> |
    Then the step should succeed
    When I run the :patch admin command with:
      | resource      | ns  |
      | resource_name | <%= cb.project %> |
      | p             | {"metadata":{"annotations":{"scheduler.alpha.kubernetes.io/node-selector":"env=#=xyz%\|=\|"}}} |
    Then the step should succeed

  # @author minmli@redhat.com
  # @case_id OCP-33818
  @admin
  @destructive
  Scenario: ClusterDefaultNodeSelector will be ignored if namespace nodeSelector exist - 4.x
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-kube-apiserver" project
    Given 3 pods become ready with labels:
      | app=openshift-kube-apiserver |
    Given I store in the clipboard the pods labeled:
      | app=openshift-kube-apiserver |
    And I register clean-up steps:
    """
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-kube-apiserver" project
    Given 3 pods become ready with labels:
      | app=openshift-kube-apiserver |
    Given I store in the clipboard the pods labeled:
      | app=openshift-kube-apiserver |
    Given as admin I successfully merge patch resource "scheduler/cluster" with:
      | {"spec":{"defaultNodeSelector":null}} |
    And I wait up to 1200 seconds for the steps to pass:
      | When I run the :get client command with:                                            |
      |   \| resource     \| pod                           \|                               |
      |   \|resource_name \| <%= cb.pods[0].name %>        \|                               |
      |   \|template      \| {{.metadata.resourceVersion}} \|                               |
      | Then the step should succeed                                                        |
      | Then the expression should be true> @result[:response] > cb.pods[0].resourceVersion |
      | When I run the :get client command with:                                            |
      |   \| resource     \| pod                           \|                               |
      |   \|resource_name \| <%= cb.pods[1].name %>        \|                               |
      |   \|template      \| {{.metadata.resourceVersion}} \|                               |
      | Then the step should succeed                                                        |
      | Then the expression should be true> @result[:response] > cb.pods[1].resourceVersion |
      | When I run the :get client command with:                                            |
      |   \| resource     \| pod                           \|                               |
      |   \|resource_name \| <%= cb.pods[2].name %>        \|                               |
      |   \|template      \| {{.metadata.resourceVersion}} \|                               |
      | Then the step should succeed                                                        |
      | Then the expression should be true> @result[:response] > cb.pods[2].resourceVersion |
    """
    Given as admin I successfully merge patch resource "scheduler/cluster" with:
      | {"spec":{"defaultNodeSelector":"region=west"}} |
    And I wait up to 1200 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | pod                           |
      | resource_name | <%= cb.pods[0].name %>        |
      | template      | {{.metadata.resourceVersion}} |
    Then the step should succeed
    Then the expression should be true> @result[:response] > cb.pods[0].resourceVersion
    When I run the :get client command with:
      | resource      | pod                           |
      | resource_name | <%= cb.pods[1].name %>        |
      | template      | {{.metadata.resourceVersion}} |
    Then the step should succeed
    Then the expression should be true> @result[:response] > cb.pods[1].resourceVersion
    When I run the :get client command with:
      | resource      | pod                           |
      | resource_name | <%= cb.pods[2].name %>        |
      | template      | {{.metadata.resourceVersion}} |
    Then the step should succeed
    Then the expression should be true> @result[:response] > cb.pods[2].resourceVersion
    """
    Given I switch to the first user
    Given I have a project
    Given I run the :patch admin command with:
      | resource      | namespace                                                                                              |
      | resource_name | <%=project.name%>                                                                                      |
      | p             | {"metadata":{"annotations": {"scheduler.alpha.kubernetes.io/node-selector": "env=test,infra=fedora"}}} |
    Then the step should succeed
    Given I obtain test data file "admission/podnodeselector/pod-nodeSelector1.yaml"
    When I run the :create client command with:
      | f | pod-nodeSelector1.yaml |
    Then the step should succeed
    When I get project pod named "hello-pod" as JSON
    Then the output should match:
      | "env": "test"     |
      | "infra": "fedora" |
      | "os": "fedora"    |
    And the output should not match:
      | "region": "west" |

  # @author minmli@redhat.com
  # @case_id OCP-27086
  @admin
  @destructive
  Scenario: defaultNodeSelector options in scheduler will make pod landing on nodes with proper label
    Given as admin I successfully merge patch resource "scheduler/cluster" with:
      | {"spec":{"defaultNodeSelector":"infra=rhel"}} |
    And I register clean-up steps:
    """
    When I run the :patch admin command with:
      | resource      | Scheduler                                             |
      | resource_name | cluster                                               |
      | p             | [{"op":"remove", "path":"/spec/defaultNodeSelector"}] |
      | type          | json                                                  |
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
      | Then the expression should be true> cluster_operator("kube-apiserver").condition(cached: false, type: 'Progressing')['status'] == "True" |
    And I wait up to 1200 seconds for the steps to pass:
      | Then the expression should be true> cluster_operator("kube-apiserver").condition(cached: false, type: 'Progressing')['status'] == "False" |
      | And the expression should be true> cluster_operator("kube-apiserver").condition(type: 'Degraded')['status'] == "False"                    | 
      | And the expression should be true> cluster_operator("kube-apiserver").condition(type: 'Available')['status'] == "True"                    |
    """
    And I wait up to 120 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-apiserver").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 1200 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-apiserver").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("kube-apiserver").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-apiserver").condition(type: 'Available')['status'] == "True"
    """

    Given I switch to the first user
    Given I have a project
    Given I obtain test data file "pods/hello-pod.json"
    When I run the :create client command with:
      | f | hello-pod.json |
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :pending
    Given I store the schedulable workers in the :nodes clipboard
    Given label "infra=rhel" is added to the "<%= cb.nodes[0].name %>" node
    Then the pod named "hello-openshift" status becomes :running

    Given label "infra-" is added to the "<%= cb.nodes[0].name %>" node
    Given I switch to the second user
    Given I have a project
    Given I run the :patch admin command with:
      | resource      | namespace                                                                                  |
      | resource_name | <%=project.name%>                                                                          |
      | p             | {"metadata":{"annotations": {"scheduler.alpha.kubernetes.io/node-selector": "infra=aos"}}} |
    Then the step should succeed
    Given I obtain test data file "pods/hello-pod.json"
    When I run the :create client command with:
      | f | hello-pod.json |
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :pending
    When label "infra=aos" is added to the "<%= cb.nodes[0].name %>" node
    Then the pod named "hello-openshift" status becomes :running

  # @author minmli@redhat.com
  # @case_id OCP-33816
  @admin
  @destructive
  Scenario: NodeSelector in pod should merge with clusterDefaultNodeSelector and defaultNodeSelector options in scheduler will make pod landing on nodes with proper label
    Given as admin I successfully merge patch resource "scheduler/cluster" with:
      | {"spec":{"defaultNodeSelector":"region=west"}} |
    And I register clean-up steps:
    """
    When I run the :patch admin command with:
      | resource      | Scheduler                                             |
      | resource_name | cluster                                               |
      | p             | [{"op":"remove", "path":"/spec/defaultNodeSelector"}] |
      | type          | json                                                  |
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
      | Then the expression should be true> cluster_operator("kube-apiserver").condition(cached: false, type: 'Progressing')['status'] == "True" |
    And I wait up to 1200 seconds for the steps to pass:
      | Then the expression should be true> cluster_operator("kube-apiserver").condition(cached: false, type: 'Progressing')['status'] == "False" |
      | And the expression should be true> cluster_operator("kube-apiserver").condition(type: 'Degraded')['status'] == "False"                    |
      | And the expression should be true> cluster_operator("kube-apiserver").condition(type: 'Available')['status'] == "True"                    |
    """
    And I wait up to 120 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-apiserver").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 1200 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-apiserver").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("kube-apiserver").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-apiserver").condition(type: 'Available')['status'] == "True"
    """

    Given I switch to the first user
    Given I have a project
    Given I obtain test data file "admission/podnodeselector/pod-nodeSelector2.yaml"
    When I run the :create client command with:
      | f | pod-nodeSelector2.yaml |
    Then the step should fail
    And the output should match:
      | forbidden: pod node label selector conflicts with its project node label selector |
    Given I obtain test data file "admission/podnodeselector/pod-nodeSelector1.yaml"
    When I run the :create client command with:
      | f | pod-nodeSelector1.yaml |
    Then the step should succeed
    When I get project pod named "hello-pod" as JSON
    Then the output should match:
      | "env": "test"    |
      | "os": "fedora"   |
      | "region": "west" |
    Given I obtain test data file "pods/hello-pod.json"
    When I run the :create client command with:
      | f | hello-pod.json |
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :pending
    Given I store the schedulable workers in the :nodes clipboard
    Given label "region=west" is added to the "<%= cb.nodes[0].name %>" node
    Then the pod named "hello-openshift" status becomes :running

    Given label "region-" is added to the "<%= cb.nodes[0].name %>" node
    Given I switch to the second user
    Given I have a project
    Given I run the :patch admin command with:
      | resource      | namespace                                                                                  |
      | resource_name | <%=project.name%>                                                                          |
      | p             | {"metadata":{"annotations": {"scheduler.alpha.kubernetes.io/node-selector": "region=east"}}} |
    Then the step should succeed
    Given I obtain test data file "pods/hello-pod.json"
    When I run the :create client command with:
      | f | hello-pod.json |
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :pending
    When label "region=east" is added to the "<%= cb.nodes[0].name %>" node
    Then the pod named "hello-openshift" status becomes :running

