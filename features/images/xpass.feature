Feature: xpass.feature

  # @author haowang@redhat.com
  # @case_id 508991
  Scenario: Create jbossamq resource from imagestream via oc new-app - jboss-amq62
    Given I have a project
    When I run the :new_app client command with:
      | image_stream| jboss-amq-62 |
      | env         | AMQ_USER=user,AMQ_PASSWORD=passwd |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=jboss-amq-62 |
  # @author haowang@redhat.com
  # @case_id 484431
  Scenario: Create amq application from template - amq62-basic
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/amq-app-secret.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | template | amq62-basic |
    Then the step should succeed
    And a pod becomes ready with labels:
      | application=broker |
  # @author haowang@redhat.com
  # @case_id 498017 484397 469045 469043 514975 514973
  Scenario Outline: jbosseap template
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/eap-app-secret.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | template |  <template> |
    Then the step should succeed
    And the "eap-app-1" build was created
    And the "eap-app-1" build completed
    And <podno> pods become ready with labels:
     |application=eap-app|

    Examples: OS Type
      | template             | podno |
      | eap64-amq-s2i        | 2     |
      | eap64-basic-s2i      | 1     |
      | eap64-https-s2i      | 1     |
      | eap64-mongodb-s2i    | 2     |
      | eap64-mysql-s2i      | 2     |
      | eap64-postgresql-s2i | 2     |
  # @author haowang@redhat.com
  # @case_id 515426
  Scenario: Create amq application from template in web console - amq62-ssl
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/amq-app-secret.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | template | amq62-ssl |
      | param    | AMQ_TRUSTSTORE_PASSWORD=password,AMQ_KEYSTORE_PASSWORD=password |
    Then the step should succeed
    And a pod becomes ready with labels:
      | application=broker |
  # @author haowang@redhat.com
  # @case_id 508993
  Scenario: create resource from imagestream via oc new-app-jboss-eap6-openshift
    Given I have a project
    When I run the :new_app client command with:
      | app_repo    | jboss-eap64-openshift~https://github.com/jboss-developer/jboss-eap-quickstarts#6.4.x |
      | context_dir | kitchensink |
    Then the step should succeed
    And the "jboss-eap-quickstarts-1" build was created
    And the "jboss-eap-quickstarts-1" build completed
    And a pod becomes ready with labels:
      |app=jboss-eap-quickstarts|
    When I expose the "jboss-eap-quickstarts" service
    Then I wait for a server to become available via the "jboss-eap-quickstarts" route
    And  the output should contain "JBoss"

  # @author haowang@redhat.com
  # @case_id 469046
  Scenario: Clustering app of Jboss EAP can work well
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/eap-app-secret.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | template | eap64-basic-s2i |
    Then the step should succeed
    And the "eap-app-1" build was created
    And the "eap-app-1" build completed
    And 1 pods become ready with labels:
      |application=eap-app|
    And I use the "eap-app" service
    Then I wait for a server to become available via the "eap-app" route
    And  the output should contain "JBoss"
    When I get project replicationcontroller as JSON
    And evaluation of `@result[:parsed]['items'][0]['metadata']['name']` is stored in the :rc_name clipboard
    Then I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | <%= cb.rc_name %>      |
      | replicas | 2                      |
    Then the step should succeed
    And 2 pods become ready with labels:
      |application=eap-app|
    And I use the "eap-app" service
    Then I wait for a server to become available via the "eap-app" route
    And  the output should contain "JBoss"
    Then I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | <%= cb.rc_name %>      |
      | replicas | 1                      |
    And 1 pods become ready with labels:
      |application=eap-app|
    Then I wait for a server to become available via the "eap-app" route
    And  the output should contain "JBoss"
