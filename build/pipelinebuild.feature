Feature: pipelinebuild.feature

  # @author dyan@redhat.com
  Scenario Outline: Jenkins pipeline build from private repo with/without secret of password with http-gitserver
    Given I have a project
    Given I have a jenkins v<tag> application
    When I have an http-git service in the project
    And I run the :set_env client command with:
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
    When I run the :secrets_new_basicauth client command with:
      | secret_name | mysecret  |
      | username    | openshift |
      | password    | redhat    |
    Then the step should succeed
    Given I obtain test data file "templates/tc543797/samplepipeline.yaml"
    When I run the :new_app client command with:
      | file | samplepipeline.yaml |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | buildconfig                                                                                                               |
      | resource_name | sample-pipeline                                                                                                           |
      | p             | {"spec": {"source": { "git": {"uri": "http://git:8080/jenkins-pipeline-test.git"},"sourceSecret": {"name": "mysecret"}}}} |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    Given I update "nodejs" slave image for jenkins <tag> server
    And I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    When the "sample-pipeline-1" build becomes :running
    When the "nodejs-mongodb-example-1" build becomes :running
    Then the "nodejs-mongodb-example-1" build completed
    Then the "sample-pipeline-1" build completed
    When I run the :secrets_new_basicauth client command with:
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
      | 2   | # @case_id OCP-11857

  # @author dyan@redhat.com
  Scenario Outline: Jenkins pipeline build from private git repo with/without ssh key
    Given I have a project
    Given I have a jenkins v<tag> application
    When I have an ssh-git service in the project
    And the "secret" file is created with the following lines:
      | <%= cb.ssh_private_key.to_pem %> |
    And I run the :secrets_new_sshauth client command with:
      | ssh_privatekey | secret   |
      | secret_name    | mysecret |
    Then the step should succeed
    When I execute on the pod:
      | bash                                                                                                                               |
      | -c                                                                                                                                 |
      | cd /repos/ && rm -rf sample.git && git clone --bare https://github.com/openshift-qe/jenkins-pipeline-nodejsmongodb-test sample.git |
    Then the step should succeed
    Given I obtain test data file "templates/tc543797/samplepipeline.yaml"
    When I run the :new_app client command with:
      | file | samplepipeline.yaml |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | buildconfig                                              |
      | resource_name | sample-pipeline                                          |
      | p             | {"spec":{"source":{"git":{"uri":"<%= cb.git_repo %>"}}}} |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    Given I update "nodejs" slave image for jenkins <tag> server
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
      | 2   | # @case_id OCP-11858

  # @author xiuwang@redhat.com
  # @case_id OCP-17299
  Scenario: Sync openshift secret to credential in jenkins with basic-auth type
    Given I have a project
    Given I have a jenkins v2 application
    When I have an http-git service in the project
    And I run the :set_env client command with:
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
      | bash                                                                                                               |
      | -c                                                                                                                 |
      | cd /var/lib/git/ && git clone --bare https://github.com/openshift/openshift-jee-sample.git openshift-jee-sample.git|
    Then the step should succeed
    When I run the :secrets_new_basicauth client command with:
      | secret_name | mysecret  |
      | username    | openshift |
      | password    | redhat    |
    Then the step should succeed
    When I run the :label client command with:
      | resource | secret                                    |
      | name     | mysecret                                  |
      | key_val  | credential.sync.jenkins.openshift.io=true |
    Then the step should succeed
    Given I obtain test data file "templates/maven-pipeline-with-credential.yaml"
    When I run the :new_app client command with:
      | file | maven-pipeline-with-credential.yaml |
      | p    | GIT_SOURCE_URL=http://git:8080/openshift-jee-sample.git                                                          |
      | p    |OPENSHIFT_SECRET_NAME=<%= project.name %>-mysecret                                                                |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    Given I update "maven" slave image for jenkins 2 server
    When I perform the :check_jenkins_credentials web action with:
      | credential_name  | <%= project.name %>-mysecret     |
    Then the step should succeed

    And I run the :start_build client command with:
      | buildconfig | openshift-jee-sample |
    Then the step should succeed
    Then the "openshift-jee-sample-1" build completed
    When I run the :label client command with:
      | resource | secret                                |
      | name     | mysecret                              |
      | key_val  | credential.sync.jenkins.openshift.io- |
    Then the step should succeed
    When I perform the :check_jenkins_credentials web action with:
      | credential_name  | <%= project.name %>-mysecret     |
    Then the step should fail
    And I run the :start_build client command with:
      | buildconfig | openshift-jee-sample |
    Then the step should succeed
    Then the "openshift-jee-sample-2" build fails
    When I run the :label client command with:
      | resource | secret                                    |
      | name     | mysecret                                  |
      | key_val  | credential.sync.jenkins.openshift.io=true |
    Then the step should succeed
    When I perform the :check_jenkins_credentials web action with:
      | credential_name  | <%= project.name %>-mysecret     |
    Then the step should succeed
    When I run the :label client command with:
      | resource | secret                                     |
      | name     | mysecret                                   |
      | overwrite| true                                       |
      | key_val  | credential.sync.jenkins.openshift.io=false |
    Then the step should succeed
    When I perform the :check_jenkins_credentials web action with:
      | credential_name  | <%= project.name %>-mysecret     |
    Then the step should fail
    When I run the :label client command with:
      | resource | secret                                         |
      | name     | mysecret                                       |
      | key_val  | credential.sync.jenkins.openshift.io.fake=true |
    Then the step should succeed
    When I perform the :check_jenkins_credentials web action with:
      | credential_name  | <%= project.name %>-mysecret     |
    Then the step should fail

  # @author wewang@redhat.com
  # @case_id OCP-11065
  Scenario: Jenkins pipeline build with Blue Green Deployment Example
    Given I have a project
    And I have an http-git service in the project
    And I have a git client pod in the project
    When I execute on the pod:
      | bash                                                           |
      | -c                                                             |
      | cd /tmp/; git clone https://github.com/sclorg/nodejs-ex.git |
    Then the step should succeed
    When I execute on the pod:
      | bash                                                                                                                   |
      | -c                                                                                                                     |
      | cd /tmp/nodejs-ex/; git remote add openshift http://<%= cb.git_svc_ip %>:8080/nodejs-ex.git; git push openshift master |
    Then the step should succeed
    Given I have a jenkins v2 application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/bluegreen-pipeline.yaml |
      | p    | SOURCE_REPOSITORY_URL=http://<%= cb.git_svc_ip %>:8080/nodejs-ex.git                                        |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    And I run the :start_build client command with:
      | buildconfig | bluegreen-pipeline |
    Then the step should succeed
    And the "nodejs-mongodb-example-1" build completed
    Then the "bluegreen-pipeline-1" build completed
    When I execute on the "<%= cb.git_client_pod.name %>" pod:
      | bash |
      | -c   |
      | cd /tmp/nodejs-ex/; touch testfile; git add testfile; git commit -m "change: add testfile"; git push openshift master |
    Then the step should succeed
    And I run the :start_build client command with:
      | buildconfig | bluegreen-pipeline |
    Then the step should succeed
    And the "nodejs-mongodb-example-2" build completed
    And the "bluegreen-pipeline-2" build completed

  # @author wewang@redhat.com
  # @case_id OCP-18498
  Scenario: Start a few pipeline builds and removing one Build object in openshift
    Given the master version >= "3.10"
    And I have a project
    And I have a jenkins v2 application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    Given I update "nodejs" slave image for jenkins 2 server
    And I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    When the "sample-pipeline-1" build becomes :running
    And the "nodejs-mongodb-example-1" build becomes :running
    Then the "nodejs-mongodb-example-1" build completed
    Then the "sample-pipeline-1" build completed
    And I run the steps 2 times:
    """
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    """
    Given I get project builds
    Then the output should contain 3 times:
      | sample-pipeline |
    When the "sample-pipeline-3" build becomes :running
    And I perform the :jenkins_verify_job_text web action with:
      | namespace  | <%= project.name %>                    |
      | job_name   | <%= project.name %>-sample-pipeline    |
      | checktext  | <%= project.name %>/sample-pipeline-3  |
      | job_num    | 3                                      |
      | time_out   | 300                                    |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | rc        |
      | name     | jenkins-1 |
      | replicas | 0         |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type           | build             |
      | object_name_or_id     | sample-pipeline-3 |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | rc        |
      | name     | jenkins-1 |
      | replicas | 1         |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=jenkins |
    And I wait for the "jenkins" service to become ready
    #Login jenkins the second time
    Given I have a jenkins browser
    And I log in to jenkins
    And I perform the :jenkins_verify_job_text web action with:
      | namespace  | <%= project.name %>                    |
      | job_name   | <%= project.name %>-sample-pipeline    |
      | checktext  | <%= project.name %>/sample-pipeline-2  |
      | job_num    | 2                                      |
      | time_out   | 300                                    |
    Then the step should succeed
    And I perform the :jenkins_verify_job_text web action with:
      | namespace  | <%= project.name %>                    |
      | job_name   | <%= project.name %>-sample-pipeline    |
      | checktext  | <%= project.name %>/sample-pipeline-3  |
      | job_num    | 3                                      |
      | time_out   | 300                                    |
    Then the step should fail

  # @author wewang@redhat.com
  # @case_id OCP-20036
  Scenario: Build history limit cannot be saved with invalid string
    And I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | bc              |
      | resource_name | sample-pipeline |
      | p             | {"spec": {"successfulBuildsHistoryLimit": 3, "failedBuildsHistoryLimit": 2}} |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | bc              |
      | resource_name | sample-pipeline |
      | p             | {"spec": {"successfulBuildsHistoryLimit": 'abc', "failedBuildsHistoryLimit": 'abc'}} |
    Then the step should fail
