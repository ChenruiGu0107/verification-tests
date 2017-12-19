Feature: ONLY ONLINE related feature's scripts in this file

  # @author bingli@redhat.com
  # @case_id OCP-9781
  Scenario: cli disables Docker builds and custom builds and allow only sti builds
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | centos/ruby-22-centos7~https://github.com/openshift/ruby-hello-world.git |
      | name     | sti-bc    |
    Then the step should succeed
    When I run the :new_build client command with:
      | app_repo | centos/ruby-22-centos7~https://github.com/openshift/ruby-hello-world.git |
      | name     | docker-bc |
      | strategy | docker    |
    Then the step should fail
    And the output should contain:
      | build strategy Docker is not allowed |
    When I process and create "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-custombuild.json"
    Then the step should fail
    And the output should contain:
      | build strategy Custom is not allowed |
    When I replace resource "bc" named "sti-bc":
      | sourceStrategy | dockerStrategy |
      | type: Source   | type: Docker   |
    Then the step should fail
    And the output should contain:
      | build strategy Docker is not allowed |

  # @author etrott@redhat.com
  Scenario Outline: Maven repository can be used to providing dependency caching for xPaas and wildfly STI builds
    Given I create a new project
    When I run the :new_build client command with:
      | image_stream | openshift/<image_name>:<image_tag>  |
      | code         | <source_url>                        |
      | name         | maven-build                         |
      | context_dir  | <context_dir>                       |
      | e            | MAVEN_MIRROR_URL=<maven_mirror_url> |
    Then the step should succeed
    Then the "maven-build-1" build was created
    And the "maven-build-1" build completed
    When I run the :build_logs client command with:
      | build_name | maven-build-1 |
    Then the output should match:
      | Downloading:\s*https://mirror.openshift.com/nexus/content/groups/public |
    When I run the :patch client command with:
      | resource      | bc                                                                                                                                                      |
      | resource_name | maven-build                                                                                                                                             |
      | p             | {"spec":{"strategy":{"sourceStrategy":{"env":[{"name":"MAVEN_MIRROR_URL","value":"https://mirror.openshift.com/nexus/content/groups/non-existing/"}]}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | maven-build |
    Then the "maven-build-2" build was created
    And the "maven-build-2" build failed
    When I run the :build_logs client command with:
      | build_name | maven-build-2 |
    Then the output should match:
      | Could not find artifact.*https://mirror.openshift.com/nexus/content/groups/non-existing/ |

    # @case_id OCP-9993
    Examples: xPaas STI builds
      | image_name                          | image_tag | source_url                                                            | context_dir           | maven_mirror_url                                          |
      | jboss-eap70-openshift               | 1.3       | https://github.com/jboss-developer/jboss-eap-quickstarts.git#7.0.0.GA | kitchensink           | https://mirror.openshift.com/nexus/content/groups/public/ |
      | jboss-eap70-openshift               | 1.4       | https://github.com/jboss-developer/jboss-eap-quickstarts.git#7.0.0.GA | kitchensink           | https://mirror.openshift.com/nexus/content/groups/public/ |
      | jboss-eap70-openshift               | 1.5       | https://github.com/jboss-developer/jboss-eap-quickstarts.git#7.0.0.GA | kitchensink           | https://mirror.openshift.com/nexus/content/groups/public/ |
      | jboss-eap70-openshift               | 1.6       | https://github.com/jboss-developer/jboss-eap-quickstarts.git#7.0.0.GA | kitchensink           | https://mirror.openshift.com/nexus/content/groups/public/ |
      | jboss-webserver30-tomcat7-openshift | 1.1       | https://github.com/jboss-openshift/openshift-quickstarts.git          | tomcat-websocket-chat | https://mirror.openshift.com/nexus/content/groups/public/ |
      | jboss-webserver30-tomcat7-openshift | 1.2       | https://github.com/jboss-openshift/openshift-quickstarts.git          | tomcat-websocket-chat | https://mirror.openshift.com/nexus/content/groups/public/ |
      | jboss-webserver30-tomcat7-openshift | 1.3       | https://github.com/jboss-openshift/openshift-quickstarts.git          | tomcat-websocket-chat | https://mirror.openshift.com/nexus/content/groups/public/ |
      | jboss-webserver30-tomcat8-openshift | 1.1       | https://github.com/jboss-openshift/openshift-quickstarts.git          | tomcat-websocket-chat | https://mirror.openshift.com/nexus/content/groups/public/ |
      | jboss-webserver30-tomcat8-openshift | 1.2       | https://github.com/jboss-openshift/openshift-quickstarts.git          | tomcat-websocket-chat | https://mirror.openshift.com/nexus/content/groups/public/ |
      | jboss-webserver30-tomcat8-openshift | 1.3       | https://github.com/jboss-openshift/openshift-quickstarts.git          | tomcat-websocket-chat | https://mirror.openshift.com/nexus/content/groups/public/ |
      | jboss-webserver31-tomcat7-openshift | 1.0       | https://github.com/jboss-openshift/openshift-quickstarts.git          | tomcat-websocket-chat | https://mirror.openshift.com/nexus/content/groups/public/ |
      | jboss-webserver31-tomcat8-openshift | 1.0       | https://github.com/jboss-openshift/openshift-quickstarts.git          | tomcat-websocket-chat | https://mirror.openshift.com/nexus/content/groups/public/ |

    # @case_id OCP-9997
    Examples: wildfly STI builds
      | image_name | image_tag | source_url                                            | context_dir | maven_mirror_url                                          |
      | wildfly    | 8.1       | https://github.com/openshift/openshift-jee-sample.git | /           | https://mirror.openshift.com/nexus/content/groups/public/ |
      | wildfly    | 9.0       | https://github.com/openshift/openshift-jee-sample.git | /           | https://mirror.openshift.com/nexus/content/groups/public/ |
      | wildfly    | 10.0      | https://github.com/openshift/openshift-jee-sample.git | /           | https://mirror.openshift.com/nexus/content/groups/public/ |
      | wildfly    | 10.1      | https://github.com/openshift/openshift-jee-sample.git | /           | https://mirror.openshift.com/nexus/content/groups/public/ |
