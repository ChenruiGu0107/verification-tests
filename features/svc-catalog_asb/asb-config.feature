Feature: Ansible-service-broker related scenarios

  # @author jiazha@redhat.com
  # @case_id OCP-15344
  @admin
  @destructive
  Scenario: Set the ASB fresh time
    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    Given the "ansible-service-broker" cluster service broker is recreated
    Given admin redeploys "asb" dc after scenario
    And the "broker-config" configmap is recreated by admin in the "openshift-ansible-service-broker" project after scenario

    # Update the configmap settings
    Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
    """
    "broker":
      "refresh_interval": 60s
    """
    And admin redeploys "asb" dc
    And I wait up to 150 seconds for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name | dc/asb                      |
    Then the step should succeed
    And the output should match 2 times:
      | refresh specs every 1m0s seconds            |
    """

  # @author jiazha@redhat.com
  # @case_id OCP-15348
  @admin
  @destructive
  Scenario: Configure multiple registries for an adapter in one broker
    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    Given the "ansible-service-broker" cluster service broker is recreated
    Given admin redeploys "asb" dc after scenario
    And the "broker-config" configmap is recreated by admin in the "openshift-ansible-service-broker" project after scenario
    # Update the configmap settings
    Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
    """
    registry:
      - type: dockerhub
        name: rh
        url:  https://registry.hub.docker.com
        org:  ansibleplaybookbundle
        tag:  latest
        white_list: [u'.*-apb$']
      - type: dockerhub
        name: dh
        url:  https://registry.hub.docker.com
        org:  aosqe
        tag:  latest
        white_list: [u'.*-apb$']
    """
    And admin redeploys "asb" dc
    When I run the :logs client command with:
      | resource_name | dc/asb          |
      | since         | 3m              |
    Then the step should succeed
    And the output should match:
      | Name: rh      |
      | Name: dh      |

    # Update the configmap settings
    Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
    """
    registry:
      - type: dockerhub
        name: test
        url:  https://registry.hub.docker.com
        org:  ansibleplaybookbundle
        tag:  latest
        white_list: [u'.*-apb$']
      - type: dockerhub
        name: test
        url:  https://registry.hub.docker.com
        org:  aosqe
        tag:  latest
        white_list: [u'.*-apb$']
    """
    When I run the :rollout_latest client command with:
      | resource      | dc/asb          |
    Then the step should succeed
    Then status becomes :failed of 1 pods labeled:
      | deploymentconfig=asb            |

  # @case_id OCP-16373
  @destructive
  @admin
  Scenario: ASB connect to Multi-Cat with SSL
    When I run the :get client command with:
      | resource           | clusterserviceclass                                        |
      | o                  | custom-columns=BROKER\ NAME:.spec.clusterServiceBrokerName |
    Then the output should contain "ansible-service-broker"

    When I switch to cluster admin pseudo user
    # Revert to the original configuration
    And the "ansible-service-broker" cluster service broker is recreated after scenario

    When I run the :patch client command with:
      | resource           | clusterservicebroker     |
      | resource_name      | ansible-service-broker   |
      | p                  | {"spec":{"caBundle":""}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource           | clusterservicebroker     |
      | name               | ansible-service-broker   |
    And the output should contain "x509: certificate signed by unknown authority"

    # @author jiazha@redhat.com
    # @case_id OCP-15362
    @admin
    @destructive
    Scenario: [ASB] Filter APB images by whitelist/blacklist
      When I switch to cluster admin pseudo user
      And I use the "openshift-ansible-service-broker" project
      Given the "ansible-service-broker" cluster service broker is recreated
      Given admin redeploys "asb" dc after scenario
      And the "broker-config" configmap is recreated by admin in the "openshift-ansible-service-broker" project after scenario

      Given evaluation of `route("asb-1338").dns` is stored in the :asb_url clipboard
      And evaluation of `secret('asb-client').token` is stored in the :asb_token clipboard

      # white list only
      Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
      """
      registry:
        - type: dockerhub
          name: dh
          url:  registry.hub.docker.com
          org:  ansibleplaybookbundle
          tag:  latest
          white_list: ['.*mediawiki-apb$']
      """
      And admin redeploys "asb" dc
      Given I switch to the first user
      And I have a project
      And I have a pod-for-ping in the project
      When I execute on the pod:
        | curl                                                             |
        | -H                                                               |
        | Authorization: Bearer <%= cb.asb_token %>                        |
        | -sk                                                              |
        | https://<%= cb.asb_url %>/ansible-service-broker/v2/catalog      |
      Then the output should contain "mediawiki-apb"

      # black list only
      And I switch to cluster admin pseudo user
      And I use the "openshift-ansible-service-broker" project
      Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
      """
      registry:
        - type: dockerhub
          name: dh
          url:  registry.hub.docker.com
          org:  ansibleplaybookbundle
          tag:  latest
          black_list: ['.*mediawiki-apb$']
      """
      And admin redeploys "asb" dc
      Given I switch to the first user
      When I execute on the pod:
        | curl                                                             |
        | -H                                                               |
        | Authorization: Bearer <%= cb.asb_token %>                        |
        | -sk                                                              |
        | https://<%= cb.asb_url %>/ansible-service-broker/v2/catalog      |
      Then the output should contain "[]"

      # both white and black list
      And I switch to cluster admin pseudo user
      And I use the "openshift-ansible-service-broker" project
      Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
      """
      registry:
        - type: dockerhub
          name: dh
          url:  registry.hub.docker.com
          org:  ansibleplaybookbundle
          tag:  latest
          white_list: ['.*-apb$']
          black_list: ['.*mediawiki-apb$']
      """
      And admin redeploys "asb" dc
      Given I switch to the first user
      When I execute on the pod:
        | curl                                                             |
        | -H                                                               |
        | Authorization: Bearer <%= cb.asb_token %>                        |
        | -sk                                                              |
        | https://<%= cb.asb_url %>/ansible-service-broker/v2/catalog      |
      Then the output should not contain "mediawiki-apb"

      And I switch to cluster admin pseudo user
      And I use the "openshift-ansible-service-broker" project
      Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
      """
      registry:
        - type: dockerhub
          name: dh
          url:  registry.hub.docker.com
          org:  ansibleplaybookbundle
          tag:  latest
          white_list: ['.*mediawiki-apb$']
          black_list: ['.*mediawiki-apb$']
      """
      And admin redeploys "asb" dc
      Given I switch to the first user
      When I execute on the pod:
        | curl                                                             |
        | -H                                                               |
        | Authorization: Bearer <%= cb.asb_token %>                        |
        | -sk                                                              |
        | https://<%= cb.asb_url %>/ansible-service-broker/v2/catalog      |
      Then the output should contain "[]"

  # @author zitang@redhat.com
  # @case_id OCP-16367
  @admin
  @destructive
  Scenario: AnsibleServiceBroker BasicAuth username password
    Given I switch to cluster admin pseudo user
    #back up and clean env , the recreating will be in reverse order in cleanup process.
    And the "ansible-service-broker" cluster service broker is recreated after scenario
    And I register clean-up steps:
    """
      I wait up to 150 seconds for the steps to pass:
        | When I run the :logs admin command with:                |
        | \| resource_name \| dc/asb \|                           |
        | \| namespace     \| openshift-ansible-service-broker \| |
        | Then the step should succeed                            |
        | And the output should contain "Broker successfully bootstrapped on startup" |
    """
    And the "asb" dc is recreated by admin in the "openshift-ansible-service-broker" project after scenario
    And the "broker-config" configmap is recreated by admin in the "openshift-ansible-service-broker" project after scenario
    And admin ensures "asb-auth-secret" secret is deleted from the "openshift-ansible-service-broker" project after scenario

    # Get the asb route and dc image as key to patch
    And I use the "openshift-ansible-service-broker" project
    And evaluation of `secret('asb-client').token` is stored in the :token clipboard
    And evaluation of `route("asb-1338").dns` is stored in the :asbUrl clipboard
    And evaluation of `dc("asb").containers_spec[0].image` is stored in the :asbImage clipboard

    #create a client secret
    When I run the :create_secret client command with:
      | name         | asb-auth-secret   |
      | secret_type  | generic           |
      | from_literal | username=admin    |
      | from_literal | password=admin    |
    Then the step should succeed
    #Update  cm broker-config,
    Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
    """
    broker:
      auth:
      - type: basic
        enabled: true
    """
   #Update dc
    When I run the :patch client command with:
      | resource     |  dc/asb                                         |
      | p            | {                                               |
      |              |   "spec":{                                      |
      |              |     "template":{                                |
      |              |       "spec":{                                  |
      |              |         "containers":[                          |
      |              |           {                                     |
      |              |             "name":"asb",                       |
      |              |             "image":"<%= cb.asbImage %>",       |
      |              |             "volumeMounts":[                    |
      |              |               {                                 |
      |              |                 "name":"asb-auth-volume",       |
      |              |                 "mountPath":"/var/run/asb-auth" |
      |              |               }                                 |
      |              |             ]                                   |
      |              |           }                                     |
      |              |         ],                                      |
      |              |         "volumes":[                             |
      |              |           {                                     |
      |              |             "name":"asb-auth-volume",           |
      |              |             "secret":{                          |
      |              |               "defaultMode":420,                |
      |              |               "secretName":"asb-auth-secret"    |
      |              |             }                                   |
      |              |           }                                     |
      |              |         ]                                       |
      |              |       }                                         |
      |              |     }                                           |
      |              |   }                                             |
      |              | }                                               |
    Then the step should succeed
    And I wait up to 150 seconds for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name | dc/asb                             |
    Then the step should succeed
    And the output should contain "Broker successfully bootstrapped on startup"
    """

   #Access the ASB api with valid basic auth
    Given I switch to the first user
    And I have a project
    And I have a pod-for-ping in the project
    When I execute on the pod:
      | curl                                                                   |
      | -sk                                                                    |
      | https://admin:admin@<%= cb.asbUrl %>/ansible-service-broker/v2/catalog |
    Then the output should match:
      | services                                                               |
      | name.*apb                                                              |
      | description                                                            |
     #Access the ASB api with invalid password
    When I execute on the pod:
      | curl                                                                   |
      | -sk                                                                    |
      | https://admin:test@<%= cb.asbUrl %>/ansible-service-broker/v2/catalog  |
     #Access the ASB api with bearer
    Then the output should contain "invalid credentials"
    When I execute on the pod:
      | curl                                                                   |
      | -H                                                                     |
      | Authorization: Bearer <%= cb.token %>                                  |
      | -sk                                                                    |
      | https://<%= cb.asbUrl %>/ansible-service-broker/v2/catalog             |
    Then the output should contain "invalid credentials"

    #check we can get classerviceclass after edit ansible-service-broker
    #edit ansible-service-broker
    Given I switch to cluster admin pseudo user
    And I run the :patch client command with:
      | resource     | clusterservicebroker/ansible-service-broker              |
      | p            |{                                                         |
      |              |  "spec": {                                               |
      |              |    "authInfo": {                                         |
      |              |      "basic": {                                          |
      |              |        "secretRef": {                                    |
      |              |          "name": "asb-auth-secret",                      |
      |              |          "namespace": "openshift-ansible-service-broker" |
      |              |        }                                                 |
      |              |      }                                                   |
      |              |    }                                                     |
      |              |  }                                                       |
      |              |}                                                         |
    Then the step should succeed
    When I run the :get client command with:
      | resource         | clusterservicebroker                    |
      | resource_name    | ansible-service-broker                  |
      | o                | jsonpath={.status.conditions[0].status} |
    Then the output should equal "True"


  # @author zitang@redhat.com
  # @case_id OCP-15397
  @admin
  @destructive
  Scenario: Check secrets support for ansible-service-broker
    Given the "ansible-service-broker" cluster service broker is recreated after scenario
    Given I register clean-up steps:
    """
      I wait up to 150 seconds for the steps to pass:
        | When I run the :logs admin command with:                |
        | \| resource_name \| dc/asb \|                           |
        | \| namespace     \| openshift-ansible-service-broker \| |
        | Then the step should succeed                            |
        | And the output should contain "Broker successfully bootstrapped on startup" |
    """
    And the "asb" dc is recreated by admin in the "openshift-ansible-service-broker" project after scenario
    And the "broker-config" configmap is recreated by admin in the "openshift-ansible-service-broker" project after scenario
    And admin ensures "test-secret" secret is deleted from the "openshift-ansible-service-broker" project after scenario

    And I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And evaluation of `YAML.load(config_map('broker-config').value_of('broker-config'))['registry'][0]['name']` is stored in the :prefix clipboard
    When I run the :create_secret client command with:
      | name         | test-secret               |
      | secret_type  | generic                   |
      | from_literal | postgresql_database=test  |
    Then the step should succeed
    # Update the configmap settings
    Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
    """
    openshift:
      namespace: openshift-ansible-service-broker
    secrets:
     - title: Database credentials
       secret: test-secret
       apb_name: <%= cb.prefix %>-postgresql-apb
    """
    And admin redeploys "asb" dc
    And I wait up to 150 seconds for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name | dc/asb                             |
    Then the step should succeed
    And the output should contain "Broker successfully bootstrapped on startup"
    """

    #relist clusterserviceplan
    Given the "ansible-service-broker" cluster service broker is recreated
    When I run the :describe client command with:
      | resource           | clusterservicebroker     |
      | name               | ansible-service-broker   |
    And the output should match:
      | Reason:\\s+FetchedCatalog  |
      | Status:\\s+True  |
    Given cluster service classes are indexed by external name in the :csc clipboard
    And evaluation of `cb.csc['<%= cb.prefix %>-postgresql-apb'].name` is stored in the :postgresql_name clipboard
    When I run the :get client command with:
      | resource | clusterserviceplan                                                                                                 |
      | o        | custom-columns=NAME:.metadata.name,CLASS\ NAME:.spec.clusterServiceClassRef.name,EXTERNAL\ NAME:.spec.externalName |
    Then the output should contain "<%= cb.postgresql_name %>"
    And evaluation of `@result[:response].scan(/.*#{cb.postgresql_name}.*dev/)[0].split(" ")[0]` is stored in the :plan_dev clipboard
    And evaluation of `@result[:response].scan(/.*#{cb.postgresql_name}.*prod/)[0].split(" ")[0]` is stored in the :plan_prod clipboard
    When I run the :get client command with:
      | resource      | clusterserviceplan                                         |
      | resource_name | <%= cb.plan_dev %>                                         |
      | resource_name | <%= cb.plan_prod %>                                        |
      | o             |  jsonpath={.spec.instanceCreateParameterSchema.properties} |
    Then the output should not contain "postgresql_database"


  # @author zhsun@redhat.com
  # @case_id OCP-15939
  @admin
  @destructive
  Scenario: [ASB] Support concurrent, multiple APB source adapters
    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    Given the "ansible-service-broker" cluster service broker is recreated
    Given admin redeploys "asb" dc after scenario
    And the "broker-config" configmap is recreated by admin in the "openshift-ansible-service-broker" project after scenario

    Given evaluation of `route("asb-1338").dns` is stored in the :asb_url clipboard
    And evaluation of `secret('asb-client').token` is stored in the :asb_token clipboard

    # Update the configmap settings
    Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
    """
    registry:
      - type: dockerhub
        name: dh
        url:  https://registry.hub.docker.com
        org:  ansibleplaybookbundle
        tag:  latest
        white_list: ['.*-apb$']
      - type: rhcc
        name: rh
        url:  registry.access.stage.redhat.com
        tag:  v3.7.0
        white_list: ['.*-apb$']
    """
    And admin redeploys "asb" dc
    When I run the :logs client command with:
      | resource_name | dc/asb          |
      | since         | 3m              |
    Then the step should succeed
    And the output should match:
      | Type: dockerhub      |
      | Type: rhcc           |

    #And admin redeploys "asb" dc
    Given I switch to the first user
    And I have a project
    And I have a pod-for-ping in the project
    When I execute on the pod:
      | curl                                                             |
      | -H                                                               |
      | Authorization: Bearer <%= cb.asb_token %>                        |
      | -sk                                                              |
      | https://<%= cb.asb_url %>/ansible-service-broker/v2/catalog      |
    Then the output should match:
      | rh  |
      | dh  |

