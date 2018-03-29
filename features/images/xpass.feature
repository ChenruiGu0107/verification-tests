Feature: xpass.feature

  # @author haowang@redhat.com
  # @case_id OCP-9659
  Scenario: Create jbossamq resource from imagestream via oc new-app - jboss-amq62
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | jboss-amq-62        |
      | env          | AMQ_USER=user       |
      | env          | AMQ_PASSWORD=passwd |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=jboss-amq-62 |
  # @author haowang@redhat.com
  # @case_id OCP-12533
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
  Scenario Outline: jbosseap template
    Given I have a project
    When I run the :create client command with:
      | f | <secretfile>       |
    Then the step should succeed
    When I run the :new_app client command with:
      | template |  <template> |
    Then the step should succeed
    And the "eap-app-1" build was created
    And the "eap-app-1" build completed
    And <podno> pods become ready with labels:
      |application=eap-app|

    Examples: OS Type
      | secretfile                                                                                                 | template             | podno |
      | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/eap-app-secret.json | eap64-amq-s2i        | 2     | # @case_id OCP-9586
      | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/eap-app-secret.json | eap64-basic-s2i      | 1     | # @case_id OCP-9745
      | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/eap7-app-secret.json| eap70-basic-s2i      | 1     | # @case_id OCP-16543
      | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/eap-app-secret.json | eap64-https-s2i      | 1     | # @case_id OCP-9746
      | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/eap-app-secret.json | eap64-mongodb-s2i    | 2     | # @case_id OCP-12429
      | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/eap-app-secret.json | eap64-mysql-s2i      | 2     | # @case_id OCP-12414
      | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/eap-app-secret.json | eap64-postgresql-s2i | 2     | # @case_id OCP-12524
  # @author haowang@redhat.com
  # @case_id OCP-9749
  Scenario: Create amq application from template in web console - amq62-ssl
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/amq-app-secret.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | template | amq62-ssl                        |
      | param    | AMQ_TRUSTSTORE_PASSWORD=password |
      | param    | AMQ_KEYSTORE_PASSWORD=password   |
    Then the step should succeed
    And a pod becomes ready with labels:
      | application=broker |
  # @author haowang@redhat.com
  # @case_id OCP-9661
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
    Then I wait for a web server to become available via the "jboss-eap-quickstarts" route
    And  the output should contain "JBoss"

  # @author haowang@redhat.com
  # @case_id OCP-12439
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
    Then I wait for a web server to become available via the "eap-app" route
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
    Then I wait for a web server to become available via the "eap-app" route
    And  the output should contain "JBoss"
    Then I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | <%= cb.rc_name %>      |
      | replicas | 1                      |
    And 1 pods become ready with labels:
      |application=eap-app|
    Then I wait for a web server to become available via the "eap-app" route
    And  the output should contain "JBoss"

  # @author xiuwang@redhat.com
  Scenario Outline: Create tomcat7/tomcat8 application via installed template
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/jws-app-secret.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | template |  <template> |
    Then the step should succeed
    And the "jws-app-1" build was created
    And the "jws-app-1" build completed
    Given I wait for the "jws-app" service to become ready
    And I get the service pods
    And I wait up to 900 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -k | <%= service.url %>/websocket-chat/ |
    Then the step should succeed
    """
    And the output should contain "WebSocket connection opened"

    Examples:
      | template                |
      | jws30-tomcat7-basic-s2i | # @case_id OCP-9581
      | jws30-tomcat8-basic-s2i | # @case_id OCP-9582
      | jws30-tomcat7-https-s2i | # @case_id OCP-9814
      | jws30-tomcat8-https-s2i | # @case_id OCP-9813

  # @author xiuwang@redhat.com
  Scenario Outline: Create tomcat7/tomcat8 with mongodb application via installed template
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/jws-app-secret.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | template |  <template> |
    Then the step should succeed
    And the "jws-app-1" build was created
    And the "jws-app-1" build completed
    Given I wait for the "jws-app" service to become ready
    And I get the service pods
    And I wait up to 900 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -k | <%= service.url %> |
    Then the step should succeed
    """
    And the output should contain "TODO list"
    Given 1 pods become ready with labels:
      | deploymentconfig=jws-app-mongodb |
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -lc | mongo $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD  --eval 'db.version()' |
    Then the step should succeed
    """
    And the output should contain:
      | 3.2 |

    Examples:
      | template                  |
      | jws30-tomcat7-mongodb-s2i | # @case_id OCP-9587
      | jws30-tomcat8-mongodb-s2i | # @case_id OCP-9583

  # @author xiuwang@redhat.com
  Scenario Outline: Create tomcat7/tomcat8 with postgresql application via installed template
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/jws-app-secret.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | template |  <template> |
    Then the step should succeed
    And the "jws-app-1" build was created
    And the "jws-app-1" build completed
    Given I wait for the "jws-app" service to become ready
    And I get the service pods
    And I wait up to 900 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -k | <%= service.url %> |
    Then the step should succeed
    """
    And the output should contain "TODO list"
    Given 1 pods become ready with labels:
      | deploymentconfig=jws-app-postgresql |
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c 'CREATE TABLE tbl (col1 VARCHAR(20), col2 VARCHAR(20));' -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    """
    And the output should contain:
      | CREATE TABLE |

    Examples:
      | template                      |
      |  jws30-tomcat7-postgresql-s2i | # @case_id OCP-9590
      |  jws30-tomcat8-postgresql-s2i | # @case_id OCP-9591

  # @author xiuwang@redhat.com
  Scenario Outline: Create tomcat7/tomcat8 with mysql application via installed template
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/jws-app-secret.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | template |  <template> |
    Then the step should succeed
    And the "jws-app-1" build was created
    And the "jws-app-1" build completed
    Given I wait for the "jws-app" service to become ready
    And I get the service pods
    And I wait up to 900 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -k | <%= service.url %> |
    Then the step should succeed
    """
    And the output should contain "TODO list"
    Given 1 pods become ready with labels:
      | deploymentconfig=jws-app-mysql |
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | mysql  -h $JWS_APP_MYSQL_SERVICE_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD -e "show databases" |
    Then the step should succeed
    """
    And the output should contain "root"

    Examples:
      | template                 |
      |  jws30-tomcat7-mysql-s2i | # @case_id OCP-9588
      |  jws30-tomcat8-mysql-s2i | # @case_id OCP-9589
  # @author haowang@redhat.com
  Scenario Outline: jbosseap templates with pv
    Given I have a project
    When I run the :create client command with:
      | f | <secretfile>       |
    Then the step should succeed
    When I run the :new_app client command with:
      | template |  <template> |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | <pvc>                                                                           |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    And the "<pvc>" PVC becomes :bound within 300 seconds
    And the "eap-app-1" build was created
    And the "eap-app-1" build completed
    And <podno> pods become ready with labels:
      |application=eap-app|

    Examples: OS Type
     |secretfile | template                        | podno | pvc                      |
     | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/eap-app-secret.json | eap64-amq-persistent-s2i        | 2     | eap-app-amq-claim        | # @case_id OCP-9585
     | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/eap-app-secret.json | eap64-mongodb-persistent-s2i    | 2     | eap-app-mongodb-claim    | # @case_id OCP-9743
     | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/eap7-app-secret.json| eap70-mongodb-persistent-s2i    | 2     | eap-app-mongodb-claim    | # @case_id OCP-16545
     | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/eap-app-secret.json | eap64-mysql-persistent-s2i      | 2     | eap-app-mysql-claim      | # @case_id OCP-9740
     | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/eap7-app-secret.json| eap70-mysql-persistent-s2i      | 2     | eap-app-mysql-claim      | # @case_id OCP-16546
     | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/eap-app-secret.json | eap64-postgresql-persistent-s2i | 2     | eap-app-postgresql-claim | # @case_id OCP-9744
     | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/eap7-app-secret.json| eap70-postgresql-persistent-s2i | 2     | eap-app-postgresql-claim | # @case_id OCP-16526
  # @author haowang@redhat.com
  # @case_id OCP-9739
  Scenario: Create amq application from pre-installed templates : amq62-persistent-ssl
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/amq-app-secret.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | template | amq62-persistent-ssl |
      | param    | AMQ_TRUSTSTORE_PASSWORD=password |
      | param    | AMQ_KEYSTORE_PASSWORD=password   |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | broker-amq-claim                                                                |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    And the "broker-amq-claim" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | application=broker |

  # @author haowang@redhat.com
  # @case_id OCP-9584
  Scenario: Create amq application from pre-installed templates: amq62-persistent
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/amq-app-secret.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | template | amq62-persistent |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | broker-amq-claim                                                                |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    And the "broker-amq-claim" PVC becomes :bound within 300 seconds
    And a pod becomes ready with labels:
      | application=broker |

  # @author dyan@redhat.com
  Scenario Outline: Create tomcat7/tomcat8 with mongodb with persistent volume application via installed template
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/jws-app-secret.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | template |  <template> |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | jws-app-mongodb-claim                                                           |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    And the "jws-app-mongodb-claim" PVC becomes :bound within 300 seconds
    And the "jws-app-1" build was created
    And the "jws-app-1" build completed
    Given I wait for the "jws-app" service to become ready
    And I get the service pods
    And I wait up to 900 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -ksS | <%= service.url %> |
    Then the step should succeed
    """
    And the output should contain "TODO list"
    Given 1 pods become ready with labels:
      | deploymentconfig=jws-app-mongodb |
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -lc | mongo $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD  --eval 'db.version()' |
    Then the step should succeed
    """
    And the output should contain:
      | 3.2 |

    Examples:
      | template                  |
      | jws30-tomcat7-mongodb-persistent-s2i | # @case_id OCP-11749
      | jws30-tomcat8-mongodb-persistent-s2i | # @case_id OCP-11725

  # @author dyan@redhat.com
  Scenario Outline: Create tomcat7/tomcat8 with postgresql with persistent volume application via installed template
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/jws-app-secret.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | template |  <template> |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | jws-app-postgresql-claim                                                        |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    And the "jws-app-postgresql-claim" PVC becomes :bound within 300 seconds
    And the "jws-app-1" build was created
    And the "jws-app-1" build completed
    Given I wait for the "jws-app" service to become ready
    And I get the service pods 
    And I wait up to 900 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -ksS | <%= service.url %> |
    Then the step should succeed
    """
    And the output should contain "TODO list"
    Given 1 pods become ready with labels:
      | deploymentconfig=jws-app-postgresql |
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -lc | psql -U $POSTGRESQL_USER -c 'CREATE TABLE tbl (col1 VARCHAR(20), col2 VARCHAR(20));' -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    """
    And the output should contain:
      | CREATE TABLE |

    Examples:
      | template                      |
      |  jws30-tomcat7-postgresql-persistent-s2i | # @case_id OCP-11901
      |  jws30-tomcat8-postgresql-persistent-s2i | # @case_id OCP-11891

  # @author dyan@redhat.com
  Scenario Outline: Create tomcat7/tomcat8 with mysql with persistent volume application via installed template
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/jboss-openshift/application-templates/master/secrets/jws-app-secret.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | template |  <template> |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | jws-app-mysql-claim                                                        |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    And the "jws-app-mysql-claim" PVC becomes :bound within 300 seconds
    And the "jws-app-1" build was created
    And the "jws-app-1" build completed
    Given I wait for the "jws-app" service to become ready
    And I get the service pods
    And I wait up to 900 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -ksS | <%= service.url %> |
    Then the step should succeed
    """
    And the output should contain "TODO list"
    Given 1 pods become ready with labels:
      | deploymentconfig=jws-app-mysql |
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -lc | mysql  -h $JWS_APP_MYSQL_SERVICE_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD -e "show databases" |
    Then the step should succeed
    """
    And the output should contain "root"

    Examples:
      | template                 |
      |  jws30-tomcat7-mysql-persistent-s2i | # @case_id OCP-11922
      |  jws30-tomcat8-mysql-persistent-s2i | # @case_id OCP-11923

  # @author haowang@redhat.com
  # @case_id OCP-12449
  Scenario: Customize MAVEN_ARGS during maven build
    Given I have a project
    When I run the :new_build client command with:
      | code         | https://github.com/jboss-developer/jboss-eap-quickstarts#6.4.x              |
      | context_dir  | helloworld                                                                  |
      | image_stream | jboss-eap64-openshift                                                       |
      | e            | MAVEN_ARGS=-Popenshift -DskipTests -Dcom.redhat.xpaas.repo.redhatga package |
    Then the step should succeed
    And the "jboss-eap-quickstarts-1" build completed
    When I run the :logs client command with:
      | resource_name | jboss-eap-quickstarts-1-build |
    Then the output should contain:
      | -Popenshift -DskipTests -Dcom.redhat.xpaas.repo.redhatga package |
