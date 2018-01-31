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

  # @author haowang@redhat.com
  # @case_id OCP-10898
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
  # @case_id OCP-12400
  @admin
  @destructive
  Scenario: Prune images by command oadm_prune_images
    Given cluster role "system:image-pruner" is added to the "first" user
    And default registry service ip is stored in the :registry_ip clipboard
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role            | registry-admin   |
      | user name       | system:anonymous |
    Then the step should succeed
    And I select a random node's host
    And the "~/.docker/config.json" file is restored on host after scenario
    And I run commands on the host:
      | docker logout <%= cb.registry_ip %> |
      | docker pull docker.io/aosqe/singlelayer:latest |
      | docker tag docker.io/aosqe/singlelayer:latest  <%= cb.registry_ip %>/<%= project.name %>/mystream:latest|
      | docker push <%= cb.registry_ip %>/<%= project.name %>/mystream:latest|
    Then the step should succeed
    And the "mystream:latest" image stream tag was created
    And evaluation of `image_stream_tag("mystream:latest").image_layers(user:user)` is stored in the :layers clipboard
    And evaluation of `image_stream_tag("mystream:latest").digest(user:user)` is stored in the :digest clipboard
    And default docker-registry route is stored in the :registry_ip clipboard
    And I ensures "mystream" imagestream is deleted
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
    And the "~/.docker/config.json" file is restored on host after scenario
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
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/registry/config.yml"
    Then the step should succeed
    And I replace content in "config.yml":
      | mirrorpullthrough: true | mirrorpullthrough: false |
    Then the step should succeed
    And I run the :new_secret admin command with:
      | secret_name     | registryconfig |
      | credential_file | ./config.yml    |
      | namespace       | default         |
    Then the step should succeed
    And admin ensures "registryconfig" secrets is deleted from the "default" project after scenario
    And I run the :volume admin command with:
      | resource    | dc/docker-registry |
      | add         | true               |
      | name        | config             |
      | mount-path  | /config            |
      | type        | secret             |
      | secret-name | registryconfig    |
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
    And the "~/.docker/config.json" file is restored on host after scenario
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

  # @author haowang@redhat.com
  # @case_id OCP-11310
  @admin
  Scenario: Have size information for images pushed to internal registry
    Given I have a project
    When I find a bearer token of the builder service account
    And default registry service ip is stored in the :registry_ip clipboard
    And I select a random node's host
    And the "~/.docker/config.json" file is restored on host after scenario
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
  # @case_id OCP-11544
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
    Given evaluation of `@result[:parsed]["spec"]["template"]["spec"]["containers"][0]["image"]` is stored in the :imgid clipboard
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
      | ports     | 5001            |
      | namespace | default         |
      | images    | <%= cb.imgid %> |
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
  # @case_id OCP-11215
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
    Given evaluation of `@result[:parsed]["spec"]["template"]["spec"]["containers"][0]["image"]` is stored in the :imgid clipboard
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
      | mount_host     | /tmp            |
      | serviceaccount | registry        |
      | namespace      | default         |
      | images         | <%= cb.imgid %> |
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

  # @author mcurlej@redhat.com
  # @case_id OCP-10788
  Scenario: Can import private image from docker hub and another openshift embed docker registry
    Given I have a project
    When I run the :new_secret client command with:
      | secret_name     | docker-secret                                                        |
      | credential_file | <%= expand_private_path(conf[:services, :docker_hub, :dockercfg]) %> |
    Then the step should succeed
    When I run the :new_app client command with:
      | docker_image | qeopenshift/ruby-22-centos7:latest |
    Then the step should succeed
    And the "ruby-22-centos7" image stream was created
    When I run the :tag client command with:
      | source_type | docker                             |
      | source      | qeopenshift/ruby-22-centos7:latest |
      | dest        | ruby-22-centos7-1:latest           |
    Then the step should succeed
    And the "ruby-22-centos7-1" image stream was created
    When I run the :get client command with:
      | resource      | is              |
      | resource_name | ruby-22-centos7 |
      | o             | json            |
    And I save the output to file> is.json
    Then I run oc create over "is.json" replacing paths:
      | ["metadata"]["name"] | ruby-22-centos7-2 |
    Then the step should succeed
    And the "ruby-22-centos7-2" image stream was created

  # @author: yinzhou@redhat.com
  # @case_id: OCP-12059
  @destructive
  @admin
  Scenario: Pull image with secrets from private remote registry in the OpenShift registry
    Given I have a project
    And I select a random node's host
    And I have a registry with htpasswd authentication enabled in my project
    And I add the insecure registry to docker config on the node
    And a pod becomes ready with labels:
      | deploymentconfig=registry |
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I log into auth registry on the node
    Then the step should succeed
    """
    When I docker push on the node to the registry the following images:
      | docker.io/busybox:latest | busybox:latest |
    Then the step should succeed
    When I run the :oc_secrets_new_dockercfg client command with:
      |secret_name      |test                     |
      |docker_email     |serviceaccount@redhat.com|
      |docker_password  |<%= cb.reg_pass %>       |
      |docker_server    |<%= cb.reg_svc_url %>    |
      |docker_username  |<%= cb.reg_user %>       |
    Then the step should succeed
    When I run the :tag client command with:
      | source_type  | docker                        |
      | source       | <%= cb.reg_svc_url %>/busybox |
      | dest         | mystream:latest               |
      | insecure     | true                          |
    Then the step should succeed
    Given evaluation of `image_stream_tag("mystream:latest").digest(user:user)` is stored in the :digest clipboard
    When I run the :policy_add_role_to_user client command with:
      | role            | registry-viewer   |
      | user name       | system:anonymous  |
    Then the step should succeed
    Given default registry service ip is stored in the :integrated_reg_ip clipboard
    When I run commands on the host:
      | docker logout <%= cb.integrated_reg_ip %> |
      | docker pull <%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:latest |
    Then the step should succeed

  # @author mcurlej@redhat.com
  # @case_id: OCP-10849
  @admin
  @destructive
  Scenario: Create the integrated registry as a daemonset by oadm command
    Given default registry is verified using a pod in a project after scenario
    Given I switch to cluster admin pseudo user
    And default docker-registry replica count is restored after scenario
    When I run the :get admin command with:
       | resource      | dc              |
       | resource_name | docker-registry |
       | namespace     | default         |
       | o             | yaml            |
    And I save the output to file>dc.yaml
    Given evaluation of `@result[:parsed]["spec"]["template"]["spec"]["containers"][0]["image"]` is stored in the :imgid clipboard
    #When default registry is verified using a pod in a project after scenario
    #Then the master service is restarted on all master nodes after scenario
    And default docker-registry dc is deleted
    And default docker-registry service is deleted
    And admin ensures "docker-registry" daemonset is deleted from the "default" project after scenario
    Then the master service is restarted on all master nodes after scenario
    When I run the :oadm_registry admin command with:
      | namespace | default         |
      | daemonset | true            |
      | images    | <%= cb.imgid %> |
    And <%= daemon_set("docker-registry").desired_number_scheduled(user: admin) %> pods become ready with labels:
      | docker-registry=default |
    Then the step should succeed
    When I secure the default docker daemon set registry
    Then the master service is restarted on all master nodes
    And default registry is verified using a pod in a project


  # @author: yinzhou@redhat.com
  # @case_id: OCP-10987
  @destructive
  @admin
  Scenario: openshift should support image path which have more than two slashes
    Given I have a project
    And I select a random node's host
    And I have a registry with htpasswd authentication enabled in my project
    And I add the insecure registry to docker config on the node
    And I log into auth registry on the node
    When I docker push on the node to the registry the following images:
      | docker.io/openshift/deployment-example:latest | test/test/deployment-example:latest |
      | docker.io/openshift/ruby-22-centos7:latest    | test/test/ruby-22-centos7:latest    |
    Then the step should succeed
    When I run the :oc_secrets_new_dockercfg client command with:
      |secret_name      |test                     |
      |docker_email     |serviceaccount@redhat.com|
      |docker_password  |<%= cb.reg_pass %>       |
      |docker_server    |<%= cb.reg_svc_url %>    |
      |docker_username  |<%= cb.reg_user %>       |
    Then the step should succeed
    When I run the :secret_add client command with:
      | sa_name     | default |
      | secret_name | test    |
      | for         | pull    |
    Then the step should succeed
    When I run the :secret_add client command with:
      | sa_name     | builder |
      | secret_name | test    |
    Then the step should succeed
    When I run the :tag client command with:
      | source_type  | docker                                                 |
      | source       | <%= cb.reg_svc_url %>/test/test/ruby-22-centos7:latest |
      | dest         | ruby-22-centos7:latest                                 |
      | insecure     | true                                                   |
    Then the step should succeed
    When I run the :new_build client command with:
      | code         | https://github.com/openshift/ruby-ex.git |
      | image_stream | ruby-22-centos7:latest                   |
    Then the step should succeed
    And the "ruby-ex-1" build completed
    When I run the :run client command with:
      | name  | testdc                                                    |
      | image | <%= cb.reg_svc_url %>/test/test/deployment-example:latest |
    Then the step should succeed
    And I wait until the status of deployment "testdc" becomes :complete

  # @author: yinzhou@redhat.com
  # @case_id: OCP-10922
  @destructive
  @admin
  Scenario: Admin can understand/manage image use and prune oversized image
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role            | registry-admin   |
      | user name       | system:anonymous |
    Then the step should succeed
    And I select a random node's host
    Given default registry service ip is stored in the :integrated_reg_ip clipboard
    And default docker-registry route is stored in the :registry_ip clipboard
    And the "~/.docker/config.json" file is restored on host after scenario
    When I run commands on the host:
      | docker logout <%= cb.integrated_reg_ip %>                                          |
      | docker pull aosqe/singlelayer:latest                                               |
      | docker tag docker.io/aosqe/singlelayer:latest  <%= cb.integrated_reg_ip %>/<%= project.name %>/singlelayer:latest             |
      | docker push <%= cb.integrated_reg_ip %>/<%= project.name %>/singlelayer:latest     |
      | docker pull openshift/hello-openshift:latest                                       |
      | docker tag docker.io/openshift/hello-openshift:latest  <%= cb.integrated_reg_ip %>/<%= project.name %>/hello-openshift:latest |
      | docker push <%= cb.integrated_reg_ip %>/<%= project.name %>/hello-openshift:latest |
    Then the step should succeed
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/image-limit-range.yaml"
    Then the step should succeed
    And I replace lines in "image-limit-range.yaml":
      | storage: 1Gi | storage: 140Mi |
    When I run the :create admin command with:
      | f | image-limit-range.yaml |
      | n | <%= project.name %>    |
    Then the step should succeed
    Given cluster role "system:image-pruner" is added to the "first" user
    And I run the :oadm_prune_images client command with:
      | prune_over_size_limit | true                  |
      | confirm               | true                  |
      | registry_url          | <%= cb.registry_ip %> |
      | namespace             | <%= project.name %>   |
    Then the step should succeed
    And the output should contain:
      | singlelayer |
    And the output should not contain:
      | hello-openshift |

  # @author yinzhou@redhat.com
  # @case_id OCP-12008
  @admin
  @destructive
  Scenario: When mirror fails should not affect the pullthrough operation
    Given default docker-registry deployment config is restored after scenario
    Given I switch to cluster admin pseudo user
    Given SCC "privileged" is added to the "registry" service account
    And I run the :volume admin command with:
      | resource    | dc/docker-registry |
      | add         | true               |
      | name        | registry-storage   |
      | mount-path  | /registry          |
      | type        | hostPath           |
      | path        | /home/test         |
      | overwrite   |                    |
      | namespace   | default            |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deploymentconfig=docker-registry |
    Given I switch to the first user
    And I have a project
    When I run the :tag client command with:
      | source_type | docker                  |
      | source      | openshift/origin:latest |
      | dest        | mystream:latest         |
    Then the step should succeed
    When I find a bearer token of the builder service account
    And default registry service ip is stored in the :registry_ip clipboard
    And I select a random node's host
    And I register clean-up steps:
    """
    And I run commands on the host:
      | docker rmi <%= cb.registry_ip %>/<%= project.name %>/mystream:latest |
    Then the step should succeed
    """
    And the "~/.docker/config.json" file is restored on host after scenario
    Then I wait up to 60 seconds for the steps to pass:
    """
    When I run commands on the host:
      | docker login -u dnm -p <%= service_account.get_bearer_token.token %> -e dnm@redmail.com <%= cb.registry_ip %> |
    Then the step should succeed
    """
    When I run commands on the host:
      | docker pull <%= cb.registry_ip %>/<%= project.name%>/mystream:latest |
    Then the step should succeed
    And evaluation of `image_stream_tag("mystream:latest").image_layers(user:user)` is stored in the :layers clipboard
    And all the image layers in the :layers clipboard do not exist in the registry

