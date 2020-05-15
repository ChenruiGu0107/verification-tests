Feature: remote registry related scenarios
  # @author yinzhou@redhat.com
  # @case_id OCP-10865
  @admin
  Scenario: After Image Size Limit increment can push the image which previously over the limit
    Given I have a project
    And I obtain test data file "quota/image-limit-range.yaml"
    And I replace lines in "image-limit-range.yaml":
      | storage: 1Gi | storage: 65Mi |
    When I run the :create admin command with:
      | f | image-limit-range.yaml |
      | n | <%= project.name %>    |
    Then the step should succeed
    Given default registry service ip is stored in the :integrated_reg_ip clipboard
    And evaluation of `cb.integrated_reg_ip + "/" + project.name + "/mystream:2.0"` is stored in the :my_tag clipboard
    And I have a skopeo pod in the project
    When I execute on the pod:
      | skopeo                               |
      | --debug                              |
      | --insecure-policy                    |
      | copy                                 |
      | --dest-tls-verify=false              |
      | --dcreds                             |
      | any:<%= user.cached_tokens.first %>  |
      | docker://docker.io/centos:centos7    |
      | docker://<%= cb.my_tag %>            |
    Then the step should fail
    And the output should match:
      | uploading.*denied |
    Given I replace lines in "image-limit-range.yaml":
      | storage: 65Mi | storage: 1Gi |
    When I run the :replace admin command with:
      | f             | image-limit-range.yaml          |
      | n             | <%= project.name %>             |
    Then the step should succeed
    When I execute on the pod:
      | skopeo                               |
      | --debug                              |
      | --insecure-policy                    |
      | copy                                 |
      | --dest-tls-verify=false              |
      | --dcreds                             |
      | any:<%= user.cached_tokens.first %>  |
      | docker://docker.io/centos:centos7    |
      | docker://<%= cb.my_tag %>            |
    Then the step should succeed

  # @author yinzhou@redhat.com
  # @case_id OCP-10778
  @admin
  Scenario: No layers of the image will be stored in docker registy
    Given I have a project
    When I find a bearer token of the deployer service account
    When I run the :tag client command with:
      | source_type | docker                  |
      | source      | openshift/origin:latest |
      | dest        | mystream:latest         |
    Then the step should succeed
    And I select a random node's host
    Given default registry service ip is stored in the :integrated_reg_ip clipboard
    And the "~/.docker/config.json" file is restored on host after scenario
    When I run commands on the host:
      | podman login -u dnm -p <%= service_account.cached_tokens.first %> <%= cb.integrated_reg_ip %> |
    Then the step should succeed
    When I run commands on the host:
      | podman pull <%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:latest |
    Then the step should succeed
    Given I run commands on the host:
      | podman ps \|grep image-registry: \| awk '{ print $1}'|
    Then the step should succeed
    Given I run commands on the host:
      | podman exec  <%= @result[:response].strip() %> find /registry \| grep layer\| grep mystream |
    Then the step should fail
    And the output should not match:
      | mystream |

  # @author yinzhou@redhat.com
  # @case_id OCP-11314
  @admin
  Scenario: Support unauthenticated with registry-viewer role docker pull
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role      | registry-viewer     |
      | user name | system:anonymous    |
      | n         | <%= project.name %> |
    Then the step should succeed
    When I run the :import_image client command with:
      | image_name | ruby-25-centos7        |
      | from       | centos/ruby-25-centos7 |
      | confirm    | true                   |
    Then the step should succeed
    And I have a skopeo pod in the project
    Given I enable image-registry default route
    Given default image registry route is stored in the :integrated_reg_ip clipboard
    When I execute on the pod:
      | skopeo                                                                          |
      | --debug                                                                         |
      | --insecure-policy                                                               |
      | inspect                                                                         |
      | --tls-verify=false                                                              |
      | docker://<%= cb.integrated_reg_ip %>/<%= project.name %>/ruby-25-centos7:latest |
    Then the step should succeed
    When I execute on the pod:
      | skopeo                                                                   |
      | --debug                                                                  |
      | --insecure-policy                                                        |
      | copy                                                                     |
      | --dest-tls-verify=false                                                  |
      | docker://docker.io/busybox                                               |
      | docker://<%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:latest |
    Then the step should fail
    And the output should contain:
      | 401                           |
      | Error initiating layer upload |

  # @author yinzhou@redhat.com
  # @case_id OCP-12158
  @admin
  Scenario: Specify ResourceQuota on project
    Given I have a project
    When I obtain test data file "quota/openshift-object-counts.yaml"
    And I replace lines in "openshift-object-counts.yaml":
      | openshift.io/imagestreams: "10" | openshift.io/imagestreams: "1" |
    Then the step should succeed
    When I run the :create admin command with:
      | f | openshift-object-counts.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :tag client command with:
      | source_type  | docker                           |
      | source       | docker.io/library/busybox:latest |
      | dest         | mystream:latest                  |
    Then the step should succeed
    When I run the :tag client command with:
      | source_type  | docker                     |
      | source       | openshift/hello-openshift  |
      | dest         | mystream2:latest           |
    Then the step should fail
    And the output should match:
      | forbidden: [Ee]xceeded quota |

    Given default registry service ip is stored in the :integrated_reg_ip clipboard
    And evaluation of `cb.integrated_reg_ip + "/" + project.name + "/mystream3"` is stored in the :mystream3 clipboard
    And I have a skopeo pod in the project
    When I execute on the pod:
      | skopeo                               |
      | --debug                              |
      | --insecure-policy                    |
      | copy                                 |
      | --dest-tls-verify=false              |
      | --dcreds                             |
      | any:<%= user.cached_tokens.first %>  |
      | docker://docker.io/busybox           |
      | docker://<%= cb.mystream3 %>:latest  |
    Then the step should fail
    And the output should match:
      | uploading.*denied |

  # @author geliu@redhat.com
  # @case_id OCP-15107
  @admin
  Scenario: Strip manifest stored in etcd with schema2 version image
    Given the master version >= "3.6"
    Given I have a project
    When I run the :import_image client command with:
      | image_name | ruby-22-centos7        |
      | from       | centos/ruby-22-centos7 |
      | confirm    | true                   |
    Then the step should succeed
    When I run the :new_build client command with:
      | app_repo     | https://github.com/sclorg/ruby-ex.git |
      | image_stream | ruby-22-centos7                          |
    Then the step should succeed
    And a pod becomes ready with labels:
      | openshift.io/build.name=ruby-ex-1 |
    Given the "ruby-ex-1" build completed
    Given the "ruby-ex" image stream becomes ready
    And evaluation of `image_stream("ruby-ex").latest_tag_status.imageref.name` is stored in the :image_id clipboard
    When I run the :get admin command with:
      | resource      | image              |
      | o             | yaml               |
      | resource_name | <%= cb.image_id %> |
    Then the step should succeed
    Then the output should not match:
      | .*dockerImageManifest:.* |
    Given I use the first master host
    Given I store the default registry scheme to the :registry_scheme clipboard
    Given default registry service ip is stored in the :integrated_reg_ip clipboard
    And I run commands on the host:
      | curl -u <%=user.name %>:<%= user.cached_tokens.first %> -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' <%=cb.registry_scheme%>://<%= cb.integrated_reg_ip %>/v2/<%= project.name %>/ruby-ex/manifests/latest --cert /etc/origin/master/admin.crt --cacert /etc/origin/master/ca.crt --key /etc/origin/master/admin.key |
    Then the step should succeed
    And the output should match:
      | .*layers[\s\S]*digest.* |
    And I run commands on the host:
      | curl -u <%=user.name %>:<%= user.cached_tokens.first %> -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' <%=cb.registry_scheme%>://<%= cb.integrated_reg_ip %>/v2/<%= project.name %>/ruby-ex/manifests/<%= cb.image_id %> --cert /etc/origin/master/admin.crt --cacert /etc/origin/master/ca.crt --key /etc/origin/master/admin.key |
    Then the step should succeed
    And the output should match:
      | .*layers[\s\S]*digest.* |

