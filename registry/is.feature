Feature: Testing imagestream

  # @author haowang@redhat.com
  # @case_id OCP-11035
  Scenario: oc import-image should pull "highest" tags
    Given I have a project
    When I run the :import_image client command with:
      | image_name | busybox                           |
      | from       | docker.io/aosqe/busybox-multytags |
      | all        | true                              |
      | confirm    | true                              |
    Then the step should succeed
    And the "busybox" image stream was created
    And the expression should be true> image_stream('busybox').tags(user: user).length == 5
    And the "busybox:latest" image stream tag was created
    And the "busybox:v1.3-2" image stream tag was created
    And the "busybox:v1.3-3" image stream tag was created
    And the "busybox:v1.3-4" image stream tag was created
    And the "busybox:v1.2-5" image stream tag was created


  # @author yinzhou@redhat.com
  # @case_id OCP-13893
  @destructive
  @admin
  Scenario: Shouldn't prune the image with week and strong reference witch the strong reference is imagestream
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role            | registry-admin   |
      | user name       | system:anonymous |
    Then the step should succeed
    Given default registry service ip is stored in the :registry_hostname clipboard
    And I have a skopeo pod in the project
    And master CA is added to the "skopeo" dc
    When I execute on the pod:
      | skopeo                     |
      | --debug                    |
      | --insecure-policy          |
      | copy                       |
      | --dest-cert-dir            |
      | /opt/qe/ca                 |
      | docker://docker.io/busybox:latest |
      | docker://<%= cb.registry_hostname %>/<%= project.name %>/mystream:latest |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | istag                    |
      | resource_name | mystream:latest          |
      | template      | {{.image.metadata.name}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :digest1 clipboard
    When I run the :tag client command with:
      | source_type  | docker                                                          |
      | source       | <%= cb.registry_hostname %>/<%= project.name %>/mystream:latest |
      | dest         | <%= project.name %>/myisb:latest                                |
      | insecure     | true                                                            |
    Then the step should succeed
    When I execute on the pod:
      | skopeo                     |
      | --debug                    |
      | --insecure-policy          |
      | copy                       |
      | --dest-cert-dir            |
      | /opt/qe/ca                 |
      | docker://docker.io/openshift/hello-openshift:latest |
      | docker://<%= cb.registry_hostname %>/<%= project.name %>/mystream:latest |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | istag                    |
      | resource_name | mystream:latest          |
      | template      | {{.image.metadata.name}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :digest2 clipboard
    When I execute on the pod:
      | skopeo                     |
      | --debug                    |
      | --insecure-policy          |
      | copy                       |
      | --dest-cert-dir            |
      | /opt/qe/ca                 |
      | docker://docker.io/openshift/deployment-example:latest |
      | docker://<%= cb.registry_hostname %>/<%= project.name %>/mystream:latest |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | istag                    |
      | resource_name | mystream:latest          |
      | template      | {{.image.metadata.name}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :digest3 clipboard
    Given cluster role "system:image-pruner" is added to the "first" user
    And I run the :oadm_prune_images client command with:
      | keep_tag_revisions | 1                           |
      | keep_younger_than  | 0                           |
      | registry_url       | <%= cb.registry_hostname %> |
      | confirm            | true                        |
    Then the step should succeed
    And the output should not contain:
      | <%= cb.digest1 %> |
      | <%= cb.digest3 %> |
    And the output should contain:
      | <%= cb.digest2 %> |


  # @author yinzhou@redhat.com
  # @case_id OCP-13878
  @destructive
  @admin
  Scenario: Shouldn't prune the image with week and strong reference which the strong reference is imagestreamtag
    Given default registry service ip is stored in the :integrated_reg_ip clipboard
    Given default registry service ip is stored in the :registry_hostname clipboard
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | centos/ruby-22-centos7~https://github.com/sclorg/ruby-ex.git |
    Then the step should succeed
    And the "ruby-ex-1" build was created
    Then the "ruby-ex-1" build completes
    When I run the :get client command with:
      | resource      | istag                    |
      | resource_name | ruby-ex:latest           |
      | template      | {{.image.metadata.name}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :digest1 clipboard
    When I run the :tag client command with:
      | source_type  | docker                                                         |
      | source       | <%= cb.integrated_reg_ip %>/<%= project.name %>/ruby-ex:latest |
      | dest         | <%= project.name %>/ruby-ex:20                                 |
      | insecure     | true                                                           |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    And the "ruby-ex-2" build was created
    Then the "ruby-ex-2" build completes
    When I run the :get client command with:
      | resource      | istag                    |
      | resource_name | ruby-ex:latest           |
      | template      | {{.image.metadata.name}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :digest2 clipboard
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    And the "ruby-ex-3" build was created
    Then the "ruby-ex-3" build completes
    When I run the :get client command with:
      | resource      | istag                    |
      | resource_name | ruby-ex:latest           |
      | template      | {{.image.metadata.name}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :digest3 clipboard
    Then I run the :delete client command with:
      | object_type       | buildConfig |
      | object_name_or_id | ruby-ex     |
    Then the step should succeed
    Given cluster role "system:image-pruner" is added to the "first" user
    And I run the :oadm_prune_images client command with:
      | keep_tag_revisions | 1                           |
      | keep_younger_than  | 0                           |
      | registry_url       | <%= cb.registry_hostname %> |
      | confirm            | true                        |
    Then the step should succeed
    And the output should not contain:
      | <%= cb.digest1 %> |
      | <%= cb.digest3 %> |
    And the output should contain:
      | <%= cb.digest2 %> |

  # @author xiuwang@redhat.com
  # @case_id OCP-26732
  @destructive
  @admin
  Scenario: Increase the limit on the number of image signatures
    Given I have a project
    Given evaluation of `project.name` is stored in the :saved_name clipboard
    Given a 5 characters random string of type :dns is stored into the :sign_name clipboard
    Given I switch to cluster admin pseudo user
    When I use the "openshift-cluster-version" project
    When I run the :scale client command with:
      | resource | deployment               |
      | name     | cluster-version-operator |
      | replicas | 0                        |
    Then the step should succeed
    Given all existing pods die with labels:
      | k8s-app=cluster-version-operator |
    When I use the "openshift-controller-manager-operator" project
    When I run the :scale client command with:
      | resource | deployment                            |
      | name     | openshift-controller-manager-operator |
      | replicas | 0                                     |
    Then the step should succeed
    And I register clean-up steps:
    """
    When I run the :scale admin command with:
      | resource | deployment                            |
      | name     | openshift-controller-manager-operator |
      | replicas | 1                                     |
      | n        | openshift-controller-manager-operator |
    Then the step should succeed
    When I run the :scale admin command with:
      | resource | deployment                |
      | name     | cluster-version-operator  |
      | replicas | 1                         |
      | n        | openshift-cluster-version |
    Then the step should succeed
    """
    Given all existing pods die with labels:
      | app=openshift-controller-manager-operator |
    When I use the "openshift-controller-manager" project
    And evaluation of `daemon_set("controller-manager").generation_number(user: user, cached: false)` is stored in the :before_change clipboard
    And evaluation of `daemon_set("controller-manager").desired_replicas` is stored in the :desired_num clipboard
    And <%= cb.desired_num %> pods become ready with labels:
      | pod-template-generation=<%= cb.before_change %> |
    When I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/registry/registry.access.redhat.com.yaml"
    And I run the :create_configmap client command with:
      | name      | <%= cb.sign_name %>             | 
      | from_file | registry.access.redhat.com.yaml |
    Then the step should succeed
    When I run the :set_volume client command with:
      | resource       | ds/controller-manager         |
      | action         | --add                         |
      | type           | configmap                     |
      | mount-path     | /etc/containers/registries.d/ |
      | name           | <%= cb.sign_name %>           |
      | configmap-name | <%= cb.sign_name %>           |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    And evaluation of `daemon_set("controller-manager").generation_number(user: user, cached: false)` is stored in the :after_change clipboard
    And the expression should be true> cb.after_change - cb.before_change >=1
    """
    And <%= cb.desired_num %> pods become ready with labels:
      | pod-template-generation=<%= cb.after_change %> |
    Given I switch to the first user
    When I use the "<%= cb.saved_name %>" project
    When I run the :import_image client command with:
      | image_name | registry.access.redhat.com/openshift3/ose:latest |
      | confirm    | true                                             |
    Then the step should succeed
    When I get project imagestreamtag named "ose:latest" as YAML
    And evaluation of `@result[:parsed]['image']['signatures'].count` is stored in the :sign_count clipboard
    And the expression should be true> cb.sign_count > 3
