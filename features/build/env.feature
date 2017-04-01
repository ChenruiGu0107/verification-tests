Feature: env.feature

  # @author shiywang@redhat.com
  # @case_id OCP-11411
  Scenario: Set environment variables when creating application using DeploymentConfig template
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/sclorg/mongodb-container/master/examples/petset/mongodb-petset-persistent.yaml"
    And I replace lines in "mongodb-petset-persistent.yaml":
      | centos/mongodb-32-centos7 | <%= product_docker_repo %>rhscl/mongodb-32-rhel7 |
    When I run the :new_app client command with:
      | app_repo | mongodb-petset-persistent.yaml |
      | e        | VOLUME_CAPACITY=2Gi            |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | mongo-data-mongodb-0                                                            |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    And the step should succeed
    When I run the :env client command with:
      | resource | pod/mongodb-0 |
      | list     | true          |
    And the step should succeed
    And the output should contain:
      | VOLUME_CAPACITY=2Gi |
    When I run the :delete client command with:
      | object_type | all  |
      | all         | true |
    When I run the :new_app client command with:
      | app_repo | mongodb-petset-persistent.yaml |
      | e        | APPLE1=apple                                                                                                     |
      | e        | APPLE2=tesla                                                                                                     |
      | e        | APPLE3=linux                                                                                                     |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | mongo-data-mongodb-0                                                            |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    And the step should succeed
    When I run the :env client command with:
      | resource | pod/mongodb-0 |
      | list     | true          |
    And the step should succeed
    And the output should contain:
      | APPLE1=apple |
      | APPLE2=tesla |
      | APPLE3=linux |

  # @author shiywang@redhat.com
  # @case_id OCP-11007
  Scenario: Allow for non-string parameters in templates
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/OCP-11007/cakephp1.json |
    Then the step should succeed
    And the "cakephp-example-1" build was created
    And the "cakephp-example-1" build completed
    Given I wait until number of replicas match "2" for replicationController "cakephp-example-1"
    And I delete all resources from the project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/OCP-11007/cakephp2.json |
    Then the step should succeed
    And the "cakephp-example-1" build was created
    And the "cakephp-example-1" build completed
    When I run the :process client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/OCP-11007/cakephp3.json |
    And the output should contain "a${{REPLICA_COUNT}}"
    When I run the :process client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/OCP-11007/cakephp4.json |
    And the output should contain "{2"