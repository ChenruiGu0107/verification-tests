Feature: limit range related scenarios:

  # @author xiaocwan@redhat.com
  # @case_id OCP-12339
  @admin
  Scenario: The number of created persistent volume claims can not exceed the limitation
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/kubernetes/kubernetes/master/test/fixtures/doc-yaml/admin/resourcequota/quota.yaml"
    And I replace lines in "quota.yaml":
      | persistentvolumeclaims: "10" | persistentvolumeclaims: "1"        |
    When I run the :create admin command with:
      | f |  quota.yaml         |
      | n | <%= project.name %> |
    Then the step should succeed
    And the output should match:
      | [Rr]esourcequota.*quota.*created |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/kubernetes/kubernetes/master/test/fixtures/doc-yaml/user-guide/persistent-volumes/claims/claim-01.yaml |
    Then the step should succeed
    And the output should match:
      | [Pp]ersistentvolumeclaim.*myclaim-1.*created |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/kubernetes/kubernetes/master/test/fixtures/doc-yaml/user-guide/persistent-volumes/claims/claim-01.yaml |
    Then the step should fail
    And the output should match:
      | [Ee]rror.*when creat.*myclaim-1.*forbidden.*[Ee]xceeded quota |


  # @author yinzhou@redhat.com
  # @case_id OCP-11289
  @admin
  Scenario: Check the openshift.io/imagestreams of quota in the project after build image
    Given I have a project
    When I run the :create admin command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/quota/openshift-object-counts.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | quota |
      | resource_name | openshift-object-counts |
      | template      | {{.status.used}} |
      | n             | <%= project.name %> |
    Then the output should match "openshift.io/imagestreams:0"
    """
    When I run the :new_build client command with:
      | app_repo | centos/ruby-22-centos7~https://github.com/sclorg/ruby-ex.git |
    Then the step should succeed
    And the "ruby-ex-1" build was created
    Then the "ruby-ex-1" build completes
    When I run the :get client command with:
      | resource      | quota |
      | resource_name | openshift-object-counts |
      | template      | {{.status.used}} |
      | n             | <%= project.name %> |
    Then the output should match "openshift.io/imagestreams:2"
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    Then the "ruby-ex-2" build completes
    When I run the :get client command with:
      | resource      | quota |
      | resource_name | openshift-object-counts |
      | template      | {{.status.used}} |
      | n             | <%= project.name %> |
    Then the output should match "openshift.io/imagestreams:2"


  # @author yinzhou@redhat.com
  # @case_id OCP-11594
  @admin
  Scenario: Check the quota after import-image with --all option
    Given I have a project
    When I run the :create admin command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/quota/openshift-object-counts.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | quota |
      | resource_name | openshift-object-counts |
      | template      | {{.status.used}} |
      | n             | <%= project.name %> |
    Then the output should match "openshift.io/imagestreams:0"
    """
    When I run the :import_image client command with:
      | image_name | centos           |
      | from       | docker.io/centos |
      | confirm    | true             |
      | all        | true             |
    Then the step should succeed
    When I run the :tag client command with:
      | source_type  | docker                           |
      | source       | docker.io/library/busybox:latest |
      | dest         | mystream:latest                  |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | quota |
      | resource_name | openshift-object-counts |
      | template      | {{.status.used}} |
      | n             | <%= project.name %> |
    Then the output should match "openshift.io/imagestreams:2"
    """


  # @author yinzhou@redhat.com
  # @case_id OCP-12214
  @admin
  Scenario: When exceed openshift.io/image-tags will ban to create new image references in the project
    Given I have a project
    When I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/quota/image-limit-range.yaml"
    And I replace lines in "image-limit-range.yaml":
      | openshift.io/image-tags: 20 | openshift.io/image-tags: 1 |
    Then the step should succeed
    When I run the :create admin command with:
      | f | image-limit-range.yaml |
      | n | <%= project.name %>    |
    Then the step should succeed
    When I run the :tag client command with:
      | source_type  | docker                           |
      | source       | docker.io/library/busybox:latest |
      | dest         | mystream:v1                      |
    Then the step should succeed
    When I run the :tag client command with:
      | source_type  | docker                    |
      | source       | openshift/hello-openshift |
      | dest         | mystream:v2               |
    Then the step should fail
    And the output should contain:
      | forbidden |


  # @author yinzhou@redhat.com
  # @case_id OCP-12263
  @admin
  Scenario: When exceed openshift.io/images will ban to create image reference or push image to project
    Given I have a project
    When I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/quota/image-limit-range.yaml"
    And I replace lines in "image-limit-range.yaml":
      | openshift.io/images: 30 | openshift.io/images: 1 |
    Then the step should succeed
    When I run the :create admin command with:
      | f | image-limit-range.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :tag client command with:
      | source_type  | docker                           |
      | source       | docker.io/library/busybox:latest |
      | dest         | mystream:v1                      |
    Then the step should succeed
    When I run the :tag client command with:
      | source_type  | docker                    |
      | source       | openshift/hello-openshift |
      | dest         | mystream:v2               |
    And I wait for the steps to pass:
    """
    And I run the :describe client command with:
      |resource | imagestream |
      | name    | mystream    |
    And the output should contain:
      | Import failed |
    """
    Given default registry service ip is stored in the :integrated_reg_ip clipboard
    And evaluation of `cb.integrated_reg_ip + "/" + project.name + "/mystream"` is stored in the :mystream clipboard
    And I have a skopeo pod in the project
    When I execute on the pod:
      | skopeo                                    |
      | --debug                                   |
      | --insecure-policy                         |
      | copy                                      |
      | --dest-tls-verify=false                   |
      | --dcreds                                  |
      | any:<%= user.cached_tokens.first %>       |
      | docker://docker.io/centos:centos7         |
      | docker://<%= cb.mystream %>:v3            |
    Then the step should fail
    And the output should match:
      | uploading.*denied |

