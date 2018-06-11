Feature: genericbuild.feature
  # @author wewang@redhat.com
  # @case_id OCP-14373
  Scenario: Support valueFrom with filedRef syntax for pod field
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc14373/test-valuefrom.json"
    And I run the :create client command with:
      | f | test-valuefrom.json | 
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :running
    When I run the :env client command with:
      | resource | pods/hello-openshift |
      | list     | true                 |
    And the output should contain:
      |  podname from field path metadata.name |
    And I replace lines in "test-valuefrom.json":
      | "fieldPath":"metadata.name" | "fieldPath":"" | 
    Then the step should succeed
    And I run the :create client command with:
      | f | test-valuefrom.json |
    Then the step should fail
    And the output should contain "valueFrom.fieldRef.fieldPath: Required value"

  # @author wewang@redhat.com
  # @case_id OCP-14381
  Scenario: Support valueFrom with configMapKeyRef syntax for pod field
    Given I have a project
    When I run the :create_configmap client command with:
      | name         | special-config     |
      | from_literal | special.how=very   |
      | from_literal | special.type=charm |
    Then the step should succeed
    When I run the :get client command with:
      | resource  | configmap |
      | o         | yaml      |
    Then the output should match:
      | special.how: very |
      | special.type: charm |
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc14381/test-valuefrommap.json"
    And I run the :create client command with:
      | f | test-valuefrommap.json |
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :running
    When I run the :env client command with:
      | resource | pods/hello-openshift |
      | list     | true                 |
    Then the step should succeed
    And the output should contain:
      | SPECIAL_LEVEL_KEY from configmap special-config, key special.how |
      | SPECIAL_TYPE_KEY from configmap special-config, key special.type |
    And I replace lines in "test-valuefrommap.json":
      | "key":"special.how" | "key":"" |
    Then the step should succeed
    And I run the :create client command with:
      | f | test-valuefrommap.json |
    Then the step should fail
    And the output should contain "configMapKeyRef.key: Required value"

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
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc15352_15353/service.yaml |
      | p | PROTOCOL=UDP                                                                                        |
      | p | CONTAINER_PORT=abc                                                                                  | 
      | p | EXT_PORT=efg                                                                                        |
      | p | NODE_TEMPLATE_NAME=bug-param                                                                        |
    And the step should fail
    Then the output should contain "decNum: got first char 'e'"

  # @author wewang@redhat.com
  # @case_id OCP-15352
    Scenario: Setting ports using parameter in template and set parameter value with number
    Given I have a project
    And I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc15352_15353/service.yaml | 
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
            gitHTTPProxy: http://<%= cb.proxy_ip %>:3128
            gitHTTPSProxy: https://<%= cb.proxy_ip %>:3128 
            env:
            - name: CUSTOM_VAR
              value: custom_value
    """
    Given the master service is restarted on all master nodes
    When I run the :new_app client command with:                                                          
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json |
      | env  | http_proxy=http://<%= cb.proxy_ip %>:3128                                                              |
      | env  | https_proxy=https://<%= cb.proxy_ip %>:3128                                                            |
    Then the step should succeed                                                                          
    And the "ruby22-sample-build-1" build completes                                                       
    Given 2 pods become ready with labels:                                                                
      | app=ruby-helloworld-sample |
    When I execute on the pod:                                                                            
      | env |
    Then the step should succeed                                                                          
    And the output should contain "https_proxy=https://<%= cb.proxy_ip %>:3128"                         
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
            gitHTTPProxy: http://<%= cb.proxy_ip %>:3128
            gitHTTPSProxy: https://<%= cb.proxy_ip %>:3128 
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
      | buildconfig | ruby22-sample-build                         |
      | env         | http_proxy=http://<%= cb.proxy_ip %>:3128   |
      | env         | https_proxy=https://<%= cb.proxy_ip %>:3128 |
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
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json |
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
  # @case_id OCP-10965
  @admin
  @destructive
  Scenario: Configure the noproxy BuildDefaults when build
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
            gitNoProxy: github.com 
    """
    Given the master service is restarted on all master nodes
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json |
    Then the step should succeed
    And the "ruby22-sample-build-1" build completed
