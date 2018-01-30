Feature: oc set image related tests

  # @author cryan@redhat.com
  # @case_id OCP-10309
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

    When I run the :label client command with:
      | resource | pods                 |
      | name     | <%= @pods[0].name %> |
      | key_val  | test=1234            |
    Then the step should succeed
    When I run the :set_image client command with:
      | resource | pod                                      |
      | keyval   | dctest-1=openshift/python:latest         |
      | l        | test=1234                                |
    Then the step should succeed
    And the output should contain ""<%= @pods[0].name %>" image updated"
    
    When I run the :describe client command with:
      | resource | pod                  |
      | name     | <%= @pods[0].name %> |
    Then the step should succeed
    And the output should match "Image:.*python"
    When I run the :describe client command with:
      | resource | pod                  |
      | name     | <%= @pods[1].name %> |
    Then the step should succeed
    And the output should not match "Image:.*python"

  # @author xiaocwan@redhat.com
  # @case_id OCP-10390
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
  # @case_id OCP-10304
  Scenario: oc set image to update existed image for container with --source
    Given I have a project
    ## 1.  Create pod container(s) and ISs for project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/dc-with-two-containers.yaml |
    Then the step should succeed
    ## 2. oc set image with --source=imagestreamtag
    When I run the :set_image client command with:
      | type_name       | dc/dctest                         |
      | container_image | dctest-1=openshift/ruby:latest    |
      | source          | imagestreamtag                    |
    Then the step should succeed
    When I run the :describe client command with:
      | resource        | dc                                |
      | name            | dctest                            |
    Then the step should succeed
    And the output should match "[Ii]mage.*ruby"
    ## 3. oc set image with --source=docker
    When I run the :set_image client command with:
      | type_name       | dc/dctest                         |
      | container_image | dctest-1=openshift/python:latest  |
      | source          | docker                            |
    Then the step should succeed
    When I run the :describe client command with:
      | resource        | dc                                |
      | name            | dctest                            |
    Then the step should succeed
    And the output should match "[Ii]mage.*python"
    ## 4. Negative test
    When I run the :set_image client command with:
      | type_name       | dc/dctest                         |
      | container_image | dctest-1=openshift/python:latest  |
      | source          | notexistsource                    |
    Then the step should fail
    And the output should match "notexistsource"

  # @author xiaocwan@redhat.com
  # @case_id OCP-10308
  Scenario: oc set image to update existed image for all resource using local file without and with apply
    Given I have a project
    ## 1.  Create pod container(s) and dc,rc for project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/dc-with-two-containers.yaml |
    Then the step should succeed
    ## 2. set image with keywork python for compatibility between 3.6 and 3.7 
    When I run the :set_image client command with:
      | type_name       | dc,rc                            |
      | container_image | dctest-1=openshift/python:latest |  
      | all             | true                             |
    Then the step should succeed 
    ## step 3 checking
    When I run the :describe client command with:
      | resource        | dc                                |
      | name            | dctest                            |
    Then the step should succeed
    And the output should match:
      | dctest-1:\n.*[Ii]mage.*python |
    When I run the :describe client command with:
      | resource        | rc                                |
      | name            | dctest-1                          |
    Then the step should succeed
    And the output should match:
      | [Ii]mage.*python  |
    ## 4. Local update the 2nd container without actually apply
    When I run the :get client command with:
      | resource | dc   |
      | o        | yaml |
    Then the step should succeed
    And I save the output to file> dc.yaml
    When I run the :set_image client command with:
      | filename        | dc.yaml                           |
      | container_image | dctest-2=openshift/ruby:latest    |
      | local           | true                              |
    Then the step should succeed
    When I run the :describe client command with:
      | resource        | dc                                |
      | name            | dctest                            |
    Then the step should succeed
    And the output should not match:
      | ruby |
    ## 5. Update without --local to apply
    When I run the :set_image client command with:
      | filename        | dc.yaml                           |
      | container_image | dctest-2=openshift/ruby:latest    |  
    Then the step should succeed 
    When I run the :describe client command with:
      | resource        | dc                                |
      | name            | dctest                            |
    Then the step should succeed
    And the output should match:
      | dctest-1:\n.*[Ii]mage.*python      |
      | dctest-2:\n.*[Ii]mage.*ruby        |

  # @author yinzhou@redhat.com
  # @case_id OCP-11623
  @admin
  Scenario: Can not prune image by conflicted condition flags
    Given I have a project
    Given cluster role "system:image-signer" is added to the "first" user
    Then the step should succeed
    When I run the :oadm_prune_images client command with:
      | confirm               | false |
      | keep_younger_than     | 1m    |
      | prune_over_size_limit | true  |
    Then the step should fail
    And the output should match " cannot be specified with "
    When I run the :oadm_prune_images client command with:
      | confirm               | false |
      | keep_tag_revisions    | 1     |
      | prune_over_size_limit | true  |
    Then the step should fail
    And the output should match " cannot be specified with "


  # @author yinzhou@redhat.com
  # @case_id OCP-11332
  @admin
  Scenario: Admin can understand/manage image use and prune unreferenced image
    Given I have a project
    When I run the :new_app client command with:
      | docker_image   | <%= project_docker_repo %>openshift/deployment-example |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete
    When I run the :new_app client command with:
      | app_repo | centos/ruby-22-centos7~https://github.com/openshift/ruby-ex.git |
    Then the step should succeed
    Given the "ruby-ex-1" build was created
    Given the "ruby-ex-1" build completed
    And evaluation of `image_stream("deployment-example").latest_tag_docker_image_reference(user: user).split("@").last` is stored in the :dc_image_id clipboard
    And evaluation of `image_stream("ruby-ex").latest_tag_docker_image_reference(user: user).split("@").last` is stored in the :ruby_image_id clipboard
    Given cluster role "system:image-pruner" is added to the "first" user
    When I run the :oadm_top_images client command
    And the output should match:
      | <%= cb.dc_image_id %>\\s+<%= project.name %>\/deployment-example \(latest\) |
      | <%= cb.ruby_image_id %>\\s+<%= project.name %>\/ruby-ex \(latest\)          |
    When I run the :delete client command with:
      | object_type | all  |
      | all         | true |
    Then the step should succeed
    When I run the :oadm_top_images client command
    And the output should match:
      | <%= cb.dc_image_id %>\\s+<none>   |
      | <%= cb.ruby_image_id %>\\s+<none> |


  # @author yinzhou@redhat.com
  # @case_id OCP-10909
  @admin
  Scenario: Could add/remove signatures to the images
    Given I have a project
    When I run the :tag client command with:
      | source      | docker.io/openshift/hello-openshift   |
      | dest        | <%= project.name %>/ho:latest         |
    Then the step should succeed
    And evaluation of `image_stream("ho").latest_tag_docker_image_reference(user:user).split("@").last` is stored in the :image_id clipboard
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image-streams/imagesignature.yaml"
    Then the step should succeed
    When I run the :create client command with:
      | f        | imagesignature.yaml |
      | loglevel | 6                   |
    Then the step should fail
    When I run the :delete client command with:
      | object_type | imagesignature |
      | object_name_or_id | <%= cb.image_id %>@imagesignaturetest |
    Then the step should fail
    Given cluster role "system:image-signer" is added to the "first" user
    And I replace lines in "imagesignature.yaml":
      | name: ["metadata"]@["name"] | name:  <%= cb.image_id %>@imagesignaturetest |
    When I run the :create client command with:
      | f        | imagesignature.yaml |
      | loglevel | 6                   |
    Then the step should succeed
    And the output should match:
      | POST (.+)imagesignatures |
    When I run the :get admin command with:
      | resource      | image              |
      | resource_name | <%= cb.image_id %> |
      | o             | yaml               |
    Then the step should succeed
    Then the output should contain:
      | signatures |
      | name: <%= cb.image_id %>@imagesignaturetest |
    And I replace lines in "imagesignature.yaml":
      | name:  <%= cb.image_id %>@imagesignaturetest | name: <%= cb.image_id %>@imagesignaturetest2 |
      | - 25 | - 20 | 
    When I run the :create client command with:
      | f | imagesignature.yaml |
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | image              |
      | resource_name | <%= cb.image_id %> |
      | o             | yaml               |
    Then the step should succeed
    Then the output should contain:
      | signatures |
      | name: <%= cb.image_id %>@imagesignaturetest  |
      | name: <%= cb.image_id %>@imagesignaturetest2 |
    When I run the :delete client command with:
      | object_type | imagesignature |
      | object_name_or_id | <%= cb.image_id %>@imagesignaturetest2 |
    Then the step should succeed
