Feature: oc import-image related feature
  # @author haowang@redhat.com
  # @case_id OCP-10637
  Scenario: import an invalid image stream
    When I have a project
    And I run the :import_image client command with:
      | image_name | invalidimagename|
    Then the step should fail
    And the output should match:
      | no.*"invalidimagename" exists |

  # @author xxia@redhat.com
  # @case_id OCP-11127
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

  # @author geliu@redhat.com
  # @case_id OCP-14269
  Scenario: Set owner refs in new RCs owned by DCs
    Given I have a project
    When I run the :tag client command with:
      | source_type | docker                       |
      | source      | openshift/deployment-example |
      | dest        | deployment-example:latest    |
    Then the output should match:
      | [Tt]ag deployment-example:latest           |
    And I wait for the "deployment-example:latest" istag to appear
    When I run the :create_deploymentconfig client command with:
      | image | deployment-example:latest |
      | name  | deployment-example        |
    Then the step should succeed
    When I run the :get client command with:
      | resource        | imagestreams |
    Then the output should match:
      | .*deployment-example.* |
    When I run the :get client command with:
      | resource_name   | deployment-example |
      | resource        | dc                 |
      | o               | template           |
      | template        | {{.metadata.uid}}  |
    And evaluation of `@result[:response]` is stored in the :dc_uid clipboard
    When I run the :get client command with:
      | resource_name   | deployment-example-1          |
      | resource        | rc                            |
      | o               | template                      |
      | template        | {{.metadata.ownerReferences}} |
    Then the output should match:
      | .*<%= cb.dc_uid %>.* |


  # @author geliu@redhat.com
  # @case_id OCP-14380
  Scenario: Set owner refs in adopted/released RCs owned by DCs
    Given I have a project

    When I run the :tag client command with:
      | source_type | docker                       |
      | source      | openshift/deployment-example |
      | dest        | deployment-example:latest    |
    Then the output should match:
      | [Tt]ag deployment-example:latest           |
    And I wait for the "deployment-example:latest" istag to appear

    When I run the :create_deploymentconfig client command with:
      | image | deployment-example:latest |
      | name  | deployment-example        |
    Then the step should succeed
    Then the "deployment-example" image stream was created

    When I run the :get client command with:
      | resource_name   | deployment-example-1          |
      | resource        | rc                            |
      | o               | template                      |
      | template        | {{.metadata.ownerReferences}} |
    Then the output should match:
      | \bdeployment-example\b |

    When I run the :patch client command with:
      | resource      | rc                                                                                              |
      | resource_name | deployment-example-1                                                                            |
      | p             | {"metadata": {"labels":{"openshift.io/deployment-config.name": "deployment-example-detached"}}} |
    Then the step should succeed

    When I run the :get client command with:
      | resource_name   | deployment-example-1          |
      | resource        | rc                            |
      | o               | template                      |
      | template        | {{.metadata.ownerReferences}} |
    Then the output should contain:
      | no value |

    Given number of replicas of "deployment-example" deployment config becomes:
      | desired | 1 |
      | current | 0 |

    When I run the :patch client command with:
      | resource      | rc                                                                                     |
      | resource_name | deployment-example-1                                                                   |
      | p             | {"metadata": {"labels":{"openshift.io/deployment-config.name": "deployment-example"}}} |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource_name   | deployment-example-1          |
      | resource        | rc                            |
      | o               | template                      |
      | template        | {{.metadata.ownerReferences}} |
    Then the output should match:
      | \bdeployment-example\b |
    """
    Given number of replicas of "deployment-example" deployment config becomes:
      | desired | 1 |
      | current | 1 |
