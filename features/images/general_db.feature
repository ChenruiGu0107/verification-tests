Feature: general_db.feature

  # @author cryan@redhat.com
  # @case_id 484487
  Scenario: Use mysql in openshift app
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc484487/jws-app-secret.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc484487/jboss-image-streams.json |
      | n | <%= project.name %> |
    Then the step should succeed
    And the output should contain "jboss-webserver3-tomcat7-openshift"
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc484487/jws-tomcat7-mysql-sti.json"
    #The following replacements occur because the original lines violate
    #the 15 char name limit otherwise
    Given I replace lines in "jws-tomcat7-mysql-sti.json":
      | jws-app | jws |
      | -mysql-tcp-3306 | -tcp-3306 |
      | jws.local | |
    When I run the :new_app client command with:
      | file | jws-tomcat7-mysql-sti.json |
    Then the step should succeed
    When I use the "jws-http-service" service
    Then I wait for a server to become available via the "jws-http-route" route
