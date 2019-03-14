Feature: remote registry related scenarios

  # @author pruan@redhat.com
  # @case_id OCP-11556
  @admin
  @destructive
  Scenario: Pull image will failed when integrated registry with option:pullthrough=false
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/registry/tc518928/config.yaml"
    When I run the :secrets admin command with:
      | action | new         |
      | name   | tc518928    |
      | source | config.yaml |
      | n      | default     |
    Then the step should succeed
    And I register clean-up steps:
    """
    I run the :delete admin command with:
      | object_type       | secret   |
      | object_name_or_id | tc518928 |
      | n                 | default  |
    the step succeeded
    """

    Given I switch to cluster admin pseudo user
    And default docker-registry deployment config is restored after scenario
    And evaluation of `service("docker-registry", project("default")).url(user: admin)` is stored in the :integrated_reg_ip clipboard

    When I run the :set_volume admin command with:
      | resource    | dc/docker-registry |
      | action      | --add              |
      | name        | config-tc518928    |
      | mount-path  | /config            |
      | type        | secret             |
      | secret-name | tc518928           |
      | overwrite   | true               |
      | n           | default            |
    Then the step should succeed
    And I wait until replicationController "docker-registry-<%= cb.docker_registry_golden_version + 1 %>" is ready

    When I run the :set_env admin command with:
      | resource | dc/docker-registry                              |
      | e        | REGISTRY_CONFIGURATION_PATH=/config/config.yaml |
      | n        | default                                         |
    Then the step should succeed
    And I wait until replicationController "docker-registry-<%= cb.docker_registry_golden_version + 2 %>" is ready

    Given I switch to the default user
    And I have a project
    When I run the :tag client command with:
      | source_type | docker                               |
      | source      | aosqe/sleep:preserve-for-testing     |
      | dest        | mystream:latest                      |
    Then the step should succeed

    Given I find a bearer token of the deployer service account
    And I have a skopeo pod in the project
    When I execute on the pod:
      | skopeo                     |
      | --debug                    |
      | --insecure-policy          |
      | inspect                    |
      | --tls-verify=false         |
      | --creds                    |
      | dnm:<%= service_account.cached_tokens.first %>  |
      | docker://<%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:latest |
    Then the step should fail
    # TODO: this scenario should first verify pull is working, then change
    # registry config, remove image and chec again that pull not working
    # docker rmi docker.io/aosqe/sleep:latest
    # at the moment if something pulled image earlier, case would fail


  # @author pruan@redhat.com
  # @case_id OCP-11945
  @admin
  Scenario: Pull image with integrated registry have stored the data
    Given I have a project
    And default docker-registry route is stored in the :integrated_reg_ip clipboard
    # TODO: this PR should allow 'deployer' the permission to push https://github.com/openshift/origin/pull/9066
    # create a short hand
    And evaluation of `cb.integrated_reg_ip + "/" + project.name + "/tc518930-busybox:local"` is stored in the :my_tag clipboard
    And I have a skopeo pod in the project
    And master CA is added to the "skopeo" dc
    When I execute on the pod:
      | skopeo                               |
      | --debug                              |
      | --insecure-policy                    |
      | copy                                 |
      | --dest-cert-dir                      |
      | /opt/qe/ca                           |
      | --dcreds                             |
      | dnm:<%= user.cached_tokens.first %>  |
      | docker://docker.io/busybox           |
      | docker://<%= cb.my_tag %>            |
    Then the step should succeed
    When I execute on the pod:
      | skopeo                               |
      | --debug                              |
      | --insecure-policy                    |
      | inspect                              |
      | --cert-dir                           |
      | /opt/qe/ca                           |
      | --creds                              |
      | dnm:<%= user.cached_tokens.first %>  |
      | docker://<%= cb.my_tag %>            |
    Then the step should succeed

  # @author yinzhou@redhat.com
  # @case_id OCP-10591
  @admin
  Scenario: provisioned if it does not exist during 'docker push'
    Given I have a project
    When I run the :get client command with:
      | resource      | imagestream |
      | resource_name | mystream    |
      | o             | json        |
    Then the step should fail
    And I select a random node's host

    Given default docker-registry route is stored in the :integrated_reg_ip clipboard
    And the "~/.docker/config.json" file is restored on host after scenario
    When I run commands on the host:
      | docker login -u dnm -p <%= user.cached_tokens.first %> -e dnm@redmail.com <%= cb.integrated_reg_ip %> |
    Then the step should succeed
    When I run commands on the host:
      | docker pull docker.io/busybox:latest |
    Then the step should succeed
    And I run commands on the host:
      | docker tag  docker.io/busybox:latest  <%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:latest |
    Then the step should succeed
    When I run commands on the host:
      | docker push <%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:latest |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | imagestream |
      | resource_name | mystream    |
      | o             | json        |
    Then the step should succeed

  # @author yinzhou@redhat.com
  # @case_id OCP-10587
  @admin
  Scenario: ImageStream annotations can be set
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image-streams/annotations.json |
    Then the step should succeed
    Given default docker-registry route is stored in the :integrated_reg_ip clipboard
    And I have a skopeo pod in the project
    And master CA is added to the "skopeo" dc
    When I execute on the pod:
      | skopeo                                 |
      | --debug                                |
      | --insecure-policy                      |
      | copy                                   |
      | --dest-cert-dir                        |
      | /opt/qe/ca                             |
      | --dcreds                               |
      | dnm:<%= user.cached_tokens.first %>    |
      | docker://docker.io/busybox             |
      | docker://<%= cb.integrated_reg_ip %>/<%= project.name %>/testa:prod |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | imagestreamtag            |
      | resource_name | testa:prod                |
      | template      | {{.metadata.annotations}} |
      | n             | <%= project.name %>       |
    Then the output should match "color:blue"
    When I run the :get client command with:
      | resource      | imagestream         |
      | resource_name | testa               |
      | o             | yaml                |
      | n             | <%= project.name %> |
    And the output should match:
      |  tags           |
      |  - annotations: |
      | color: blue     |
      | name: prod      |

  # @author pruan@redhat.com
  # @case_id OCP-11727 OCP-11902
  @admin
  Scenario Outline: fail when retrieving an image manifest with wrong/missing credentials
    Given I store the default registry scheme to the :registry_scheme clipboard
    Given the etcd version is stored in the :etcd_ver clipboard
    Given I have a project
    And I select a random node's host
    Given default registry service ip is stored in the :integrated_reg_ip clipboard
    And the "~/.docker/config.json" file is restored on host after scenario
    When I run commands on the host:
      | docker login -u dnm -p <%= user.cached_tokens.first %> -e dnm@redmail.com <%= cb.integrated_reg_ip %> |
    Then the step should succeed
    # create a short hand
    And evaluation of `cb.integrated_reg_ip + "/" + project.name + "/tc487929-busybox:local"` is stored in the :my_tag clipboard
    When I run commands on the host:
      | docker pull busybox                 |
      | docker tag busybox <%= cb.my_tag %> |
    Then the step should succeed
    When I run commands on the host:
      | docker push <%= cb.my_tag %> |
    Then the step should succeed
    And I run the :get client command with:
      | resource | Imagestream |
    Then the step should succeed
    And the output should contain:
      | tc487929-busybox |
    # this bug prevents us from using docker pull https://bugzilla.redhat.com/show_bug.cgi?id=1347805
    And I run commands on the host:
       | curl -k -u <%=user.name %>:<token>  <%=cb.registry_scheme%>://<%= cb.integrated_reg_ip %>/v2/<%= project.name %>/tc487929-busybox/tags/list |
    Then the output should contain:
      | authentication required |
    Examples:
      | token        |
      | wrong_token  |
      |              |

  # @author yinzhou@redhat.com
  # @case_id OCP-10865,OCP-12069
  @admin
  @destructive
  Scenario: After Image Size Limit increment can push the image which previously over the limit
    Given I have a project
    And I select a random node's host
    Given default registry service ip is stored in the :integrated_reg_ip clipboard
    And the "~/.docker/config.json" file is restored on host after scenario
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/image-limit-range.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | limits                    |
      | resource_name | openshift-resource-limits |
      | o             | yaml                      |
      | n             | <%= project.name %>       |
    Then the step should succeed
    And I save the output to file>openshift-resource-limits.yaml
    Given I replace lines in "openshift-resource-limits.yaml":
      | storage: 1Gi | storage: 65Mi |
    When I run the :replace admin command with:
      | f             | openshift-resource-limits.yaml  |
      | n             | <%= project.name %>             |
    Then the step should succeed
    When I run commands on the host:
      | docker login -u dnm -p <%= user.cached_tokens.first %> -e dnm@redmail.com <%= cb.integrated_reg_ip %> |
    Then the step should succeed
    And evaluation of `cb.integrated_reg_ip + "/" + project.name + "/mystream:2.0"` is stored in the :my_tag clipboard
    When I run commands on the host:
      | docker pull docker.io/centos:centos7                 |
      | docker tag docker.io/centos:centos7 <%= cb.my_tag %> |
    Then the step should succeed
    When I run commands on the host:
      | docker push <%= cb.my_tag %> |
    Then the step should fail
    When I run the :get admin command with:
      | resource      | limits                    |
      | resource_name | openshift-resource-limits |
      | o             | yaml                      |
      | n             | <%= project.name %>       |
    Then the step should succeed
    And I save the output to file>openshift-resource-limits.yaml
    Given I replace lines in "openshift-resource-limits.yaml":
      | storage: 65Mi | storage: 1Gi |
    When I run the :replace admin command with:
      | f             | openshift-resource-limits.yaml  |
      | n             | <%= project.name %>             |
    Then the step should succeed
    When I run commands on the host:
      | docker push <%= cb.my_tag %> |
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
      | docker login -u dnm -p <%= service_account.cached_tokens.first %> -e dnm@redmail.com <%= cb.integrated_reg_ip %> |
    Then the step should succeed
    When I run commands on the host:
      | docker pull <%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:latest |
    Then the step should succeed
    Given I run commands on the host:
      | docker ps \|grep docker-registry: \| awk '{ print $1}'|
    Then the step should succeed
    Given I run commands on the host:
      | docker exec  <%= @result[:response].strip() %> find /registry \| grep layer\| grep mystream |
    Then the step should fail
    And the output should not match:
      | mystream |

  # @author yinzhou@redhat.com
  # @case_id OCP-10950
  @admin
  Scenario: Do not push blobs during cross-repo mount
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role            | registry-admin   |
      | user name       | system:anonymous |
    Then the step should succeed
    And I select a random node's host
    Given default registry service ip is stored in the :integrated_reg_ip clipboard
    When I run commands on the host:
      | docker pull busybox                 |
      | docker tag busybox <%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:latest |
      | docker push <%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:latest |
    Then the step should succeed
    Given I create a new project
    And evaluation of `project.name` is stored in the :u1p2 clipboard
    When I run the :policy_add_role_to_user client command with:
      | role            | registry-admin   |
      | user name       | system:anonymous |
    Then the step should succeed
    When I run commands on the host:
      | docker tag busybox <%= cb.integrated_reg_ip %>/<%= cb.u1p2 %>/mystream:latest |
      | docker push <%= cb.integrated_reg_ip %>/<%= cb.u1p2 %>/mystream:latest |
    Then the step should succeed
    And the output should contain:
      | Mounted from |

  # @author yinzhou@redhat.com
  # @case_id OCP-11314
  @admin
  Scenario: Support unauthenticated with registry-viewer role docker pull
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role            | registry-viewer   |
      | user name       | system:anonymous  |
    Then the step should succeed
    When I run the :new_build client command with:
      | app_repo | centos/ruby-22-centos7~https://github.com/sclorg/ruby-ex.git |
    Then the step should succeed
    And the "ruby-ex-1" build was created
    Then the "ruby-ex-1" build completes
    Given default docker-registry route is stored in the :integrated_reg_ip clipboard
    And I have a skopeo pod in the project
    And master CA is added to the "skopeo" dc
    When I execute on the pod:
      | skopeo                     |
      | --debug                    |
      | --insecure-policy          |
      | inspect                    |
      | --cert-dir                 |
      | /opt/qe/ca                 |
      | docker://<%= cb.integrated_reg_ip %>/<%= project.name %>/ruby-ex:latest |
    Then the step should succeed
    When I execute on the pod:
      | skopeo                     |
      | --debug                    |
      | --insecure-policy          |
      | copy                       |
      | --dest-cert-dir            |
      | /opt/qe/ca                 |
      | docker://docker.io/busybox |
      | docker://<%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:latest |
    Then the step should fail
    And the output should contain:
      | Unauthorized |
    Given I create a new project
    And evaluation of `project.name` is stored in the :u1p2 clipboard
    When I run the :new_build client command with:
      | app_repo | centos/ruby-22-centos7~https://github.com/sclorg/ruby-ex.git |
    Then the step should succeed
    And the "ruby-ex-1" build was created
    Then the "ruby-ex-1" build completes
    When I execute on the pod:
      | skopeo                     |
      | --debug                    |
      | --insecure-policy          |
      | inspect                    |
      | --cert-dir                 |
      | /opt/qe/ca                 |
      | docker://<%= cb.integrated_reg_ip %>/<%= cb.u1p2 %>/ruby-ex:latest |
    Then the step should fail
    When I execute on the pod:
      | skopeo                     |
      | --debug                    |
      | --insecure-policy          |
      | copy                       |
      | --dest-cert-dir            |
      | /opt/qe/ca                 |
      | docker://docker.io/busybox |
      | docker://<%= cb.integrated_reg_ip %>/<%= cb.u1p2 %>/mystream:latest  |
    Then the step should fail
    And the output should contain:
      | not authorized |

  # @author yinzhou@redhat.com
  # @case_id OCP-12158
  @admin
  Scenario: Specify ResourceQuota on project
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/openshift-object-counts.yaml"
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
  # @case_id OCP-12959
  @admin
  Scenario: Strip manifest stored in etcd
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
      | curl -u <%=user.name %>:<%= user.cached_tokens.first %>  <%=cb.registry_scheme%>://<%= cb.integrated_reg_ip %>/v2/<%= project.name %>/ruby-ex/manifests/latest --cert /etc/origin/master/admin.crt --cacert /etc/origin/master/ca.crt --key /etc/origin/master/admin.key |
    Then the step should succeed
    And the output should match:
      |.*blobSum.*|
    And I run commands on the host:
      | curl -u <%=user.name %>:<%= user.cached_tokens.first %>  <%=cb.registry_scheme%>://<%= cb.integrated_reg_ip %>/v2/<%= project.name %>/ruby-ex/manifests/<%= cb.image_id %> --cert /etc/origin/master/admin.crt --cacert /etc/origin/master/ca.crt --key /etc/origin/master/admin.key |
    Then the step should succeed
    And the output should match:
      |.*blobSum.*|

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

