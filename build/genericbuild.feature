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
      | p | PROTOCOL=UDP                                                                                        |
      | p | CONTAINER_PORT=888                                                                                  |   
      | p | EXT_PORT=999                                                                                        |
      | p | NODE_TEMPLATE_NAME=bug-param                                                                        |
    And the step should succeed 
    When I run the :get client command with:
      | resource  | service |
    And the step should succeed
    Then the output should contain:
      | NAME       |  
      | bug-param  |  
      
  # @author wewang@redhat.com
  # @case_id OCP-10793
  @admin 
  @destructive
  Scenario: Configure the BuildDefaults plugin when build     
    Given I have a project
    And I have a proxy configured in the project
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        BuildDefaults:
          configuration:
            apiVersion: v1
            kind: BuildDefaultsConfig
            gitHTTPProxy: http://<%= cb.proxy_ip %>:<%= cb.proxy_port %>
            gitHTTPSProxy: http://<%= cb.proxy_ip %>:<%= cb.proxy_port %> 
            env:
            - name: CUSTOM_VAR
              value: custom_value
    """
    Given the master service is restarted on all master nodes
    When I run the :new_app client command with:                                                          
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/build/ruby22rhel7-template-sti.json |
      | env  | http_proxy=http://<%= cb.proxy_ip %>:<%= cb.proxy_port %>                                              |
      | env  | https_proxy=http://<%= cb.proxy_ip %>:<%= cb.proxy_port %>                                            |
    Then the step should succeed                                                                          
    And the "ruby22-sample-build-1" build completes                                                       
    Given 2 pods become ready with labels:                                                                
      | app=ruby-helloworld-sample |
    When I execute on the pod:                                                                            
      | env |
    Then the step should succeed                                                                          
    And the output should contain "https_proxy=http://<%= cb.proxy_ip %>:<%= cb.proxy_port %>"                         
    When I run the :start_build client command with:                                                      
      | buildconfig | ruby22-sample-build                   |
      | env         | https_proxy=error.rdu.redhat.com:3128 |
    Then the step should succeed                                                                         
    And the "ruby22-sample-build-2" build failed                                                          
    When I run the :logs client command with:                                                             
      | resource_name | build/ruby22-sample-build-2 |
    Then the step should succeed                                                                          
    And the output should contain "HTTPError Could not fetch specs"                                         
    Given master config is merged with the following hash:                                                
    """
    admissionConfig:
      pluginConfig:
        BuildDefaults:
          configuration:
            apiVersion: v1
            kind: BuildDefaultsConfig
            gitHTTPProxy: http://<%= cb.proxy_ip %>:<%= cb.proxy_port %>
            gitHTTPSProxy: http://<%= cb.proxy_ip %>:<%= cb.proxy_port %>
            env:
            - name: HTTP_PROXY
              value: http://error.rdu.redhat.com:3128
            - name: HTTPS_PROXY
              value: https://error.rdu.redhat.com:3128
            - name: CUSTOM_VAR
              value: custom_value
    """
    Given the master service is restarted on all master nodes                                            
    When I run the :start_build client command with:                                                     
      | buildconfig | ruby22-sample-build |
    Then the step should succeed                                                                        
    And the "ruby22-sample-build-3" build failed                                                          
    When I run the :logs client command with:                                                             
      | resource_name | build/ruby22-sample-build-3 |
    Then the step should succeed                                                                          
    And the output should contain "HTTPError Could not fetch specs from https://rubygems.org"                                          
    Given master config is merged with the following hash:                                                
    """
    admissionConfig:
      pluginConfig:
        BuildDefaults:
          configuration:
            apiVersion: v1
            kind: BuildDefaultsConfig
            gitHTTPProxy: http://error.rdu.redhat.com:3128
            gitHTTPSProxy: https://error.rdu.redhat.com:3128
            env:
            - name: CUSTOM_VAR
              value: custom_value
    """
    Given the master service is restarted on all master nodes                                             
    When I run the :start_build client command with:                                                      
      | buildconfig | ruby22-sample-build                                         |
      | env         | http_proxy=http://<%= cb.proxy_ip %>:<%= cb.proxy_port %>   |
      | env         | https_proxy=http://<%= cb.proxy_ip %>:<%= cb.proxy_port %> |
    Then the step should succeed                                                                          
    And the "ruby22-sample-build-4" build failed                                                          
    When I run the :logs client command with:                                                             
      | resource_name | build/ruby22-sample-build-4 |
    Then the step should succeed                                                                         
    And the output should contain "unable to access 'https://github.com/openshift/ruby-hello-world.git/'" 

  # @author wewang@redhat.com
  # @case_id OCP-10964
  @admin
  @destructive
  Scenario: Set NoProxy env in bc when build
    Given I have a project
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        BuildDefaults:
          configuration:
            apiVersion: v1
            kind: BuildDefaultsConfig
            gitHTTPProxy: http://error.rdu.redhat.com:3128
            gitHTTPSProxy: https://error.rdu.redhat.com:3128
    """
    Given the master service is restarted on all master nodes
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/build/ruby22rhel7-template-sti.json |
    Then the step should succeed
    And the "ruby22-sample-build-1" build failed
    When I run the :patch client command with:
      | resource      | buildconfig                                                                                                          |
      | resource_name |  ruby22-sample-build                                                                                                 |
      | p             | {"spec": {"source": { "git": {"uri": "https://github.com/openshift/ruby-hello-world.git","noProxy": "github.com"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby22-sample-build |
    Then the step should succeed
    And the "ruby22-sample-build-2" build completed 

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
