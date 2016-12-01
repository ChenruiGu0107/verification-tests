Feature: oc set image related tests

  # @author cryan@redhat.com
  # @case_id 535237
  Scenario: oc set image to update pod with certain label
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/dc-with-two-containers.yaml"
    When I run the :create client command with:
      | f | dc-with-two-containers.yaml |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | dc     |
      | name     | dctest |
      | replicas | 2      |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | deployment=dctest-1 |
    When I run the :tag client command with:
      | source | aosqe/hello-openshift          |
      | dest   | <%= project.name%>/test:latest |
    Then the step should succeed
    When I run the :label client command with:
      | resource | pods                 |
      | name     | <%= @pods[0].name %> |
      | key_val  | test=1234            |
    Then the step should succeed
    When I run the :set_image client command with:
      | resource | pod                                      |
      | keyval   | dctest-1=<%= project.name %>/test:latest |
      | l        | test=1234                                |
    Then the step should succeed
    And the output should contain ""<%= @pods[0].name %>" image updated"
    When I run the :describe client command with:
      | resource | pod                  |
      | name     | <%= @pods[0].name %> |
    Then the step should succeed
    And the output should match " Image:\s+aosqe/hello-openshift"
    When I run the :describe client command with:
      | resource | pod                  |
      | name     | <%= @pods[1].name %> |
    Then the step should succeed
    And the output should not match " Image:\s+aosqe/hello-openshift"

  # @author xiaocwan@redhat.com
  # @case_id 536469
  @admin
  Scenario: oc set image for daemonset
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/3b3859001d64e0a1aba78ff20646a2fc29078bf3/daemon/daemonset.yaml |
      | n | <%= project.name %>                             |
    Then the step should succeed
    When I run the :set_image admin command with:
      | type_name       | daemonset/hello-daemonset         |
      | container_image | *=xiaocwan/hello-openshift:latest |
      | source          | docker                            |
      | n               | <%= project.name %>               |
    Then the step should succeed
    When I run the :describe admin command with:
      | resource        | daemonset                         |
      | name            | hello-daemonset                   |
      | n               | <%= project.name %>               |
    Then the step should succeed
    And the output should match:
      | [Ii]mage.*xiaocwan/hello-openshift:latest           |

  # @author xiaocwan@redhat.com
  # @case_id 535232
  Scenario: oc set image to update existed image for container with --source
    Given I have a project
    ## 1.  Create pod container(s) and ISs for project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/dc-with-two-containers.yaml |
    Then the step should succeed
    When I run the :tag client command with:
      | source      | docker.io/openshift/origin-pod        |
      | dest        | <%= project.name %>/op:latest         |
    Then the step should succeed
    When I run the :tag client command with:
      | source      | docker.io/openshift/hello-openshift   |
      | dest        | <%= project.name %>/ho:latest         |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project istag
    Then the output should contain:
      | ho:latest   |
      | op:latest   |
    """
    ## 2. Update image for container(s) for dc
    When I run the :set_image client command with:
      | type_name       | dc/dctest                         |
      | container_image | dctest-1=<%= project.name %>/op:latest     |
      | container_image | dctest-2=<%= project.name %>/ho:latest     |
    Then the step should succeed   
    ## 3. Check container image(s) for dc, pods
    When I run the :describe client command with:
      | resource        | dc                                |
      | name            | dctest                            |
    Then the step should succeed
    And the output should match:
      | dctest-1:\n.*[Ii]mage.*openshift/origin-pod         |
      | dctest-2:\n.*[Ii]mage.*openshift/hello-openshift    |
    Given all pods in the project are ready
    When I run the :describe client command with:
      | resource        | pod                               |
    Then the step should succeed
    And the output should match:
      | dctest-1:\n.*\n.*[Ii]mage.*openshift/origin-pod     |
      | dctest-2:\n.*\n.*[Ii]mage.*openshift/hello-openshift|
    ## 4. oc set image with --source
    When I run the :set_image client command with:
      | type_name       | dc/dctest                         |
      | container_image | dctest-1=xiaocwan/hello-openshift:latest    |
    Then the step should fail
    And the output should match:
      | [Ee]rror.*dctest-1      |
    When I run the :set_image client command with:
      | type_name       | dc/dctest                         |
      | container_image | dctest-1=xiaocwan/hello-openshift:latest    |
      | source          | docker                            |
    Then the step should succeed
    When I run the :describe client command with:
      | resource        | dc                                |
      | name            | dctest                            |
    Then the step should succeed
    And the output should match:
      | dctest-1:\n.*[Ii]mage.*xiaocwan/hello-openshift     |
    ## 5. Negative test
    When I run the :set_image client command with:
      | type_name       | dc/dctest                         |
      | container_image | inexistent=xiaocwan/hello-openshift:latest |  
    Then the step should fail
    And the output should match:
      | [Ee]rror.*unable to find container.*inexistent      |
    When I run the :set_image client command with:
      | type_name       | dc/dctest                         |
      | container_image | dctest-1=xiaocwan/hello-openshift:latest   |
      | container_image | dctest-2=xiaocwan/busybox:latest  |      
      | container_image | dctest-3=xiaocwan/test:latest     |      
      | source          | docker                            |
    Then the step should fail
    And the output should match:
      | deploymentconfig.*dctest.*image updated             |
      | [Ee]rror.*unable to find container.*dctest-3        |

  # @author xiaocwan@redhat.com
  # @case_id 535236
  Scenario: oc set image to update existed image for all resource using local file without and with apply
    Given I have a project
    ## 1.  Create pod container(s) and ISs for project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/dc-with-two-containers.yaml |
    Then the step should succeed
    When I run the :tag client command with:
      | source      | docker.io/openshift/hello-openshift   |
      | dest        | <%= project.name %>/ho:latest         |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project istag
    Then the output should contain:
      | ho:latest   |
    """
    When I run the :set_image client command with:
      | type_name       | dc,rc                             |
      | container_image | dctest-1=<%= project.name %>/ho:latest     |  
      | all             | true                              |
    Then the step should succeed 
    ## step 3 checking
    When I run the :describe client command with:
      | resource        | dc                                |
      | name            | dctest                            |
    Then the step should succeed
    And the output should match:
      | dctest-1:\n.*[Ii]mage.*openshift/hello-openshift    |
    When I run the :describe client command with:
      | resource        | rc                                |
      | name            | dctest-1                          |
    Then the step should succeed
    And the output should match:
      | [Ii]mage.*openshift/hello-openshift                 |
    ## 4. Local update the 2nd container without actually apply
    When I run the :get client command with:
      | resource | dc   |
      | o        | yaml |
    Then the step should succeed
    And I save the output to file> dc.yaml
    When I run the :set_image client command with:
      | filename        | dc.yaml                           |
      | container_image | dctest-2=<%= project.name %>/ho:latest     |
      | local           | true                              |
    Then the step should succeed
    When I run the :describe client command with:
      | resource        | dc                                |
      | name            | dctest                            |
    Then the step should succeed
    And the output should match:
      | dctest-2.*\n.*[Ii]mage.*yapei/hello-openshift-fedora|
    ## 5. Update without --local to apply
    When I run the :set_image client command with:
      | filename        | dc.yaml                           |
      | container_image | dctest-2=<%= project.name %>/ho:latest     |  
    Then the step should succeed 
    When I run the :describe client command with:
      | resource        | dc                                |
      | name            | dctest                            |
    Then the step should succeed
    And the output should match:
      | dctest-1:\n.*[Ii]mage.*openshift/hello-openshift    |
      | dctest-2:\n.*[Ii]mage.*openshift/hello-openshift    |
