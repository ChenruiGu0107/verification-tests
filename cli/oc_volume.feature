Feature: oc_volume.feature

  # @author cryan@redhat.com
  # @case_id OCP-12283
  Scenario: option '--all' and '--selector' can not be used together
    Given I have a project
    And I create a new application with:
      | docker image | quay.io/openshifttest/storage@sha256:a05b96d373be86f46e76817487027a7f5b8b5f87c0ac18a246b018df11529b40 |
      | name         | myapp                                                                                                 |
    Then the step should succeed
    When I run the :set_volume client command with:
      | resource | pod      |
      | all      | true     |
      | selector | frontend |
    Then the step should fail
    And the output should contain "you may specify either --selector or --all but not both"

  # @author xxia@redhat.com
  # @author jhou@redhat.com
  # @case_id OCP-12037
  Scenario: Add volume to all available resources in the namespace
    Given I have a project
    When I run the :create_deploymentconfig client command with:
      | name      | myrc1                 |
      | image     | aosqe/hello-openshift |
    Then the step should succeed
    Given number of replicas of "myrc1" deployment config becomes:
      | desired   | 1 |
      | current   | 1 |
      | updated   | 1 |
      | available | 1 |
    When I run the :set_resources client command with:
      | resource      | rc                    |
      | resourcename  | myrc1-1               |
      | limits        | cpu=200m,memory=512Mi |
      | requests      | cpu=100m,memory=256Mi |
    Then the step should succeed
    And the output should contain "replicationcontroller/myrc1-1 resource requirements updated"
    When I run the :create_deploymentconfig client command with:
      | name      | myrc2                 |
      | image     | aosqe/hello-openshift |
    Then the step should succeed
    Given number of replicas of "myrc2" deployment config becomes:
      | desired   | 1 |
      | current   | 1 |
      | updated   | 1 |
      | available | 1 |
    When I run the :set_resources client command with:
      | resource      | rc                    |
      | resourcename  | myrc2-1               |
      | limits        | cpu=200m,memory=512Mi |
      | requests      | cpu=100m,memory=256Mi |
    Then the step should succeed
    And the output should contain "replicationcontroller/myrc2-1 resource requirements updated"
    When I run the :create_secret client command with:
      | name          | my-secret    |
      | secret_type   | generic      |
      | from_file     | /etc/hosts   |
    Then the step should succeed

    Given a pod becomes ready with labels:
      | deploymentconfig=myrc2 |
    When I run the :get client command with:
      | resource      | rc                             |
      | resource_name | myrc2-1                        |
      | template      | {{.status.observedGeneration}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :version clipboard

    When I run the :set_volume client command with:
      | resource    | rc        |
      | all         | true      |
      | action      | --add     |
      | name        | secret    |
      | type        | secret    |
      | secret-name | my-secret |
      | mount-path  | /etc      |
    Then the step should succeed
    And the output should contain:
      | myrc1-1 |
      | myrc2-1 |

    When I run the :set_volume client command with:
      | resource | rc     |
      | all      | true   |
      | action   | --all  |
    Then the step should succeed
    And the output should match 2 times:
      | myrc[12]-1                         |
      |   secret/my-secret as secret       |
      |     mounted at /etc                |

    # Need wait to ensure the resource is updated. Otherwise the next '--remove' step would fail
    # when tested in auto, with error like 'the object has been modified; please apply your changes to the latest version and try again'
    # Note: must check .status.observedGeneration, rather than .metadata.generation and/or .metadata.resourceVersion
    Given I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | rc                             |
      | resource_name | myrc2-1                        |
      | template      | {{.status.observedGeneration}} |
    Then the step should succeed
    And the output should not contain "<%= cb.version %>"
    """
    When I run the :set_volume client command with:
      | resource | rc       |
      | all      | true     |
      | action   | --remove |
      | confirm  | true     |
    Then the step should succeed
    When I run the :set_volume client command with:
      | resource | rc     |
      | all      | true   |
      | action   | --all  |
    Then the step should succeed
    And the output should contain:
      | myrc1-1 |
      | myrc2-1 |

  # @author gpei@redhat.com
  # @case_id OCP-12247
  Scenario: New volume can not have a same mount point that already exists in a container
    Given I have a project
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json |
    Then the step should succeed
    When I run the :set_volume client command with:
      | resource      | dc                |
      | resource_name | database          |
      | name          | v1                |
      | action        | --add             |
      | mount-path    | /opt              |
    Then the step should succeed
    When I run the :set_volume client command with:
      | resource      | dc                |
      | resource_name | database          |
      | name          | v2                |
      | action        | --add             |
      | mount-path    | /opt              |
    Then the step should fail
    And the output should contain "volume mount '/opt' already exists"

  # @author gpei@redhat.com
  # @case_id OCP-12340
  Scenario: Select resources with '--selector' option
    Given I have a project
    When I run the :new_app client command with:
      | name         | ruby-hello-world                                                                                      |
      | docker image | quay.io/openshifttest/storage@sha256:a05b96d373be86f46e76817487027a7f5b8b5f87c0ac18a246b018df11529b40 |
    Then the step should succeed
    And I run the :run client command with:
      | name         | testpod                                                                                               |
      | image        | quay.io/openshifttest/storage@sha256:a05b96d373be86f46e76817487027a7f5b8b5f87c0ac18a246b018df11529b40 |
      | generator    | run-pod/v1                                                                                            |
    Given the pod named "testpod" becomes ready

    Given I run the :label client command with:
      | resource     | pods                      |
      | name         | testpod                   |
      | key_val      | volume=nfs                |
    Given I run the :label client command with:
      | resource     | dc                        |
      | name         | ruby-hello-world          |
      | key_val      | volume=emptydir           |

    When I run the :set_volume client command with:
      | resource      | pods                     |
      | action        | --list                   |
      | selector      | volume=nfs               |
    Then the output should contain "pods/testpod"
    When I run the :set_volume client command with:
      | resource      | dc                       |
      | action        | --list                   |
      | selector      | volume=emptydir          |
    Then the output should contain "ruby-hello-world"

  # @author jhou@redhat.com
  # @case_id OCP-12134
  Scenario: Add/Remove volumes against multiple resources
    Given I have a project

    When I process and create "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    Then the step should succeed

    # Add volume to dc
    Given I wait until replicationController "database-1" is ready
    When I run the :set_volume client command with:
      | resource   | rc/database-1 |
      | resource   | dc/database   |
      | action     | --add         |
      | name       | emptyvol      |
      | type       | emptyDir      |
      | mount-path | /etc/         |
    Then the step should succeed

    When I run the :set_volume client command with:
      | resource | dc/database |
      | action   | --list      |
    Then the output should contain "emptyvol"

    When I run the :set_volume client command with:
      | resource | rc/database-1 |
      | action   | --list        |
    Then the output should contain "emptyvol"

    # Remove multiple volumes without giving volume name and '--confirm' option
    When I run the :set_volume client command with:
      | resource | rc/database-1 |
      | resource | dc/database   |
      | action   | --remove      |
    Then the step should not succeed
    And the output should contain "error: must provide --confirm"

    # Remove volume from multiple resources
    When I run the :set_volume client command with:
      | resource | rc/database-1 |
      | resource | dc/database   |
      | action   | --remove      |
      | confirm  | true          |
    Then the step should succeed

    # Volumes are removed from dc and rc
    When I run the :set_volume client command with:
      | resource | rc/database-1 |
      | resource | dc/database   |
      | action   | --list        |
    Then the output should not contain "emptyvol"
