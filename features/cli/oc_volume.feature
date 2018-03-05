Feature: oc_volume.feature

  # @author cryan@redhat.com
  # @case_id OCP-12283
  Scenario: option '--all' and '--selector' can not be used together
    Given I have a project
    And I create a new application with:
      | docker image | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
      | name         | myapp                |
    Then the step should succeed
    When I run the :volume client command with:
      | resource | pod |
      | all | true |
      | selector | frontend |
    Then the step should fail
    And the output should contain "you may specify either --selector or --all but not both"

  # @author xxia@redhat.com
  # @case_id OCP-12194
  @smoke
  Scenario: Create a pod that consumes the secret in a volume
    Given I have a project
    When I run the :secrets client command with:
      | action         | new-basicauth     |
      | name           | basicsecret       |
      | username       | user-1            |
      | password       | pass-1            |
    Then the step should succeed
    When I run the :secrets client command with:
      | action         | add                    |
      | serviceaccount | serviceaccount/default |
      | secrets_name   | secret/basicsecret     |
    Then the step should succeed
    When I run the :run client command with:
      | name         | mydc                  |
      | image        | <%= project_docker_repo %>aosqe/hello-openshift |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=mydc-1 |
    When I run the :volume client command with:
      | resource      | dc                     |
      | resource_name | mydc                   |
      | action        | --add                  |
      | name          | secret-volume          |
      | type          | secret                 |
      | secret-name   | basicsecret            |
      | mount-path    | /etc/secret-volume-dir |
    Then the step should succeed

    Given a pod becomes ready with labels:
      | deployment=mydc-2 |
    When I execute on the pod:
      | cat | /etc/secret-volume-dir/username |
    Then the step should succeed
    And the output by order should contain:
      | user-1 |
    When I execute on the pod:
      | cat | /etc/secret-volume-dir/password |
    Then the step should succeed
    And the output by order should contain:
      | pass-1 |

  # @author xxia@redhat.com
  # @case_id OCP-11906
  @smoke
  Scenario: Add secret volume to dc and rc
    Given I have a project
    When I run the :run client command with:
      | name   | mydc                 |
      | image  | <%= project_docker_repo %>openshift/hello-openshift |
    Then the step should succeed
    When I run the :secrets client command with:
      | action | new             |
      | name   | my-secret       |
      | source | /etc/hosts      |
    Then the step should succeed

    Given I wait until replicationController "mydc-1" is ready
    When I run the :volume client command with:
      | resource      | rc                |
      | resource_name | mydc-1            |
      | action        | --add             |
      | name          | secret            |
      | type          | secret            |
      | secret-name   | my-secret         |
      | mount-path    | /etc              |
    Then the step should succeed

    When I run the :volume client command with:
      | resource      | dc                |
      | resource_name | mydc              |
      | action        | --add             |
      | name          | secret            |
      | type          | secret            |
      | secret-name   | my-secret         |
      | mount-path    | /etc              |
    Then the step should succeed

    When I run the :get client command with:
      | resource       | :false    |
      | resource_name  | dc/mydc   |
      | resource_name  | rc/mydc-1 |
      | o              | yaml      |
    Then the step should succeed
    # The output has "name: secret" prefixed with both "  " (2 spaces) and "- " ("-" and 1 space).
    # Using <%= "  name: secret" %> can reduce script lines. Otherwise, would contain 4 times of it
    And the output should contain 2 times:
      |   volumeMounts:            |
      |   - mountPath: /etc        |
      | <%= "  name: secret" %>    |
      | volumes:                   |
      | - name: secret             |
      |   secret:                  |
      |     secretName: my-secret  |

  # @author xxia@redhat.com
  # @case_id OCP-11141
  @smoke
  Scenario: Add gitRepo volume to pod, dc and rc
    Given I have a project
    And I run the :run client command with:
      | name      | mydc              |
      | image     | <%= project_docker_repo %>openshift/hello-openshift |
      | -l        | label=mydc        |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | label=mydc   |
    When I run the :volume client command with:
      | resource      | dc                     |
      | resource_name | mydc                   |
      | action        | --add                  |
      | name          | git                    |
      | source        | {"gitRepo": {"repository": "https://github.com/openshift/origin.git", "revision": "99c6de7216384f84369ad3f7572003a417206e8f"}} |
      | mount-path    | /etc                   |
    Then the step should succeed
    When I run the :volume client command with:
      | resource      | rc                     |
      | resource_name | mydc-1                 |
      | action        | --add                  |
      | name          | git                    |
      | source        | {"gitRepo": {"repository": "https://github.com/openshift/origin.git", "revision": "99c6de7216384f84369ad3f7572003a417206e8f"}} |
      | mount-path    | /etc                   |
    Then the step should succeed
    When I run the :get client command with:
      | resource       | :false    |
      | resource_name  | dc/mydc   |
      | resource_name  | rc/mydc-1 |
      | o              | yaml      |
    Then the step should succeed
    And the output should contain 2 times:
      | - mountPath: /etc                                          |
      | - gitRepo:                                                 |
      |     repository: https://github.com/openshift/origin.git    |
      |     revision: 99c6de7216384f84369ad3f7572003a417206e8f     |
    And the output should contain 4 times:
      |   name: git                                                |

  # @author xxia@redhat.com
  # @author jhou@redhat.com
  # @case_id OCP-12037
  Scenario: Add volume to all available resources in the namespace
    Given I have a project
    When I run the :run client command with:
      | name      | myrc1                 |
      | image     | aosqe/hello-openshift |
      | generator | run-controller/v1     |
      | limits    | cpu=200m,memory=512Mi |
      | requests  | cpu=100m,memory=256Mi |
    Then the step should succeed
    When I run the :run client command with:
      | name      | myrc2                 |
      | image     | aosqe/hello-openshift |
      | generator | run-controller/v1     |
      | limits    | cpu=200m,memory=512Mi |
      | requests  | cpu=100m,memory=256Mi |
    Then the step should succeed
    When I run the :secrets client command with:
      | action | new        |
      | name   | my-secret  |
      | source | /etc/hosts |
    Then the step should succeed

    Given a pod becomes ready with labels:
      |  run=myrc2 |
    When I run the :get client command with:
      | resource      | rc                             |
      | resource_name | myrc2                          |
      | template      | {{.status.observedGeneration}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :version clipboard

    When I run the :volume client command with:
      | resource    | rc        |
      | all         | true      |
      | action      | --add     |
      | name        | secret    |
      | type        | secret    |
      | secret-name | my-secret |
      | mount-path  | /etc      |
    Then the step should succeed
    And the output should contain:
      | myrc1 |
      | myrc2 |

    When I run the :volume client command with:
      | resource | rc     |
      | all      | true   |
      | action   | --list |
    Then the step should succeed
    And the output should match 2 times:
      | replicationcontrollers/myrc[12]  |
      |   secret/my-secret as secret     |
      |     mounted at /etc              |

    # Need wait to ensure the resource is updated. Otherwise the next '--remove' step would fail
    # when tested in auto, with error like 'the object has been modified; please apply your changes to the latest version and try again'
    # Note: must check .status.observedGeneration, rather than .metadata.generation and/or .metadata.resourceVersion
    Given I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | rc                             |
      | resource_name | myrc2                          |
      | template      | {{.status.observedGeneration}} |
    Then the step should succeed
    And the output should not contain "<%= cb.version %>"
    """
    When I run the :volume client command with:
      | resource | rc       |
      | all      | true     |
      | action   | --remove |
      | confirm  | true     |
    Then the step should succeed
    When I run the :volume client command with:
      | resource | rc     |
      | all      | true   |
      | action   | --list |
    Then the step should succeed
    And the output should contain:
      | myrc1 |
      | myrc2 |

  # @author gpei@redhat.com
  # @case_id OCP-12247
  Scenario: New volume can not have a same mount point that already exists in a container
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/ui/application-template-stibuild-without-customize-route.json |
    Then the step should succeed
    When I run the :volume client command with:
      | resource      | dc                |
      | resource_name | database          |
      | name          | v1                |
      | action        | --add             |
      | mount-path    | /opt              |
    Then the step should succeed
    When I run the :volume client command with:
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
      | docker image | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
    Then the step should succeed
    And I run the :run client command with:
      | name         | testpod                   |
      | image        | openshift/hello-openshift |
      | generator    | run-pod/v1                |
    Given the pod named "testpod" becomes ready

    Given I run the :label client command with:
      | resource     | pods                      |
      | name         | testpod                   |
      | key_val      | volume=nfs              |
    Given I run the :label client command with:
      | resource     | dc                        |
      | name         | ruby-hello-world          |
      | key_val      | volume=emptydir         |

    When I run the :volume client command with:
      | resource      | pods                     |
      | action        | --list                   |
      | selector      | volume=nfs             |
    Then the output should contain "pods/testpod"
    When I run the :volume client command with:
      | resource      | dc                       |
      | action        | --list                   |
      | selector      | volume=emptydir        |
    Then the output should contain "ruby-hello-world"

  # @author jhou@redhat.com
  # @case_id OCP-12134
  Scenario: Add/Remove volumes against multiple resources
    Given I have a project

    When I process and create "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    Then the step should succeed

    # Add volume to dc
    Given I wait until replicationController "database-1" is ready
    When I run the :volume client command with:
      | resource   | rc/database-1 |
      | resource   | dc/database   |
      | action     | --add         |
      | name       | emptyvol      |
      | type       | emptyDir      |
      | mount-path | /etc/         |
    Then the step should succeed

    When I run the :volume client command with:
      | resource | dc/database |
      | action   | --list      |
    Then the output should contain "emptyvol"

    When I run the :volume client command with:
      | resource | rc/database-1 |
      | action   | --list        |
    Then the output should contain "emptyvol"

    # Remove multiple volumes without giving volume name and '--confirm' option
    When I run the :volume client command with:
      | resource | rc/database-1 |
      | resource | dc/database   |
      | action   | --remove      |
    Then the step should not succeed
    And the output should contain "error: must provide --confirm"

    # Remove volume from multiple resources
    When I run the :volume client command with:
      | resource | rc/database-1 |
      | resource | dc/database   |
      | action   | --remove      |
      | confirm  | true          |
    Then the step should succeed

    # Volumes are removed from dc and rc
    When I run the :volume client command with:
      | resource | rc/database-1 |
      | resource | dc/database   |
      | action   | --list        |
    Then the output should not contain "emptyvol"
