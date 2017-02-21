Feature: Testing registry

  # @author haowang@redhat.com
  # @case_id OCP-10015
  @admin
  @destructive
  Scenario: Docker-registry with whitelist
    Given I have a project
    And I select a random node's host
    Given the node service is verified
    And the node service is restarted on the host after scenario
    And I register clean-up steps:
    """
    And I run commands on the host:
      | systemctl restart docker |
    Then the step should succeed
    """
    And the "/etc/sysconfig/docker" file is restored on host after scenario
    And I run commands on the host:
      | sed -i '/^BLOCK_REGISTRY*/d' /etc/sysconfig/docker |
    Then the step should succeed
    And I run commands on the host:
      | sed -i '/^*ADD_REGISTRY/d' /etc/sysconfig/docker |
    Then the step should succeed
    And I run commands on the host:
      | echo "BLOCK_REGISTRY='--block-registry=all'" >> /etc/sysconfig/docker |
    Then the step should succeed
    And I run commands on the host:
      | systemctl restart docker |
    Then the step should succeed
    And I run commands on the host:
      | docker pull docker.io/library/centos:latest |
    Then the step failed
    And the output should contain:
      | blocked |
    And I run commands on the host:
      | echo "ADD_REGISTRY='--add-registry docker.io'" >> /etc/sysconfig/docker |
    Then the step should succeed
    And I run commands on the host:
      | systemctl restart docker |
    Then the step should succeed
    And I run commands on the host:
      | docker pull docker.io/library/centos:latest |
    Then the step should succeed

  # @author: haowang@redhat.com
  # @case_id: OCP-10898
  @admin
  Scenario: Have size information for any image pushed
    Given I have a project
    And I run the :tag client command with:
      | source_type | docker                                  |
      | source      | docker.io/aosqe/pushwithdocker19:latest |
      | dest        | pushwithdocker19:latest                 |
    Then the step should succeed
    And the "pushwithdocker19:latest" image stream tag was created
    And evaluation of `image_stream_tag("pushwithdocker19:latest").digest(user:user)` is stored in the :digest clipboard
    Then I run the :describe admin command with:
      | resource | image            |
      | name     | <%= cb.digest %> |
    And the output should match:
      | Image Size:.* |

  # @author haowang@redhat.com
  # @case_id: OCP-12400
  @admin
  @destructive
  Scenario: Prune images by command oadm_prune_images
    Given cluster role "system:image-pruner" is added to the "first" user
    Given I have a project
    And I run the :new_build client command with:
      | app_repo | openshift/ruby:2.3~https://github.com/openshift/ruby-ex |
    Then the step should succeed
    And the "ruby-ex-1" build was created
    Then the "ruby-ex-1" build completed
    And the "ruby-ex:latest" image stream tag was created
    And evaluation of `image_stream_tag("ruby-ex:latest").image_layers(user:user)` is stored in the :layers clipboard
    And evaluation of `image_stream_tag("ruby-ex:latest").digest(user:user)` is stored in the :digest clipboard
    And default registry route is stored in the :registry_ip clipboard
    And I ensures "ruby-ex" imagestream is deleted
    Given I delete the project
    And I run the :oadm_prune_images client command with:
      | keep_younger_than | 0                     |
      | confirm           | true                  |
      | registry_url      | <%= cb.registry_ip %> |
    Then the step should succeed
    And all the image layers in the :layers clipboard were deleted
    When I run the :get client command with:
      | resource | images |
    Then the step should succeed
    And the output should not contain:
      | <%= cb.digest %> |

  # @author haowang@redhat.com
  # @case_id OCP-10010
  @admin
  @destructive
  Scenario: Re-using the Registry IP address
    Given I have a project
    And I run the :new_build client command with:
      | app_repo | openshift/ruby:2.3~https://github.com/openshift/ruby-ex |
    Then the step should succeed
    And the "ruby-ex-1" build was created
    Then the "ruby-ex-1" build completed
    And evaluation of `project.name` is stored in the :prj1 clipboard
    And default docker-registry replica count is restored after scenario
    Given I switch to cluster admin pseudo user
    When I run the :get admin command with:
       | resource      | service         |
       | resource_name | docker-registry |
       | namespace     | default         |
       | o             | yaml            |
    And I save the output to file>svc.yaml
    Then admin ensures "docker-registry" service is deleted from the "default" project
    Given I run the :scale client command with:
      | resource | dc              |
      | name     | docker-registry |
      | replicas | 0               |
    Then the step should succeed
    Then I run the :create admin command with:
      | f         | ./svc.yaml |
      | namespace | default    |
    And the step should succeed
    Given I run the :scale client command with:
      | resource | dc              |
      | name     | docker-registry |
      | replicas | 1               |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deploymentconfig=docker-registry |
    Given I switch to the first user
    And I use the "<%= cb.prj1 %>" project
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    And the "ruby-ex-2" build was created
    Given the "ruby-ex-2" build completes
