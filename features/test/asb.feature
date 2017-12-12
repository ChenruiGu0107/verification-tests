Feature: Ansible-service-broker related scenarios

  @admin
  Scenario: test configmap and serviceinstance
    Given I have a project
    And evaluation of `project.name` is stored in the :org_proj_name clipboard
    # Provision mediawiki apb
    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And evaluation of `YAML.load(configmap('broker-config').value_of('broker-config'))['registry'][0]['name']` is stored in the :prefix clipboard
    # need to swtich back to normal user mode
    And I switch to the first user
    And I use the "<%= cb.org_proj_name %>" project
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | param | INSTANCE_NAME=<%= cb.prefix %>-mediawiki-apb          |
      | param | CLASS_EXTERNAL_NAME=<%= cb.prefix %>-mediawiki-apb    |
      | param | SECRET_NAME=<%= cb.prefix %>-mediawiki-apb-parameters |
      | param | INSTANCE_NAMESPACE=<%= project.name %>                |
    Then the step should succeed
    And evaluation of `service_instance('<%= cb.prefix %>-mediawiki-apb').uid` is stored in the :mediawiki_uid clipboard
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml |
      | param | SECRET_NAME=<%= cb.prefix %>-mediawiki-apb-parameters |
      | param | INSTANCE_NAME=<%= cb.prefix %>-mediawiki-apb          |
      | param | UID=<%= cb.mediawiki_uid %>                           |
      | n     | <%= project.name %>                                   |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=mediawiki123-1  |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance |
    Then the step should succeed
    And the output should match 2 times:
      | Message:\\s+The instance was provisioned successfully |
    """

    # Add credentials to mediawiki application
    When I run the :patch client command with:
      | resource      | dc           |
      | resource_name | mediawiki123 |
      | p             | spec:\n  template:\n    spec:\n      containers:\n      - envFrom:\n        - secretRef:\n            name: <%= cb.prefix %>-postgresql-apb-credentials\n        name: mediawiki123\n |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | deployment=mediawiki123-2 |

