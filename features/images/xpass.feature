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



