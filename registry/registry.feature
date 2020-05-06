Feature: Testing registry
  # @author haowang@redhat.com
  # @case_id OCP-11038
  @admin
  @destructive
  Scenario: Disable the mirroring function for registry
    Given default docker-registry deployment config is restored after scenario
    And I change the internal registry pod to use a new emptyDir volume
    When I run the :set_env admin command with:
      | resource  | dc/docker-registry                                      |
      | e         | REGISTRY_OPENSHIFT_MIDDLEWARE_MIRRORPULLTHROUGH=false   |
      | namespace | default                                                 |
    Then the step should succeed
    And I wait until the latest rc of internal registry is ready

    Given I create a new project
    And evaluation of `project.name` is stored in the :prj1 clipboard
    And I find a bearer token of the deployer service account
    And default registry service ip is stored in the :registry_ip clipboard
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

    Given I have a skopeo pod in the project
    And master CA is added to the "skopeo" dc
    When I execute on the pod:
      | skopeo                     |
      | --debug                    |
      | --insecure-policy          |
      | inspect                    |
      | --cert-dir                 |
      | /opt/qe/ca                 |
      | --creds                    |
      | dnm:<%= service_account.cached_tokens.first %> |
      | docker://<%= cb.registry_ip %>/<%= project.name %>/hello-world:latest |
    Then the step should succeed
    When I execute on the pod:
      | skopeo                     |
      | --debug                    |
      | --insecure-policy          |
      | inspect                    |
      | --cert-dir                 |
      | /opt/qe/ca                 |
      | --creds                    |
      | dnm:<%= service_account.cached_tokens.first %> |
      | docker://<%= cb.registry_ip %>/<%= project.name %>/ruby-20-centos7:latest |
    Then the step should succeed
    And evaluation of `image_stream_tag("hello-world:latest").image_layers(user:user)` is stored in the :layers clipboard
    And all the image layers in the :layers clipboard do not exist in the registry
    And evaluation of `image_stream_tag("ruby-20-centos7:latest").image_layers(user:user)` is stored in the :layers clipboard
    And all the image layers in the :layers clipboard do not exist in the registry
    When I obtain test data file "registry/config.yml"
    Then the step should succeed
    And I replace content in "config.yml":
      | mirrorpullthrough: true | mirrorpullthrough: false |
    Then the step should succeed
    And I run the :new_secret admin command with:
      | secret_name     | registryconfig |
      | credential_file | ./config.yml   |
      | namespace       | default        |
    Then the step should succeed
    And admin ensures "registryconfig" secrets is deleted from the "default" project after scenario
    And I run the :set_volume admin command with:
      | resource    | dc/docker-registry |
      | add         | true               |
      | name        | config             |
      | mount-path  | /config            |
      | type        | secret             |
      | secret-name | registryconfig     |
      | namespace   | default            |
    Then the step should succeed
    Given I wait until the latest rc of internal registry is ready
    When I run the :set_env admin command with:
      | resource  | dc/docker-registry                               |
      | env_name  | REGISTRY_OPENSHIFT_MIDDLEWARE_MIRRORPULLTHROUGH- |
      | env_name  | REGISTRY_CONFIGURATION_PATH=/config/config.yml   |
      | namespace | default                                          |
    Then the step should succeed
    Given I wait until the latest rc of internal registry is ready
    And I create a new project
    And evaluation of `project.name` is stored in the :prj2 clipboard
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
    Given I find a bearer token of the deployer service account
    And I use the "<%= cb.prj1 %>" project
    When I execute on the "<%= cb.skopeo_dc.rc.pods.first.name %>" pod:
      | skopeo                     |
      | --debug                    |
      | --insecure-policy          |
      | inspect                    |
      | --cert-dir                 |
      | /opt/qe/ca                 |
      | --creds                    |
      | dnm:<%= service_account.cached_tokens.first %> |
      | docker://<%= cb.registry_ip %>/<%= cb.prj2 %>/hello-world:latest |
    Then the step should succeed
    When I execute on the pod:
      | skopeo                     |
      | --debug                    |
      | --insecure-policy          |
      | inspect                    |
      | --cert-dir                 |
      | /opt/qe/ca                 |
      | --creds                    |
      | dnm:<%= service_account.cached_tokens.first %> |
      | docker://<%= cb.registry_ip %>/<%= cb.prj2 %>/ruby-20-centos7:latest |
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
    Given I store the schedulable nodes in the :nodes clipboard
    Given I use the "<%= cb.nodes[0].name %>" node
    And the "~/.docker/config.json" file is restored on host after scenario
    When I run commands on the host:
      | docker rmi docker.io/busybox:latest |
    When I run commands on the host:
      | docker login -u dnm -p <%= service_account.cached_tokens.first %> -e dnm@redmail.com <%= cb.registry_ip %> |
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

  # @author mcurlej@redhat.com
  # @case_id OCP-10788
  Scenario: Can import private image from docker hub and another openshift embed docker registry
    Given I have a project
    And I run the :create_secret client command with:
      | secret_type | generic                                                                         |
      | name        | docker-secret                                                                   |
      | from_file   | .dockercfg=<%= expand_private_path(conf[:services, :docker_hub, :dockercfg]) %> |
      | type        | kubernetes.io/dockercfg                                                         |
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

  # @author yinzhou@redhat.com
  # @case_id OCP-12059
  @admin
  Scenario: Pull image with secrets from private remote registry in the OpenShift registry
    Given I have a project
    Given I have a registry with htpasswd authentication enabled in my project
    And I have a skopeo pod in the project
    And master CA is added to the "skopeo" dc
    When I execute on the pod:
      | skopeo                     |
      | --debug                    |
      | --insecure-policy          |
      | copy                       |
      | --dest-tls-verify=false    |
      | --dcreds                   |
      | <%= cb.reg_user %>:<%= cb.reg_pass %>  |
      | docker://docker.io/busybox             |
      | docker://<%= cb.reg_svc_url %>/busybox:latest  |
    Then the step should succeed
    When I run the :create_secret client command with:
      | secret_type        | docker-registry           |
      | name               | test                      |
      | docker_email       | serviceaccount@redhat.com |
      | docker_password    | <%= cb.reg_pass %>        |
      | docker_server      | <%= cb.reg_svc_url %>     |
      | docker_username    | <%= cb.reg_user %>        |
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
    Given I enable image-registry default route
    Given default image registry route is stored in the :integrated_reg_ip clipboard
    When I execute on the pod:
      | skopeo                     |
      | --debug                    |
      | --insecure-policy          |
      | inspect                    |
      | --cert-dir                 |
      | /opt/qe/ca                 |
      | docker://<%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:latest |
    Then the step should succeed

  # @author yinzhou@redhat.com
  # @case_id OCP-12008
  @admin
  @destructive
  Scenario: When mirror fails should not affect the pullthrough operation
    Given default docker-registry deployment config is restored after scenario
    Given I switch to cluster admin pseudo user
    Given SCC "privileged" is added to the "registry" service account
    And I run the :set_volume admin command with:
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
    Given I find a bearer token of the builder service account
    And default registry service ip is stored in the :registry_ip clipboard
    And I have a skopeo pod in the project
    And master CA is added to the "skopeo" dc
    When I execute on the pod:
      | skopeo                     |
      | --debug                    |
      | --insecure-policy          |
      | inspect                    |
      | --cert-dir                 |
      | /opt/qe/ca                 |
      | --creds                    |
      | dnm:<%= service_account.cached_tokens.first %>  |
      | docker://<%= cb.registry_ip %>/<%= project.name%>/mystream:latest |
    Then the step should succeed
    And evaluation of `image_stream_tag("mystream:latest").image_layers(user:user)` is stored in the :layers clipboard
    And all the image layers in the :layers clipboard do not exist in the registry

  # @author wzheng@redhat.com
  # @case_id OCP-17167
  @admin
  Scenario: Image soft prune via 'prune-registry' option with invalid argument
    When I run the :oadm_prune_images admin command with:
      | keep_tag_revisions | abc |
    Then the output should contain:
      | invalid argument "abc" |
    When I run the :oadm_prune_images admin command with:
      | confirm | abc |
    Then the output should contain:
      | invalid argument "abc" |
    When I run the :oadm_prune_images admin command with:
      | keep_younger_than | abc |
    Then the output should contain:
      | invalid argument "abc" |
    When I run the :oadm_prune_images admin command with:
      | prune_over_size_limit | abc |
    Then the output should contain:
      | invalid argument "abc" |
    When I run the :oadm_prune_images admin command with:
      | prune_registry | abc |
    Then the output should contain:
      | invalid argument "abc" |

  # @author xiuwang@redhat.com
  # @case_id OCP-19633
  Scenario: Should create a status tag after editing an image stream tag to set 'reference: true' from an invalid tag
    Given I have a project
    When I run the :import_image client command with:
      | from       | registry.access.redhat.com/openshift3/jenkins-2-rhel7:invalid |
      | image_name | jenkins:invalid                                               |
      | confirm    | true                                                          |
    Then the step should succeed
    And the output should match:
      | Import failed.*File not found |
    When I run the :patch client command with:
      | resource      | imagestream                                               |
      | resource_name | jenkins                                                   |
      | p             | {"spec":{"tags":[{"name": "invalid","reference": true}]}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | imagestream |
      | name     | jenkins     |
    And the output should contain:
      | reference to registry |
    And the output should not contain:
      | Import failed |

  # @author wzheng@redhat.com
  # @case_id OCP-18559
  @admin
  @destructive
  Scenario: Use SAR request to access registry metrics
    Given I have a project
    Given I switch to cluster admin pseudo user
    Given I enable image-registry default route
    Given default image registry route is stored in the :integrated_reg_host clipboard
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/registry/ocp-18559/prometheus-role.yaml |
    Then the step should succeed
    And admin ensures "prometheus-scraper" clusterroles is deleted after scenario
    And I switch to the first user
    Given I have a pod-for-ping in the project
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | curl -v -s -u openshift:<%= user.cached_tokens.first %> https://<%= cb.integrated_reg_host %>/extensions/v2/metrics -k |
    Then the output should contain:
      | UNAUTHORIZED |
    """
    Given cluster role "prometheus-scraper" is added to the "first" user
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | curl -v -s -u openshift:<%= user.cached_tokens.first %> https://<%= cb.integrated_reg_host %>/extensions/v2/metrics -k |
    Then the step should succeed
    """

  # @author xiuwang@redhat.com
  # @case_id OCP-22781
  @admin
  @destructive
  Scenario: Set toleration field for image registry pod
    Given I switch to cluster admin pseudo user
    When I use the "openshift-image-registry" project
    Given current generation number of "image-registry" deployment is stored into :before_change clipboard
    And all existing pods are ready with labels:
      | docker-registry=default |
    And I successfully merge patch resource "configs.imageregistry.operator.openshift.io/cluster" with:
      | {"spec":{"replicas": 1,"tolerations":[{"effect":"NoSchedule","key":"node-role.kubernetes.io/master","operator":"Exists"}]}} |
    And I register clean-up steps:
    """
    When I run the :delete client command with:
      | object_type       | configs.imageregistry.operator.openshift.io |
      | object_name_or_id | cluster                                     |
      | wait              | false                                       |
    Then the step should succeed
    """
    And I wait for the steps to pass:
    """
    Given current generation number of "image-registry" deployment is stored into :after_change clipboard
    And the expression should be true> cb.after_change - cb.before_change >=1
    """
    And I wait for the pod to die regardless of current status
    And a pod becomes ready with labels:
      | docker-registry=default |
    Then the expression should be true> node(pod.node_name).is_master?
    Given I successfully merge patch resource "configs.imageregistry.operator.openshift.io/cluster" with:
      | {"spec":{"tolerations":[{"effect":"NoSchedule","key":"node-role.kubernetes.io/master","operator":"Equal","value": "myvalue"}]}} |
    And I wait for the steps to pass:
    """
    Given current generation number of "image-registry" deployment is stored into :change_twice clipboard
    And the expression should be true> cb.change_twice - cb.after_change >=1
    """
    And I wait for the pod to die regardless of current status
    And a pod becomes ready with labels:
      | docker-registry=default |
    Then the expression should be true> node(pod.node_name).is_worker?

  # @author xiuwang@redhat.com
  # @case_id OCP-21482
  @admin
  Scenario: Set default externalRegistryHostname in image policy config globally
    Given I have a project
    Given docker config for default image registry is stored to the :dockercfg_file clipboard
    Then I run the :describe admin command with:
      | resource | image.config.openshift.io |
      | name     | cluster                   |
    And the output should match:
      | External Registry Hostnames |
      | Internal Registry Hostname  |
      | <%= cb.integrated_reg_ip %> |
    Then I run the :image_mirror client command with:
      | source_image | <%= cb.integrated_reg_ip %>/openshift/ruby:2.5                 |
      | dest_image   | <%= cb.integrated_reg_ip %>/<%= project.name %>/myimage:latest |
      | a            | <%= cb.dockercfg_file %>                                       |
      | insecure     | true                                                           |
    And the step should succeed
    And the output should match:
      | Mirroring completed in |
    Given the "myimage" image stream was created
    And the "myimage" image stream becomes ready

  # @author xiuwang@redhat.com
  # @case_id OCP-21510
  @admin
  @destructive
  Scenario: Set the white list of image registry via allowedRegistriesForImport
    Given I have a project
    Given evaluation of `project.name` is stored in the :saved_name clipboard
    Given I switch to cluster admin pseudo user
    When I use the "openshift-apiserver" project
    And evaluation of `daemon_set("apiserver").generation_number(user: user, cached: false)` is stored in the :before_change clipboard
    And evaluation of `daemon_set("apiserver").desired_replicas` is stored in the :desired_num clipboard
    And <%= cb.desired_num %> pods become ready with labels:
      | pod-template-generation=<%= cb.before_change %> |
    And I successfully merge patch resource "image.config.openshift.io/cluster" with:
      | {"spec":{"allowedRegistriesForImport":[{"domainName":"registry.redhat.io","insecure":false},{"domainName":"registry.access.redhat.com","insecure":false}]}} |
    And I register clean-up steps:
    """
    And I successfully merge patch resource "image.config.openshift.io/cluster" with:
      | {"spec":{"allowedRegistriesForImport":[]}} |
    """
    And I wait for the steps to pass:
    """
    And evaluation of `daemon_set("apiserver").generation_number(user: user, cached: false)` is stored in the :after_change clipboard
    And the expression should be true> cb.after_change - cb.before_change >=1
    """
    And <%= cb.desired_num %> pods become ready with labels:
      | pod-template-generation=<%= cb.after_change %> |
    And I run the :tag client command with:
      | source | docker.io/centos/ruby-25-centos7:latest |
      | dest   | myimage:v1                              |
      | n      | <%= cb.saved_name %>                    |
    Then the step should fail
    And the output should contain:
      | Forbidden: registry "docker.io" not allowed by whitelist |
      | registry.redhat.io:443                                   |
      | registry.access.redhat.com:443                           |
    And I run the :tag client command with:
      | source | registry.redhat.io/rhscl/ruby-25-rhel7:latest |
      | dest   | myimage1:v1                                   |
      | n      | <%= cb.saved_name %>                          |
    Then the step should succeed
    And I run the :tag client command with:
      | source | registry.access.redhat.com/rhscl/ruby-25-rhel7:latest |
      | dest   | myimage2:v1                                           |
      | n      | <%= cb.saved_name %>                                  |
    Then the step should succeed
    And I successfully merge patch resource "image.config.openshift.io/cluster" with:
      | {"spec":{"allowedRegistriesForImport":[{"domainName":"registry.redhat.io","insecure":false},{"domainName":"registry.access.redhat.com","insecure":true}]}} |
    And I wait for the steps to pass:
    """
    And evaluation of `daemon_set("apiserver").generation_number(user: user, cached: false)` is stored in the :third_change clipboard
    And the expression should be true> cb.third_change - cb.after_change >=1
    """
    And <%= cb.desired_num %> pods become ready with labels:
      | pod-template-generation=<%= cb.third_change %> |
    And I run the :tag client command with:
      | source | registry.access.redhat.com/rhscl/ruby-25-rhel7:latest |
      | dest   | myimage4:v1                                           |
      | n      | <%= cb.saved_name %>                                  |
    Then the step should fail
    And the output should contain:
      | registry.access.redhat.com:80 |
