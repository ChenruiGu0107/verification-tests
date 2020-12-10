Feature: Testing registry
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
      | docker://quay.io/openshifttest/busybox             |
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
      | Import failed |
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
    Given I obtain test data file "registry/ocp-18559/prometheus-role.yaml"
    When I run the :create admin command with:
      | f | prometheus-role.yaml |
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
    Then I store in the :podas clipboard the pods labeled:
      | docker-registry=default |
    And I successfully merge patch resource "configs.imageregistry.operator.openshift.io/cluster" with:
      | {"spec":{"tolerations":[{"effect":"NoSchedule","key":"node-role.kubernetes.io/master","operator":"Exists"}]}} |
    And I register clean-up steps:
    """
    And I successfully merge patch resource "configs.imageregistry.operator.openshift.io/cluster" with:
      | {"spec":{"tolerations":null}} |
    """
    And I wait for the steps to pass:
    """
    Given current generation number of "image-registry" deployment is stored into :after_change clipboard
    And the expression should be true> cb.after_change - cb.before_change >=1
    """
    And I repeat the following steps for each :poda in cb.podas:
    """
    And I wait for the pod named "#{cb.poda.name}" to die regardless of current status
    """
    And "image-registry" deployment becomes ready in the "openshift-image-registry" project
    Then I store in the :podbs clipboard the pods labeled:
      | docker-registry=default |
    Given I successfully merge patch resource "configs.imageregistry.operator.openshift.io/cluster" with:
      | {"spec":{"tolerations":[{"effect":"NoSchedule","key":"node-role.kubernetes.io/master","operator":"Equal","value": "myvalue"}]}} |
    And I wait for the steps to pass:
    """
    Given current generation number of "image-registry" deployment is stored into :change_twice clipboard
    And the expression should be true> cb.change_twice - cb.after_change >=1
    """
    And I repeat the following steps for each :podb in cb.podbs:
    """
    And I wait for the pod named "#{cb.podb.name}" to die regardless of current status
    """
    And "image-registry" deployment becomes ready in the "openshift-image-registry" project
    Then I store in the :podcs clipboard the pods labeled:
      | docker-registry=default |
    And I repeat the following steps for each :podc in cb.podcs:
    """
    Then the expression should be true> node(cb.podc.node_name).is_worker?
    """

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
  @admin
  @destructive
  Scenario Outline: Set the white list of image registry via allowedRegistriesForImport
    Given I have a project
    Given evaluation of `project.name` is stored in the :saved_name clipboard
    Given I switch to cluster admin pseudo user
    When I use the "openshift-apiserver" project
    And evaluation of `<resource_set>("apiserver").generation_number(cached: false)` is stored in the :before_change clipboard
    And "apiserver" <resource> becomes ready in the "openshift-apiserver" project
    And I successfully merge patch resource "image.config.openshift.io/cluster" with:
      | {"spec":{"allowedRegistriesForImport":[{"domainName":"registry.redhat.io","insecure":false},{"domainName":"registry.access.redhat.com","insecure":false}]}} |
    And I register clean-up steps:
    """
    And I successfully merge patch resource "image.config.openshift.io/cluster" with:
      | {"spec":{"allowedRegistriesForImport":[]}} |
    """
    And I wait for the steps to pass:
    """
    And evaluation of `<resource_set>("apiserver").generation_number(cached: false)` is stored in the :after_change clipboard
    And the expression should be true> cb.after_change - cb.before_change >=1
    """
    And "apiserver" <resource> becomes ready in the "openshift-apiserver" project
    And I wait for the steps to pass:
    """
    And I run the :tag client command with:
      | source | quay.io/openshifttest/ruby-25-centos7@sha256:575194aa8be12ea066fc3f4aa9103dcb4291d43f9ee32e4afe34e0063051610b |
      | dest   | myimage:v1                                                                                                    |
      | n      | <%= cb.saved_name %>                                                                                          |
    Then the step should fail
    """
    And the output should contain:
      | Forbidden: registry "quay.io" not allowed by whitelist |
      | registry.redhat.io:443                                 |
      | registry.access.redhat.com:443                         |
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
    And evaluation of `<resource_set>("apiserver").generation_number(cached: false)` is stored in the :third_change clipboard
    And the expression should be true> cb.third_change - cb.after_change >=1
    """
    And "apiserver" <resource> becomes ready in the "openshift-apiserver" project
    And I wait for the steps to pass:
    """
    And I run the :tag client command with:
      | source | registry.access.redhat.com/rhscl/ruby-25-rhel7:latest |
      | dest   | myimage4:v1                                           |
      | n      | <%= cb.saved_name %>                                  |
    Then the step should fail
    """
    And the output should contain:
      | registry.access.redhat.com:80 |
    Examples:
      | resource_set | resource   |
      | daemon_set   | daemonset  | # @case_id OCP-21510
      | deployment   | deployment | # @case_id OCP-29435

  # @author wzheng@redhat.com
  # @case_id OCP-21988
  @admin
  Scenario: Registry can use AdditionalTrustedCA to trust an external secured registry 
    Given I switch to cluster admin pseudo user
    When I run the :get client command with:
      | resource  | configmap        |
      | namespace | openshift-config |
    Then the step should succeed
    Then the output should contain:
      | registry-config |
    Then I run the :describe admin command with:
      | resource | image.config.openshift.io |
      | name     | cluster                   |
    Then the step should succeed
    And the output should contain:
      | Additional Trusted CA |
      | registry-config       |
    When I run the :import_image client command with:
      | image_name | ruby:latest |
      | namespace  | openshift   |
    Then the step should succeed

  # @author wzheng@redhat.com
  # @case_id OCP-31767
  @admin
  @destructive
  Scenario: Warning appears when registry use invalid AdditionalTrustedCA	
    Given I switch to cluster admin pseudo user
    And I successfully merge patch resource "image.config.openshift.io/cluster" with:
     | {"spec": {"additionalTrustedCA": {"name": "registry-config-invalid"}}} |
    And I register clean-up steps:
    """
    And I successfully merge patch resource "image.config.openshift.io/cluster" with:
      | {"spec": {"additionalTrustedCA": {"name": "registry-config"}}} |
    """
    When I run the :logs admin command with:
      | resource_name | deployments/cluster-image-registry-operator |
      | c             | cluster-image-registry-operator             |
      | namespace     | openshift-image-registry                    |
    And the output should contain:
      | configmap "registry-config-invalid" not found |
      
