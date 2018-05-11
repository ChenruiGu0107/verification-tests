Feature: pipelinebuild.feature

  # @author dyan@redhat.com
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
      | 1   | # @case_id OCP-11860
      | 2   | # @case_id OCP-11857

  # @author dyan@redhat.com
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
      | 1   | # @case_id OCP-11861
      | 2   | # @case_id OCP-11858

  # @author xiuwang@redhat.com
  # @case_id OCP-17229
  Scenario: Sync openshift secret to credential in jenkins with basic-auth type 
    Given I have a project
    Given I store master major version in the clipboard
    And I have an ephemeral jenkins v2 application      
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
      | bash                                                                                                               |
      | -c                                                                                                                 |
      | cd /var/lib/git/ && git clone --bare https://github.com/openshift/openshift-jee-sample.git openshift-jee-sample.git|
    Then the step should succeed
    When I run the :oc_secrets_new_basicauth client command with:
      | secret_name | mysecret  |
      | username    | openshift |
      | password    | redhat    |
    Then the step should succeed
    When I run the :label client command with:
      | resource | secret                                    |
      | name     | mysecret                                  |
      | key_val  | credential.sync.jenkins.openshift.io=true |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/maven-pipeline-with-credential.yaml |
      | p    | GIT_SOURCE_URL=http://git:8080/openshift-jee-sample.git                                                          |
      | p    |OPENSHIFT_SECRET_NAME=<%= project.name %>-mysecret                                                                |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=jenkins |
    And I wait for the "jenkins" service to become ready up to 300 seconds
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins_2/                                   |    
      | base_url | https://<%= route("jenkins", service("jenkins")).dns(by: user) %> | 
    Given I log in to jenkins
    Then the step should succeed
    When I perform the :jenkins_update_cloud_image web action with:
      | currentimgval | registry.access.redhat.com/openshift3/<%= env.version_ge("3.10", user: user) ? "jenkins-agent-maven-35" : "jenkins-slave-maven" %>-rhel7                          |
      | cloudimage    | <%= product_docker_repo %>openshift3/<%= env.version_ge("3.10", user: user) ? "jenkins-agent-maven-35" : "jenkins-slave-maven" %>-rhel7:v<%= cb.master_version %> |
    Then the step should succeed
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
