Feature: Ansible-service-broker related scenarios

  # @author jiazha@redhat.com
  # @case_id OCP-15344
  @admin
  @destructive
  Scenario: Set the ASB fresh time
    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project

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
      | resource_name | dc/asb                             |
    Then the step should succeed
    And the output should match 2 times:
      | refresh specs every 1m0s seconds       |
    """

  # @author jiazha@redhat.com
  # @case_id OCP-15348
  @admin
  @destructive
  Scenario: Configure multiple registries for an adapter in one broker
    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project

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
    And the "ansible-service-broker" cluster service broker is recreated

    When I run the :patch client command with:
      | resource           | clusterservicebroker     |
      | resource_name      | ansible-service-broker   |
      | p                  | {"spec":{"caBundle":""}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource           | clusterservicebroker     |
      | name               | ansible-service-broker   |
    And the output should contain "x509: certificate signed by unknown authority"
