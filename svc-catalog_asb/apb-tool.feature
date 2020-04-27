Feature: The apb tool related scenarios
    
  # @author jiazha@redhat.com
  # @case_id OCP-18562
  @admin
  @destructive
  Scenario: [APB] Check the apb tool subcommand - bootstrap
    Given the first user is cluster-admin
    And I use the "openshift-ansible-service-broker" project
    And evaluation of `route('asb-1338').dns` is stored in the :asb_route clipboard

    When I run the :bootstrap client command with:
      | _tool | apb |
    Then the step should succeed
    And the output should contain "Successfully bootstrapped Ansible Service Broker"
    And the output should contain "Successfully relisted the Service Catalog"
    When I run the :bootstrap client command with:
      | _tool  | apb                 |
      | broker | <%= cb.asb_route %> |
    Then the step should succeed
    And the output should contain "Successfully bootstrapped Ansible Service Broker"
    And the output should contain "Successfully relisted the Service Catalog"
    When I run the :bootstrap client command with:
      | _tool       | apb                    |
      | broker-name | ansible-service-broker |
    Then the step should succeed
    And the output should contain "Successfully bootstrapped Ansible Service Broker"
    And the output should contain "Successfully relisted the Service Catalog"
    When I run the :bootstrap client command with:
      | _tool     | apb |
      | no-relist |     |
    Then the step should succeed
    And the output should contain "Successfully bootstrapped Ansible Service Broker"
    And the output should not contain "Successfully relisted the Service Catalog"
    
  # @author jiazha@redhat.com
  # @case_id OCP-15042
  @admin
  @destructive
  Scenario: [APB] Check the apb tool subcommand - remove
    Given the first user is cluster-admin
    And I use the "openshift-ansible-service-broker" project
    And evaluation of `route('asb-1338').dns` is stored in the :asb_route clipboard
    And evaluation of `YAML.load(config_map('broker-config').value_of('broker-config'))['registry'][0]['name']` is stored in the :prefix clipboard
    Given the "ansible-service-broker" cluster service broker is recreated after scenario
    Given admin redeploys "asb" dc after scenario
    And the "broker-config" configmap is recreated by admin in the "openshift-ansible-service-broker" project after scenario

    # Update the configmap settings
    Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
    """
    "broker":
      "dev_broker": true
    """
    And admin redeploys "asb" dc


    Given cluster service classes are indexed by external name in the :csc clipboard
    And evaluation of `cb.csc['<%= cb.prefix %>-mediawiki-apb'].name` is stored in the :class_id clipboard

    # Temporary deletion
    When I run the :remove client command with:
      | _tool | apb            |
      | id    | <%= cb.class_id %>   |
    Then the step should succeed
    And the output should contain "Successfully relisted the Service Catalog"
    And the output should contain "Successfully deleted APB"
    
    When I run the :list client command with:
      | _tool | apb |
    Then the step should succeed
    And the output should not contain "Exception"
    And the output should not contain "Error"
    And the output should not contain "No APBs found"
    And the output should not contain "<%= cb.class_id %>"
    
    When I run the :bootstrap client command with:
      | _tool | apb |
    Then the step should succeed
    
    When I run the :list client command with:
      | _tool | apb |
    Then the step should succeed
    And the output should not contain "Exception"
    And the output should not contain "Error"
    And the output should not contain "No APBs found"
    And the output should contain "<%= cb.class_id %>"

    # Temporary deletion all
    When I run the :remove client command with:
      | _tool | apb            |
      | all   |                |
    Then the step should succeed
    And the output should contain "Successfully relisted the Service Catalog"
    And the output should contain "Successfully deleted APB"
    When I run the :list client command with:
      | _tool | apb |
    Then the step should succeed
    And the output should contain "No APBs found"
    
  # @author jiazha@redhat.com
  # @case_id OCP-18557
  @admin
  @destructive
  Scenario: [APB] Check the apb tool subcommand - push
    Given the first user is cluster-admin
    And I use the "default" project
    And evaluation of `route('docker-registry').dns` is stored in the :docker_registry clipboard
    And I use the "openshift-ansible-service-broker" project
    And evaluation of `route('asb-1338').dns` is stored in the :asb_route clipboard
    And evaluation of `YAML.load(config_map('broker-config').value_of('broker-config'))['registry'][0]['name']` is stored in the :prefix clipboard
    Given the "ansible-service-broker" cluster service broker is recreated after scenario
    Given admin redeploys "asb" dc after scenario
    And the "broker-config" configmap is recreated by admin in the "openshift-ansible-service-broker" project after scenario

    # Add one insecure registry into docker
    Given the expression should be true> @host = localhost
    And the "/etc/sysconfig/docker" file is restored on host after scenario
    And I run commands on the host:
      | sudo sed -i '/^INSECURE_REGISTRY*/d' /etc/sysconfig/docker |
    Then the step should succeed
    And I run commands on the host:
      | echo "INSECURE_REGISTRY='--insecure-registry <%= cb.docker_registry %>'" \| sudo tee /etc/sysconfig/docker |
    Then the step should succeed
    And I run commands on the host:
      | sudo systemctl restart docker |
    Then the step should succeed

    # Update the configmap settings
    Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
    """
    registry:
      - type: local_openshift
        name: localregistry
        namespaces: ['openshift']
        white_list: [.*]
    """
    And admin redeploys "asb" dc

    # Clone an example from the Github
    When I git clone the repo "https://github.com/ansibleplaybookbundle/hello-world-apb.git"

    # Access the target folder and run `apb push`
    When I run the :push client command with:
      | _chdir         | hello-world-apb           |
      | _tool          | apb                       |
      | registry-route | <%= cb.docker_registry %> |
    Then the step should succeed
    
    When I run the :list client command with:
      | _tool | apb |
    Then the step should succeed
    And the output should contain "localregistry-hello-world-apb"

  # @author jfan@redhat.com
  # @case_id OCP-18560
  @admin
  Scenario: [APB] Check the apb tool subcommand - list
    Given I have a project
    Given I switch to cluster admin pseudo user
    Given I store master major version in the :master_version clipboard
    And evaluation of `project.name` is stored in the :cur_project clipboard
    Given I create the serviceaccount "apbtoolsstage"
    Given SCC "privileged" is added to the "system:serviceaccount:<%= project.name %>:apbtoolsstage" service account
    And I use the "<%= project.name %>" project
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/apbtools.yaml |
      | p    | IMAGE=registry.stage.redhat.io/openshift4/apb-tools:v<%= cb.master_version %> |
      | p    | NAMESPACE=<%= cb.cur_project %> |
    Then the step should succeed
    And I wait until the status of deployment "apbtools" becomes :complete
    When I run the :logs client command with:
      | resource_name | deployment/apbtools |
      | since         | 60s                 |
    Then the step should succeed
    And the output should contain:
      | Tool for working with Ansible Playbook Bundles |
