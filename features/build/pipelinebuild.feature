Feature: pipelinebuild.feature

  # @author dyan@redhat.com
  # @case_id 543797 544324
  Scenario Outline: Jenkins pipeline build from private repo with/without secret of password with http-gitserver
    Given I have a project
    And I have an ephemeral jenkins v<tag> application      
    When I have an http-git service in the project
    And I run the :env client command with:
      | resource | dc/git                            |
      | e        | REQUIRE_SERVER_AUTH=              |
      | e        | REQUIRE_GIT_AUTH=openshift:redhat |
      | e        | BUILD_STRATEGY=source             |
      | e        | ALLOW_ANON_GIT_PULL=false         |
    Then the step should succeed
    When a pod becomes ready with labels:
      | deploymentconfig=git |
      | deployment=git-2     |
    And I execute on the pod:
      | bash                                                                                                                               |
      | -c                                                                                                                                 |
      | cd /var/lib/git/ && git clone --bare https://github.com/openshift-qe/jenkins-pipeline-nodejsmongodb-test jenkins-pipeline-test.git |
    Then the step should succeed
    When I run the :oc_secrets_new_basicauth client command with:
      | secret_name | mysecret  |
      | username    | openshift |
      | password    | redhat    |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc543797/samplepipeline.yaml |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | buildconfig                                                                                                               |
      | resource_name | sample-pipeline                                                                                                           |
      | p             | {"spec": {"source": { "git": {"uri": "http://git:8080/jenkins-pipeline-test.git"},"sourceSecret": {"name": "mysecret"}}}} |
    Then the step should succeed
    When a pod becomes ready with labels:
      | deploymentconfig=jenkins |
      | deployment=jenkins-1     |
    And I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    When the "sample-pipeline-1" build becomes :running
    When the "nodejs-mongodb-example-1" build becomes :running
    Then the "nodejs-mongodb-example-1" build completed
    Then the "sample-pipeline-1" build completed
    When I run the :oc_secrets_new_basicauth client command with:
      | secret_name | mysecret1 |
      | username    | openshift |
      | password    | invaild   |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | buildconfig                                                   |
      | resource_name | sample-pipeline                                               |
      | p             | {"spec": {"source": {"sourceSecret": {"name": "mysecret1"}}}} |
    Then the step should succeed
    And I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    And the "sample-pipeline-2" build failed

    Examples:
      | tag |
      | 1   |
      | 2   |

  # @author dyan@redhat.com
  # @case_id 543798 544325
  Scenario Outline: Jenkins pipeline build from private git repo with/without ssh key
    Given I have a project
    And I have an ephemeral jenkins v<tag> application
    When I have an ssh-git service in the project
    And the "secret" file is created with the following lines:
      | <%= cb.ssh_private_key.to_pem %> |
    And I run the :oc_secrets_new_sshauth client command with:
      | ssh_privatekey | secret   |
      | secret_name    | mysecret |
    Then the step should succeed
    When I execute on the pod:
      | bash                                                                                                                               |
      | -c                                                                                                                                 |
      | cd /repos/ && rm -rf sample.git && git clone --bare https://github.com/openshift-qe/jenkins-pipeline-nodejsmongodb-test sample.git |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc543797/samplepipeline.yaml |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | buildconfig                                              |
      | resource_name | sample-pipeline                                          |
      | p             | {"spec":{"source":{"git":{"uri":"<%= cb.git_repo %>"}}}} |
    Then the step should succeed
    When a pod becomes ready with labels:
      | deploymentconfig=jenkins |
      | deployment=jenkins-1     |
    And I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    And the "sample-pipeline-1" build failed
    When I run the :patch client command with:
      | resource      | buildconfig                                              |
      | resource_name | sample-pipeline                                          |
      | p             | {"spec":{"source":{"sourceSecret":{"name":"mysecret"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    When the "sample-pipeline-2" build becomes :running
    And the "nodejs-mongodb-example-1" build becomes :running
    Then the "nodejs-mongodb-example-1" build completed
    Then the "sample-pipeline-2" build completed

    Examples:
      | tag |
      | 1   |
      | 2   |

