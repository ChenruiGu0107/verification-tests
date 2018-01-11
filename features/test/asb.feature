Feature: Ansible-service-broker related scenarios

  @admin
  Scenario: test configmap and serviceinstance
    Given I have a project
    And evaluation of `project.name` is stored in the :org_proj_name clipboard
    # Provision mediawiki apb
    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And evaluation of `YAML.load(config_map('broker-config').value_of('broker-config'))['registry'][0]['name']` is stored in the :prefix clipboard
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


  # @author zitang@redhat.com
  # @case_id OCP-15395
  @admin
  Scenario: Check the ASB with bearer token authn
    #Get asb route and ansible service broker  client secret
    Given I have a project
    And evaluation of `project.name` is stored in the :projectName clipboard
    And I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And evaluation of `secret('asb-client').token` is stored in the :token clipboard
    And evaluation of `route("asb-1338").dns` is stored in the :asbUrl clipboard

    #Access the ASB api with valid token
    Given I switch to the first user
    And I use the "<%= cb.projectName %>" project
    And I have a pod-for-ping in the project
    When I execute on the pod:
      | curl                                                       |
      | -H                                                         |
      | Authorization: Bearer <%= cb.token %>                      |
      | -sk                                                        |
      | https://<%= cb.asbUrl %>/ansible-service-broker/v2/catalog |
    Then the output should match:
      | services      |
      | name.*apb     |
      | description   |
    #Access the ASB api with invalid token
     When I execute on the pod:
      | curl                                                       |
      | -H                                                         |
      | Authorization: Bearer XXXXXXXXXXXX                         |
      | -sk                                                        |
      | https://<%= cb.asbUrl %>/ansible-service-broker/v2/catalog |
    Then the output should contain "Unauthorized"

  @admin
  Scenario: Test cluster_service_class methods
    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    Given cluster service classes are indexed by external name in the :csc clipboard
    And evaluation of `cb.csc['rh-mediawiki-apb'].dependencies` is stored in the :media_wiki_dep clipboard
    And evaluation of `cb.csc['rh-mysql-apb'].dependencies` is stored in the :mysql_dep clipboard
    And evaluation of `cb.csc['rh-postgresql-apb'].dependencies` is stored in the :postgresql_dep clipboard
    And evaluation of `cb.csc['rh-mariadb-apb'].dependencies` is stored in the :mariadb_dep clipboard

   Then the expression should be true>  cb.mysql_dep.select { |e| e.start_with? 'registry.access.redhat.com/rhscl/mysql' }.count == 2
   Then the expression should be true>  cb.mariadb_dep.select { |e| e.start_with? 'registry.access.redhat.com/rhscl/mariadb' }.count == 2
   Then the expression should be true>  cb.postgresql_dep.select { |e| e.start_with? 'registry.access.redhat.com/rhscl/postgresql' }.count == 2
   Then the expression should be true>  cb.media_wiki_dep.select { |e| e.start_with? 'registry.access.redhat.com/openshift3/mediawiki' }.count == 1
