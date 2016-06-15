Feature: oc import-image related feature
  # @author haowang@redhat.com
  # @case_id 488868
  Scenario: import an invalid image stream
    When I have a project
    And I run the :import_image client command with:
      | image_name | invalidimagename|
    Then the step should fail
    And the output should match:
      | no.*"invalidimagename" exists |

  # @author chunchen@redhat.com
  # @case_id 488870
  Scenario: [origin_infrastructure_437] Import new tags to image stream
    Given I have a project
    When I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc488870/application-template-stibuild.json |
    Then the step should succeed
    When I run the :new_secret client command with:
      | secret_name     | sec-push                                                             |
      | credential_file | <%= expand_private_path(conf[:services, :docker_hub, :dockercfg]) %> |
    Then the step should succeed
    When I run the :add_secret client command with:
      | sa_name         | builder                     |
      | secret_name     | sec-push                    |
    Then the step should succeed
    Given a 5 character random string is stored into the :tag_name clipboard
    When I run the :new_app client command with:
      | template | python-sample-sti                   |
      | param    | OUTPUT_IMAGE_TAG=<%= cb.tag_name %> |
    When I run the :get client command with:
      | resource        | imagestreams |
    Then the output should contain "python-sample-sti"
    And the output should not contain "<%= cb.tag_name %>"
    Given the "python-sample-build-sti-1" build was created
    And the "python-sample-build-sti-1" build completed
    When I run the :import_image client command with:
      | image_name         | python-sample-sti        |
    Then the step should succeed
    When I run the :get client command with:
      | resource_name   | python-sample-sti |
      | resource        | imagestreams      |
      | o               | yaml              |
    Then the output should contain "tag: <%= cb.tag_name %>"

  # @author chaoyang@redhat.com
  # @case_id 474368
  Scenario: [origin_infrastructure_319]Do not create tags for ImageStream if image repository does not have tags
    When I have a project
    And I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image-streams/is_without_tags.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | imagestreams |
    Then the output should contain "hello-world"
    When I run the :get client command with:
      | resource_name   | hello-world  |
      | resource        | imagestreams     |
      | o               | yaml             |
    And the output should not contain "tags"

  # @author xxia@redhat.com
  # @case_id 488869
  Scenario: Import new images to image stream
    Given I have a project
    When I run the :create client command with:
      | f        | -   |
      | _stdin   | {"kind":"ImageStream","apiVersion":"v1","metadata":{"name":"my-imagestream"}} |
    Then the step should succeed

    # Creating a pod is a helper step. Without this, cucumber runs the ':create' step so fast that the imagestream is not yet ready to be referenced in ':patch' step and ':patch' will fail
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
    Then the step should succeed
    Given the pod named "hello-openshift" becomes ready
    When I run the :patch client command with:
      | resource      | is                      |
      | resource_name | my-imagestream          |
      | p             | {"spec":{"dockerImageRepository":"aosqe/hello-openshift"}} |
    Then the step should succeed
    When I run the :import_image client command with:
      | image_name         | my-imagestream           |
    Then the step should succeed
    And the output should match:
      | The import completed successfully           |
      | latest.+aosqe/hello-openshift@sha256:       |


  # @author wjiang@redhat.com
  # @case_id 510523
  Scenario: Could not import the tag when reference is true
    Given I have a project
    When I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image-streams/tc510523.json |
    Then the step should succeed
    Given I wait up to 15 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | imagestreamtags |
    Then the step should succeed
    And the output should not contain:
      | aosqeruby:3.3 |
    """


  # @author wsun@redhat.com
  # @case_id 510524
  Scenario: Import image when pointing to non-existing docker image
    Given I have a project
    When I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image-streams/tc510524.json |
    Then the step should succeed
    When I run the :import_image client command with:
      | image_name | tc510524 |
    Then the step should fail
    And the output should match:
      | the repository "aosqe/non-existen-image" was not found, tag "latest" has not been set on repository "aosqe/non-existen-image" |


  # @author wjiang@redhat.com
  # @case_id 510525
  Scenario: Import image when spec.DockerImageRepository defined without any tags
    Given I have a project
    When I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image-streams/tc510525.json |
    Then the step should succeed
    Given I wait up to 15 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | imagestreamtags |
    Then the step should succeed
    And the output should match:
      | aosqeruby:latest |
    """


  # @author wjiang@redhat.com
  # @case_id 510526
  Scenario: Import Image when spec.DockerImageRepository not defined
    Given I have a project
    When I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image-streams/tc510526.json |
    Then the step should succeed
    Given I wait up to 15 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | imagestreamtags |
    Then the step should succeed
    And the output should contain:
      | aosqeruby:3.3 |
    And the output should not contain:
      | aosqeruby:latest |
    """


  # @author wjiang@redhat.com
  # @case_id 510527
  Scenario: Import image when spec.DockerImageRepository with some tags defined when Kind!=DockerImage
    Given I have a project
    When I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image-streams/tc510525.json |
    Then the step should succeed 
    Given I wait up to 15 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | imagestreamtags |
    Then the step should succeed
    And the output should contain:
      | aosqeruby:latest |
    """
    When I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image-streams/tc510527.json |
    Then the step should succeed
    Given I wait up to 15 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | imagestreamtags |
    Then the step should succeed
    And the output should contain:
      | aosqeruby33:3.3 |
    And the output should contain 2 times:
      | aosqe/ruby-20-centos7@sha256:093405d5f541b8526a008f4a249f9bb8583a3cffd1d8e301c205228d1260150a |
    """


  # @author wjiang@redhat.com
  # @case_id 510528
  Scenario: Import image when spec.DockerImageRepository with some tags defined when Kind==DockerImage
    Given I have a project
    When I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image-streams/tc510528.json |
    Then the step should succeed
    Given I wait up to 15 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | imagestreamtags |
    Then the step should succeed
    And the output should contain:
      | aosqeruby:3.3 |
    """


  # @author wsun@redhat.com
  # @case_id 510529
  Scenario: Import Image without tags and spec.DockerImageRepository set
    Given I have a project
    When I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image-streams/tc510529.json |
    Then the step should succeed
    When I run the :import_image client command with:
      | image_name | tc510529 |
    Then the step should fail
    And the output should match:
      | error: image stream has not defined anything to import |

  # @author xiaocwan@redhat.com
  # @case_id 519468
  Scenario: oc import-image should take the new api endpoint to run imports instead of clearing the annotation
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                 |
      | source      | hello-openshift:latest |
      | dest        | <%= project.name %>/ho:latest |
    Then the output should match:
      | [Tt]ag ho:latest |
    When I get project is as YAML
    Then the output should match:
      | annotations:\\s+openshift.io/image.dockerRepositoryCheck:|

    When I run the :import_image client command with:
      | image_name    | ho |
      | loglevel | 6  |
    Then the output should contain:
      | /oapi/v1/namespaces/<%= project.name %>/imagestreams/ho |
    When I get project is as YAML
    Then the output should match:
      | annotations:\\s+openshift.io/image.dockerRepositoryCheck:|

  # @author xiaocwan@redhat.com
  # @case_id 474369
  Scenario: Tags should be added to ImageStream if image repository is from an external docker registry
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image-streams/external.json |
    Then the step should succeed
    And I wait for the steps to pass:
    ## istag will not show promtly as soon as is create, need wait for a few seconds
    """
    When I run the :get client command with:
      | resource | imageStreams |
      | o        | yaml         |
    Then the step should succeed
    And the output should match:
      | tag:\\s+None    |
      | tag:\\s+latest  |
      | tag:\\s+busybox |
    """
