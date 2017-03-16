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
    And all the image layers in the :layers clipboard do not exist in the registry
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

  # @author haowang@redhat.com
  # @case_id OCP-11038
  @admin
  @destructive
  Scenario: Disable the mirroring function for registry
    Given default docker-registry deployment config is restored after scenario
    And I change the internal registry pod to use a new emptyDir volume
    When I run the :env admin command with:
      | resource  | dc/docker-registry                                      |
      | e         | REGISTRY_OPENSHIFT_MIDDLEWARE_MIRRORPULLTHROUGH=false   |
      | namespace | default                                                 |
    Then the step should succeed
    Given I wait until the latest rc of internal registry is ready
    Given I create a new project
    When I run the :tag client command with:
      | source_type | docker                                 |
      | source      | docker.io/aosqe/hello-openshift:latest |
      | dest        | hello-world:latest                     |
    Then the step should succeed
    When I run the :import_image client command with:
      | from       | docker.io/openshift/ruby-20-centos7:latest |
      | image_name | ruby-20-centos7:latest                     |
      | confirm    | true                                       |
    Then the step should succeed
    When I find a bearer token of the deployer service account
    And default registry service ip is stored in the :registry_ip clipboard
    And I select a random node's host
    When I run commands on the host:
      | docker login -u dnm -p <%= service_account.get_bearer_token.token %> -e dnm@redmail.com <%= cb.registry_ip %> |
    Then the step should succeed
    When I run commands on the host:
      | docker pull <%= cb.registry_ip %>/<%= project.name %>/hello-world:latest |
    Then the step should succeed
    When I run commands on the host:
      | docker pull <%= cb.registry_ip %>/<%= project.name %>/ruby-20-centos7:latest |
    Then the step should succeed
    And evaluation of `image_stream_tag("hello-world:latest").image_layers(user:user)` is stored in the :layers clipboard
    And all the image layers in the :layers clipboard do not exist in the registry
    And evaluation of `image_stream_tag("ruby-20-centos7:latest").image_layers(user:user)` is stored in the :layers clipboard
    And all the image layers in the :layers clipboard do not exist in the registry
    When I run the :cp admin command with:
      | source | default/<%= pod.name %>:/config.yml |
      | dest   | ./config.yml                |
    Then the step should succeed
    And I replace content in "config.yml":
      | mirrorpullthrough: true | mirrorpullthrough: false |
    Then the step should succeed
    And I run the :new_secret admin command with:
      | secret_name     | registry-config |
      | credential_file | ./config.yml    |
      | namespace       | default         |
    Then the step should succeed
    And admin ensures "registry-config" secrets is deleted from the "default" project after scenario
    And I run the :volume admin command with:
      | resource    | dc/docker-registry |
      | add         | true               |
      | name        | config             |
      | mount-path  | /config            |
      | type        | secret             |
      | secret-name | registry-config    |
      | namespace   | default            |
    Then the step should succeed
    Given I wait until the latest rc of internal registry is ready
    When I run the :env admin command with:
      | resource  | dc/docker-registry                               |
      | env_name  | REGISTRY_OPENSHIFT_MIDDLEWARE_MIRRORPULLTHROUGH- |
      | env_name  | REGISTRY_CONFIGURATION_PATH=/config/config.yml   |
      | namespace | default                                          |
    Then the step should succeed
    Given I wait until the latest rc of internal registry is ready
    And I create a new project
    When I run the :tag client command with:
      | source_type | docker                                 |
      | source      | docker.io/aosqe/hello-openshift:latest |
      | dest        | hello-world:latest                     |
    Then the step should succeed
    When I run the :import_image client command with:
      | from       | docker.io/openshift/ruby-20-centos7:latest |
      | image_name | ruby-20-centos7:latest                     |
      | confirm    | true                                       |
    Then the step should succeed
    When I find a bearer token of the deployer service account
    And default registry service ip is stored in the :registry_ip clipboard
    And I select a random node's host
    When I run commands on the host:
      | docker login -u dnm -p <%= service_account.get_bearer_token.token %> -e dnm@redmail.com <%= cb.registry_ip %> |
    Then the step should succeed
    When I run commands on the host:
      | docker pull <%= cb.registry_ip %>/<%= project.name %>/hello-world:latest |
    Then the step should succeed
    When I run commands on the host:
      | docker pull <%= cb.registry_ip %>/<%= project.name %>/ruby-20-centos7:latest |
    Then the step should succeed
    And evaluation of `image_stream_tag("hello-world:latest").image_layers(user:user)` is stored in the :layers clipboard
    And all the image layers in the :layers clipboard do not exist in the registry
    And evaluation of `image_stream_tag("ruby-20-centos7:latest").image_layers(user:user)` is stored in the :layers clipboard
    And all the image layers in the :layers clipboard do not exist in the registry

  # @author haowang@redhat.com
  # @case_id OCP-11415
  @admin
  @destructive
  Scenario: Mirror blobs to the local registry on pullthrough
    Given default docker-registry deployment config is restored after scenario
    And I change the internal registry pod to use a new emptyDir volume
    And I create a new project
    When I run the :tag client command with:
      | source_type | docker             |
      | source      | docker.io/busybox  |
      | dest        | hello-world:latest |
    Then the step should succeed
    When I find a bearer token of the deployer service account
    And default registry service ip is stored in the :registry_ip clipboard
    And I select a random node's host
    When I run commands on the host:
      | docker rmi docker.io/busybox:latest |
    When I run commands on the host:
      | docker login -u dnm -p <%= service_account.get_bearer_token.token %> -e dnm@redmail.com <%= cb.registry_ip %> |
    Then the step should succeed
    When I run commands on the host:
      | docker pull <%= cb.registry_ip %>/<%= project.name %>/hello-world:latest |
    Then the step should succeed
    And I register clean-up steps:
    """
    And I run commands on the host:
      | docker rmi <%= cb.registry_ip %>/<%= project.name %>/hello-world:latest |
    """
    And evaluation of `image_stream_tag("hello-world:latest").image_layers(user:user)` is stored in the :layers clipboard
    And all the image layers in the :layers clipboard do exist in the registry

  # @author haowang@redhat.com
  # @case_id OCP-11490
  @admin
  @destructive
  Scenario: Import new tags to image stream
    Given I have a project
    And I select a random node's host
    And I have a registry in my project
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
      | sed -i '/^INSECURE_REGISTRY*/d' /etc/sysconfig/docker |
    Then the step should succeed
    And I run commands on the host:
      | echo "INSECURE_REGISTRY='--insecure-registry <%= cb.reg_svc_url%>'" >> /etc/sysconfig/docker |
    Then the step should succeed
    And I run commands on the host:
      | systemctl restart docker |
    Then the step should succeed
    And I run commands on the host:
      | docker pull docker.io/busybox:latest |
    Then the step should succeed
    And I run commands on the host:
      | docker tag docker.io/busybox:latest <%= cb.reg_svc_url %>/test/busybox:latest|
    Then the step should succeed
    Then I wait up to 60 seconds for the steps to pass:
    """
    And I run commands on the host:
      | docker push <%= cb.reg_svc_url %>/test/busybox:latest|
    Then the step should succeed
    """
    When I run the :import_image client command with:
      | from       | <%= cb.reg_svc_url %>/test/busybox |
      | image_name | busybox                            |
      | all        | true                               |
      | confirm    | true                               |
      | insecure   | true                               |
    Then the step should succeed
    And the "busybox:latest" image stream tag was created
    And I run commands on the host:
      | docker tag docker.io/busybox:latest <%= cb.reg_svc_url %>/test/busybox:v1|
    Then the step should succeed
    And I run commands on the host:
      | docker push <%= cb.reg_svc_url %>/test/busybox:v1 |
    Then the step should succeed
    When I run the :import_image client command with:
      | from       | <%= cb.reg_svc_url %>/test/busybox |
      | image_name | busybox                            |
      | confirm    | true                               |
      | all        | true                               |
      | insecure   | true                               |
    Then the step should succeed
    And the "busybox:v1" image stream tag was created
    And I run commands on the host:
      | docker pull docker.io/library/centos:latest |
    Then the step should succeed
    And I run commands on the host:
      | docker tag docker.io/library/centos:latest <%= cb.reg_svc_url %>/test/busybox:centos |
    Then the step should succeed
    And I run commands on the host:
      | docker push <%= cb.reg_svc_url %>/test/busybox:centos |
    Then the step should succeed
    When I run the :import_image client command with:
      | from       | <%= cb.reg_svc_url %>/test/busybox |
      | image_name | busybox                            |
      | confirm    | true                               |
      | all        | true                               |
      | insecure   | true                               |
    Then the step should succeed
    And the "busybox:centos" image stream tag was created

  # @author: haowang@redhat.com
  # @case_id: OCP-11310
  @admin
  Scenario: Have size information for images pushed to internal registry
    Given I have a project
    When I find a bearer token of the builder service account
    And default registry service ip is stored in the :registry_ip clipboard
    And I select a random node's host
    When I run commands on the host:
      | docker login -u dnm -p <%= service_account.get_bearer_token.token %> -e dnm@redmail.com <%= cb.registry_ip %> |
    Then the step should succeed
    When I run commands on the host:
      | docker pull docker.io/aosqe/pushwithdocker19:latest |
    Then the step should succeed
    When I run commands on the host:
      | docker tag docker.io/aosqe/pushwithdocker19:latest <%= cb.registry_ip %>/<%= project.name %>/busybox:latest |
    Then the step should succeed
    When I run commands on the host:
      | docker push  <%= cb.registry_ip %>/<%= project.name %>/busybox:latest |
    Then the step should succeed
    And evaluation of `image_stream_tag("busybox:latest").digest(user:user)` is stored in the :digest clipboard
    Then I run the :describe admin command with:
      | resource | image            |
      | name     | <%= cb.digest %> |
    And the output should match:
      | Image Size:.* |

  # @author haowang@redhat.com
  # @case_id: OCP-11544
  @admin
  @destructive
  Scenario: Create docker registry with special ports
    Given I switch to cluster admin pseudo user
    And default docker-registry replica count is restored after scenario
    When I run the :get admin command with:
       | resource      | service         |
       | resource_name | docker-registry |
       | namespace     | default         |
       | o             | yaml            |
    And I save the output to file>svc.yaml
    Then admin ensures "docker-registry" service is deleted from the "default" project
    When I run the :get admin command with:
       | resource      | dc              |
       | resource_name | docker-registry |
       | namespace     | default         |
       | o             | yaml            |
    And I save the output to file>dc.yaml
    Then admin ensures "docker-registry" dc is deleted from the "default" project
    And I register clean-up steps:
    """
    Then admin ensures "docker-registry" service is deleted from the "default" project
    Then admin ensures "docker-registry" dc is deleted from the "default" project
    And I run the :create admin command with:
       | f         | ./dc.yaml |
       | namespace | default   |
    Then the step should succeed
    And I run the :create admin command with:
       | f         | ./svc.yaml |
       | namespace | default    |
    Then the step should succeed
    And the master service is restarted on all master nodes
    """
    When I run the :oadm_registry admin command with:
      | ports     | 5001    |
      | namespace | default |
    And a pod becomes ready with labels:
      | deploymentconfig=docker-registry |
    And the master service is restarted on all master nodes
    Given I switch to the first user
    And I have a project
    When I run the :import_image client command with:
      | from       | docker.io/openshift/ruby-20-centos7:latest |
      | image_name | ruby-20-centos7:latest                     |
      | confirm    | true                                       |
    Then the step should succeed
    When I find a bearer token of the deployer service account
    And default registry service ip is stored in the :registry_ip clipboard
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
      | sed -i '/^INSECURE_REGISTRY*/d' /etc/sysconfig/docker |
    Then the step should succeed
    And I run commands on the host:
      | echo "INSECURE_REGISTRY='--insecure-registry <%= cb.registry_ip %>'" >> /etc/sysconfig/docker |
    Then the step should succeed
    And I run commands on the host:
      | systemctl restart docker |
    Then the step should succeed
    Then I wait up to 60 seconds for the steps to pass:
    """
    When I run commands on the host:
      | docker login -u dnm -p <%= service_account.get_bearer_token.token %> -e dnm@redmail.com <%= cb.registry_ip %> |
    Then the step should succeed
    """
    When I run commands on the host:
      | docker pull <%= cb.registry_ip %>/<%= project.name %>/ruby-20-centos7:latest |
    Then the step should succeed

  # @author haowang@redhat.com
  # @case_id: OCP-11215
  @admin
  @destructive
  Scenario: Create docker registry with options mount-host and service-account
    Given I switch to cluster admin pseudo user
    And default docker-registry replica count is restored after scenario
    When I run the :get admin command with:
       | resource      | service         |
       | resource_name | docker-registry |
       | namespace     | default         |
       | o             | yaml            |
    And I save the output to file>svc.yaml
    Then admin ensures "docker-registry" service is deleted from the "default" project
    When I run the :get admin command with:
       | resource      | dc              |
       | resource_name | docker-registry |
       | namespace     | default         |
       | o             | yaml            |
    And I save the output to file>dc.yaml
    Then admin ensures "docker-registry" dc is deleted from the "default" project
    And I register clean-up steps:
    """
    Then admin ensures "docker-registry" service is deleted from the "default" project
    Then admin ensures "docker-registry" dc is deleted from the "default" project
    And I run the :create admin command with:
       | f         | ./dc.yaml |
       | namespace | default   |
    Then the step should succeed
    And I run the :create admin command with:
       | f         | ./svc.yaml |
       | namespace | default    |
    Then the step should succeed
    And the master service is restarted on all master nodes
    """
    Given SCC "privileged" is added to the "registry" service account
    When I run the :oadm_registry admin command with:
      | mount_host     | /tmp |
      | serviceaccount | registry   |
      | namespace      | default    |
    And a pod becomes ready with labels:
      | deploymentconfig=docker-registry |
    And the master service is restarted on all master nodes
    Given I switch to the first user
    And I have a project
    When I find a bearer token of the builder service account
    And default registry service ip is stored in the :registry_ip clipboard
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
      | sed -i '/^INSECURE_REGISTRY*/d' /etc/sysconfig/docker |
    Then the step should succeed
    And I run commands on the host:
      | echo "INSECURE_REGISTRY='--insecure-registry <%= cb.registry_ip %>'" >> /etc/sysconfig/docker |
    Then the step should succeed
    And I run commands on the host:
      | systemctl restart docker |
    Then the step should succeed
    Then I wait up to 60 seconds for the steps to pass:
    """
    When I run commands on the host:
      | docker login -u dnm -p <%= service_account.get_bearer_token.token %> -e dnm@redmail.com <%= cb.registry_ip %> |
    Then the step should succeed
    """
    When I run commands on the host:
      | docker pull docker.io/busybox && docker tag docker.io/busybox <%= cb.registry_ip %>/<%= project.name%>/busybox && docker push <%= cb.registry_ip %>/<%= project.name%>/busybox|
    Then the step should succeed
    And the "busybox:latest" image stream tag was created
    And evaluation of `image_stream_tag("busybox:latest").image_layers(user:user)` is stored in the :layers clipboard
    And all the image layers in the :layers clipboard do exist in the registry
