Feature: secrets related scenarios
  # @author pruan@redhat.com
  # @case_id OCP-11724
  Scenario: Can not convert to secrets with non-existing files
    Given I have a project
    And I run the :secrets client command with:
      | action       | new      |
      | secrets_name | tc483168 |
      | name | I_do_not_exist |
    Then the step should fail
    And the output should contain:
      | error: error reading I_do_not_exist: no such file or directory |

  # @author wjiang@redhat.com
  # @case_id OCP-12599
  Scenario: Generate dockercfg type secrets via oc secrets new-dockercfg
    Given I have a project
    When I run the :secrets_new_dockercfg client command with:
      |secret_name      |test                     |
      |docker_email     |serviceaccount@redhat.com|
      |docker_password  |password                 |
      |docker_server    |dockerregistry.io        |
      |docker_username  |serviceaccount           |
    Then the step should succeed
    When I run the :get client command with:
      |resource     |secrets  |
      |resource_name|test     |
    Then the step should succeed
    And the output should match "kubernetes.io/dockerc.*f.*g.*"

  # @author xiaocwan@redhat.com
  # @case_id OCP-12360
  @admin
  Scenario: [origin_platformexp_403] The number of created secrets can not exceed the limitation
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/myquota.yaml"
    And I replace lines in "myquota.yaml":
      | name: myquota                | <%= "name: "+project.name %> |
      | cpu: "30"                    | cpu: "20"                    |
      | memory: 16Gi                 | memory: 1Gi                  |
      | persistentvolumeclaims: "20" | persistentvolumeclaims: "10" |
      | pods: "20"                   | pods: "10"                   |
      | replicationcontrollers: "30" | replicationcontrollers: "20" |
      | secrets: "15"                | secrets: "1"                |
      | services: "10"               | services: "5"                |

    When I run the :create admin command with:
      | f        | myquota.yaml        |
      | n        | <%= project.name %> |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe admin command with:
      | resource      | quota |
      | name          | <%= project.name %>  |
      | n             | <%= project.name %> |
    Then the output should match:
      | secrets.*1 |
    """
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/secret.yaml |
    Then the step should not succeed
    And the output should contain:
      |  limit |

  # @author xiuwang@redhat.com
  # @case_id OCP-12254
  Scenario: Create new secrets for basic authentication
    Given I have a project
    When I run the :secrets_new_basicauth client command with:
      |secret_name |testsecret |
      |username    |tester     |
      |password    |password   |
    Then the step should succeed
    When I run the :get client command with:
      |resource      |secrets    |
      |resource_name |testsecret |
      |o             |yaml       |
    Then the step should succeed
    And the output should contain:
      |password:|
      |username:|
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cases/508970/ca.crt"
    When I run the :secrets_new_basicauth client command with:
      |secret_name |testsecret2 |
      |username    |tester      |
      |password    |password    |
      |cafile      |ca.crt      |
    Then the step should succeed
    When I run the :get client command with:
      |resource      |secrets     |
      |resource_name |testsecret2 |
      |o             |yaml        |
    Then the step should succeed
    And the output should contain:
      |password:|
      |username:|
      |ca.crt:  |
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cases/508970/.gitconfig"
    When I run the :secrets_new_basicauth client command with:
      |secret_name |testsecret3 |
      |username    |tester      |
      |password    |password    |
      |cafile      |ca.crt      |
      |gitconfig   |.gitconfig  |
    Then the step should succeed
    When I run the :get client command with:
      |resource      |secrets     |
      |resource_name |testsecret3 |
      |o             |yaml        |
    Then the step should succeed
    And the output should contain:
      |.gitconfig:|
      |ca.crt:    |

  # @author xxia@redhat.com
  # @case_id OCP-11731
  Scenario: There should be a dockcfg secret generated automatically based on the serviceaccount token
    Given I have a project
    And I wait up to 10 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | secret              |
    Then the output should contain:
      | default-dockercfg-  |
      | deployer-dockercfg- |
      | builder-dockercfg-  |
    """
    When I run the :describe client command with:
      | resource | secret              |
      | name     | default-dockercfg-  |
    Then the step should succeed
    And the output should match:
      | openshift.io/token-secret.name.*default-token- |

    When I run the :describe client command with:
      | resource | secret               |
      | name     | deployer-dockercfg-  |
    Then the step should succeed
    And the output should match:
      | openshift.io/token-secret.name.*deployer-token- |

    When I run the :describe client command with:
      | resource | secret               |
      | name     | builder-dockercfg-   |
    Then the step should succeed
    And the output should match:
      | openshift.io/token-secret.name.*builder-token- |

  # @author cryan@redhat.com
  # @case_id OCP-10784
  Scenario: Secret can be used to download dependency from private registry - custom build
    Given I have a project
    Given project role "system:build-strategy-custom" is added to the "first" user
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/tc519256/testsecret1.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/tc519256/testsecret2.json |
    Then the step should succeed
    When I process and create "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-custombuild.json"
    Then the step should succeed
    Given the "ruby-sample-build-1" build completes
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | ruby-sample-build |
      | p | {"spec": {"source": {"secrets":[{"secret":{"name":"testsecret1"}},{"secret":{"name":"testsecret2"}}]}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given the pod named "ruby-sample-build-2-build" status becomes :running
    When I run the :exec admin command with:
      | pod | ruby-sample-build-2-build |
      | n | <%= project.name %> |
      | exec_command | env |
    Then the output should contain:
      | testsecret1 |
      | testsecret2 |
    When I run the :exec admin command with:
      | pod | ruby-sample-build-2-build |
      | n | <%= project.name %> |
      | exec_command| ls |
      | exec_command_arg | /var/run/secrets/openshift.io/build |
    Then the output should contain:
      | testsecret1 |
      | testsecret2 |

  # @author xxia@redhat.com
  # @case_id OCP-12036
  Scenario: User can pull a private image from a docker registry when a pull secret is defined
    Given I have a project
    And I run the :new_build client command with:
      | app_repo | centos/ruby-25-centos7~https://github.com/openshift/ruby-hello-world |
      | name     | test |
    Then the step should succeed

    Given the "test-1" build completed
    # Get user1's image as private docker image. Format is like: 172.31.168.158:5000/<project>/<istream>
    Then evaluation of `image_stream("test").docker_image_repository(user: user)` is stored in the :user1_image clipboard

    Given I switch to the second user
    And I create a new project
    # Get user1's dockercfg as secret for user2
    When I run the :create_secret client command with:
      | secret_type  | docker-registry                                      |
      | name         | user1-dockercfg                                      |
      | docker_email | any@any.com                                          |
      # Get openshift docker registry. Format is like: 172.31.168.158:5000
      | docker_server      | <%= cb.user1_image[/[^\/]*/] %>                      |
      | docker_username    | <%= user(0, switch: false).name %>                   |
      | docker_password    | <%= user(0, switch: false).cached_tokens.first %> |
    Then the step should succeed

    When I run the :run client command with:
      | name      | frontend   |
      | image     | <%= cb.user1_image %>   |
      | dry_run   |            |
      | -o        | yaml       |
    Then the step should succeed
    And I save the output to file> dc.yaml

    When I run oc create with "dc.yaml" replacing paths:
      | ["spec"]["template"]["spec"]["containers"][0]["imagePullPolicy"] | Always                    |
      | ["spec"]["template"]["spec"]["imagePullSecrets"]                 | - name: user1-dockercfg   |
    Then the step should succeed

    Then a pod becomes ready with labels:
      | deploymentconfig=frontend |

  # @author xxia@redhat.com
  # @case_id OCP-11138
  Scenario: Deploy will fail with incorrently formed pull secrets
    Given I have a project
    And I run the :new_build client command with:
      | app_repo | centos/ruby-25-centos7~https://github.com/openshift/ruby-hello-world |
      | name     | test |
    Then the step should succeed

    Given the "test-1" build completed
    # Get user1's image as private docker image. Format is like: 172.31.168.158:5000/<project>/<istream>
    Then evaluation of `image_stream("test").docker_image_repository(user: user)` is stored in the :user1_image clipboard

    Given I switch to the second user
    And I create a new project

    When I run the :run client command with:
      | name      | frontend   |
      | image     | <%= cb.user1_image %>   |
      | dry_run   |            |
      | -o        | yaml       |
    Then the step should succeed
    And I save the output to file> dc.yaml

    # Not existent secret
    When I run oc create with "dc.yaml" replacing paths:
      | ["spec"]["template"]["spec"]["containers"][0]["imagePullPolicy"] | Always                    |
      | ["spec"]["template"]["spec"]["imagePullSecrets"]                 | - name: notexist-secret   |
    Then the step should succeed
    And I wait up to 300 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | pod     |
    Then the step should succeed
    And the output should match "frontend-1-.*(ImagePullBackOff|ErrImagePull)"
    """
    # TODO: check secrets "notexist-secret" not found?

    # Not matched secret
    When I run the :create_secret client command with:
      | secret_type | generic         |
      | name        | notmatch-secret |
      | from_file   | dc.yaml         |
    Then the step should succeed
    When I run oc create with "dc.yaml" replacing paths:
      | ["metadata"]["name"]                                             | newdc                     |
      | ["spec"]["template"]["spec"]["containers"][0]["imagePullPolicy"] | Always                    |
      | ["spec"]["template"]["spec"]["imagePullSecrets"]                 | - name: notmatch-secret   |
    Then the step should succeed
    And I wait up to 300 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | pod                |
    Then the step should succeed
    And the output should match "newdc-1-.*(ImagePullBackOff|ErrImagePull)"
    """
    When I run the :describe client command with:
      | resource      | pod       |
      | name          | newdc-1-  |
    Then the step should succeed

  # @author xiuwang@redhat.com
  # @case_id OCP-10702
  Scenario: Build from private repo with/without secret of token --ephemeral gitserver
    Given I have a project
    And I have an http-git service in the project
    When I run the :run client command with:
      | name  | gitserver                  |
      | image | openshift/origin-gitserver |
      | env   | GIT_HOME=/var/lib/git      |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role          | edit             |
      | serviceaccount| default          |
    Then the step should succeed

    #Create app when push code to initial repo
    And a pod becomes ready with labels:
      | run=gitserver|
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      |bash|
      |-c  |
      |sed -i '1,2d' /var/lib/gitconfig/.gitconfig|
    Then the step should succeed
    """
    When I execute on the pod:
      |bash|
      |-c  |
      |git config --global credential.http://<%= cb.git_route%>.helper '!f() { echo "username=<%= @user.name %>"; echo "password=<%= user.cached_tokens.first %>"; }; f'|
    Then the step should succeed
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/ ;git clone https://github.com/openshift/ruby-hello-world.git|
    Then the step should succeed
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/ruby-hello-world/;git remote add openshift http://<%= cb.git_route%>/ruby-hello-world.git|
    Then the step should succeed
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/ruby-hello-world/;git push openshift master|
    Then the step should succeed
    And the output should contain:
      |buildconfig "ruby-hello-world" created|
    And the "ruby-hello-world-1" build was created
    Then I run the :delete client command with:
      | object_type       | builds             |
      | object_name_or_id | ruby-hello-world-1 |
    Then the step should succeed

    #Disable anonymous cloning
    When I run the :set_env client command with:
      | resource | dc/git                    |
      | e        | ALLOW_ANON_GIT_PULL=false |
    Then the step should succeed
    When I run the :secrets_new_basicauth client command with:
      |secret_name |mysecret                          |
      |password    |<%= user.cached_tokens.first %>|
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | buildconfig      |
      | resource_name | ruby-hello-world |
      | p | {"spec": {"source": {"sourceSecret": {"name": "mysecret"}}}} |
    Then the step should succeed

    #Trigger second build automaticlly with secret
    And a pod becomes ready with labels:
      | deploymentconfig=git |
      | deployment=git-2     |
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      |bash|
      |-c  |
      |sed -i '1,2d' /var/lib/gitconfig/.gitconfig|
    Then the step should succeed
    """
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/;git clone http://<%= cb.git_route%>/ruby-hello-world.git|
    Then the step should fail
    And the output should contain:
      |fatal: could not read Username|
    And a pod becomes ready with labels:
      | run=gitserver|
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/ruby-hello-world/;touch testfile;git add .;git commit -amp;git push openshift master|
    Then the step should succeed
    And the output should contain:
      |started on build configuration 'ruby-hello-world'|
    Given I get project builds
    Then the output should contain "ruby-hello-world-2"
    Given the "ruby-hello-world-2" build completes

    #Trigger third build automaticlly with incorrect secret
    When I run the :secrets_new_basicauth client command with:
      |secret_name |mysecret2     |
      |password    |incorrecttoken|
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | buildconfig      |
      | resource_name | ruby-hello-world |
      | p | {"spec": {"source": {"sourceSecret": {"name": "mysecret2"}}}} |
    Then the step should succeed
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/ruby-hello-world/;touch testfile1;git add .;git commit -amp;git push openshift master|
    Then the step should succeed
    And the output should contain:
      |started on build configuration 'ruby-hello-world'|
    Given I get project builds
    Then the output should contain "ruby-hello-world-3"
    Given the "ruby-hello-world-3" build fails

  # @author xiuwang@redhat.com
  # @case_id OCP-11523
  Scenario: Build from private repo with/without secret of gitconfig auth method
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cases/508964/.gitconfig"
    When I run the :new_secret client command with:
      |secret_name     |mysecret  |
      |credential_file |.gitconfig|
    Then the step should succeed
    And I replace lines in ".gitconfig":
      |redhat|<%= user.cached_tokens.first %>|
    When I run the :new_secret client command with:
      |secret_name     |mysecret1  |
      |credential_file |.gitconfig|
    Then the step should succeed
    And I have an http-git service in the project
    When I run the :run client command with:
      | name  | gitserver                  |
      | image | openshift/origin-gitserver |
      | env   | GIT_HOME=/var/lib/git      |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role          | edit    |
      | serviceaccount| default |
    Then the step should succeed

    #Create app when push code to initial repo
    And a pod becomes ready with labels:
      | run=gitserver|
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      |bash|
      |-c  |
      |sed -i '1,2d' /var/lib/gitconfig/.gitconfig|
    Then the step should succeed
    """
    When I execute on the pod:
      |bash|
      |-c  |
      |git config --global credential.http://<%= cb.git_route%>.helper '!f() { echo "username=<%= @user.name %>"; echo "password=<%= user.cached_tokens.first %>"; }; f'|
    Then the step should succeed
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/ ;git clone https://github.com/openshift/ruby-hello-world.git|
    Then the step should succeed
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/ruby-hello-world/;git remote add openshift http://<%= cb.git_route%>/ruby-hello-world.git|
    Then the step should succeed
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/ruby-hello-world/;git push openshift master|
    Then the step should succeed
    And the output should contain:
      |buildconfig "ruby-hello-world" created|
    Then I run the :delete client command with:
      | object_type       | builds             |
      | object_name_or_id | ruby-hello-world-1 |
    Then the step should succeed

    #Trigger second build automaticlly with secret
    When I run the :set_env client command with:
      | resource | dc/git                    |
      | e        | ALLOW_ANON_GIT_PULL=false |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | buildconfig      |
      | resource_name | ruby-hello-world |
      | p | {"spec": {"source": {"sourceSecret": {"name": "mysecret1"}}}} |
    Then the step should succeed

    And a pod becomes ready with labels:
      | deploymentconfig=git |
      | deployment=git-2     |
    And a pod becomes ready with labels:
      | run=gitserver|
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/ruby-hello-world/;touch testfile;git add .;git commit -amp;git push openshift master|
    Then the step should succeed
    And the output should contain:
      |started on build configuration 'ruby-hello-world'|
    Given I get project builds
    Then the output should contain "ruby-hello-world-2"
    Given the "ruby-hello-world-2" build completes

    When I run the :set_env client command with:
      | resource | dc/git                |
      | e        | REQUIRE_SERVER_AUTH=  |
      | e        | REQUIRE_GIT_AUTH=openshift:redhat |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deploymentconfig=git |
      | deployment=git-3     |
    When I run the :patch client command with:
      | resource      | buildconfig      |
      | resource_name | ruby-hello-world |
      | p | {"spec": {"source": {"sourceSecret": {"name": "mysecret"}}}} |
    Then the step should succeed
    And a pod becomes ready with labels:
      | run=gitserver|
    When I execute on the pod:
      |bash|
      |-c  |
      |git config --global credential.http://<%= cb.git_route%>.helper '!f() { echo "username=openshift"; echo "password=redhat"; }; f'|
    Then the step should succeed
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/ruby-hello-world/;touch testfile1;git add .;git commit -amp;git push openshift master|
    Then the step should succeed
    And the output should contain:
      |started on build configuration 'ruby-hello-world'|
    Given I get project builds
    Then the output should contain "ruby-hello-world-3"
    Given the "ruby-hello-world-3" build completes

  # @author xiuwang@redhat.com
  # @case_id OCP-11750
  Scenario: Build from private repo with/without secret of password with http --gitserver
    Given I have a project
    And I have an http-git service in the project
    When I run the :run client command with:
      | name  | gitserver                  |
      | image | openshift/origin-gitserver |
      | env   | GIT_HOME=/var/lib/git      |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role          | edit    |
      | serviceaccount| default |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | dc/git                |
      | e        | REQUIRE_SERVER_AUTH=  |
      | e        | REQUIRE_GIT_AUTH=openshift:redhat |
      | e        | BUILD_STRATEGY=source |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deploymentconfig=git |
      | deployment=git-2     |

    #Create app when push code to initial repo
    And a pod becomes ready with labels:
      | run=gitserver|
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      |bash|
      |-c  |
      |sed -i '1,2d' /var/lib/gitconfig/.gitconfig|
    Then the step should succeed
    """
    When I execute on the pod:
      |bash|
      |-c  |
      |git config --global credential.http://<%= cb.git_route%>.helper '!f() { echo "username=openshift"; echo "password=redhat"; }; f'|
    Then the step should succeed
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/ ;git clone https://github.com/openshift/ruby-hello-world.git|
    Then the step should succeed
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/ruby-hello-world/;git remote add openshift http://<%= cb.git_route%>/ruby-hello-world.git|
    Then the step should succeed
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/ruby-hello-world/;git push openshift master|
    Then the step should succeed
    And the output should contain:
      |buildconfig "ruby-hello-world" created|
    Then I run the :delete client command with:
      | object_type       | builds             |
      | object_name_or_id | ruby-hello-world-1 |
    Then the step should succeed

    #Disable anonymous cloning
    When I run the :set_env client command with:
      | resource | dc/git                    |
      | e        | ALLOW_ANON_GIT_PULL=false |
    Then the step should succeed
    When I run the :secrets_new_basicauth client command with:
      |secret_name |mysecret |
      |username    |openshift|
      |password    |redhat   |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | buildconfig      |
      | resource_name | ruby-hello-world |
      | p | {"spec": {"source": {"sourceSecret": {"name": "mysecret"}}}} |
    Then the step should succeed

    #Trigger second build automaticlly with secret
    And a pod becomes ready with labels:
      | deploymentconfig=git |
      | deployment=git-3     |
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      |bash|
      |-c  |
      |sed -i '1,2d' /var/lib/gitconfig/.gitconfig|
    Then the step should succeed
    """
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/;git clone http://<%= cb.git_route%>/ruby-hello-world.git|
    Then the step should fail
    And the output should contain:
      |fatal: could not read Username|
    And a pod becomes ready with labels:
      | run=gitserver|
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/ruby-hello-world/;touch testfile;git add .;git commit -amp;git push openshift master|
    Then the step should succeed
    And the output should contain:
      |started on build configuration 'ruby-hello-world'|
    Given I get project builds
    Then the output should contain "ruby-hello-world-2"
    Given the "ruby-hello-world-2" build completes

    #Trigger third build automaticlly with password alone
    When I run the :secrets_new_basicauth client command with:
      |secret_name |mysecret2 |
      |password    |redhat    |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | buildconfig      |
      | resource_name | ruby-hello-world |
      | p | {"spec": {"source": {"git": {"uri": "http://openshift@git:8080/ruby-hello-world.git"},"sourceSecret": {"name": "mysecret2"}}}} |
    Then the step should succeed
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/ruby-hello-world/;touch testfile2;git add .;git commit -amp;git push openshift master|
    Then the step should succeed
    And the output should contain:
      |started on build configuration 'ruby-hello-world'|
    Given I get project builds
    Then the output should contain "ruby-hello-world-3"
    Given the "ruby-hello-world-3" build completes

    #Trigger build automaticlly with username alone
    When I run the :secrets_new_basicauth client command with:
      |secret_name |mysecret3 |
      |username    |openshift |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | buildconfig      |
      | resource_name | ruby-hello-world |
      | p | {"spec": {"source": {"git": {"uri": "http://git:8080/ruby-hello-world.git"},"sourceSecret": {"name": "mysecret3"}}}} |
    Then the step should succeed
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/ruby-hello-world/;touch testfile3;git add .;git commit -amp;git push openshift master|
    Then the step should succeed
    And the output should contain:
      |started on build configuration 'ruby-hello-world'|
    Given I get project builds
    Then the output should contain "ruby-hello-world-4"
    Given the "ruby-hello-world-4" build fails

    #Trigger build automaticlly with invaild password
    When I run the :secrets_new_basicauth client command with:
      |secret_name |mysecret4 |
      |username    |openshift |
      |password    |invaild   |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | buildconfig      |
      | resource_name | ruby-hello-world |
      | p | {"spec": {"source": {"sourceSecret": {"name": "mysecret4"}}}} |
    Then the step should succeed
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/ruby-hello-world/;touch testfile4;git add .;git commit -amp;git push openshift master|
    Then the step should succeed
    And the output should contain:
      |started on build configuration 'ruby-hello-world'|
    Given I get project builds
    Then the output should contain "ruby-hello-world-5"
    Given the "ruby-hello-world-5" build fails

  # @author wehe@redhat.com
  # @case_id OCP-10170
  Scenario: Consume secret via volume plugin with multiple volumes
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/secret.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | secret      |
      | name     | test-secret |
    Then the output should match:
      | data-1:\\s+9\\s+bytes  |
      | data-2:\\s+11\\s+bytes |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/pod-multi-volume.yaml |
    Then the step should succeed
    And the pod named "multiv-secret-pod" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | multiv-secret-pod |
    Then the step should succeed
    And the output should contain:
      | value-1              |
      | secret-volume/data-1 |

  # @author wehe@redhat.com
  # @case_id OCP-10169
  Scenario: Consume same name secretes via volume plugin in different namespaces
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/secret.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | secret      |
      | name     | test-secret |
    Then the output should match:
      | data-1:\\s+9\\s+bytes  |
      | data-2:\\s+11\\s+bytes |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/secret-pod.yaml |
    Then the step should succeed
    And the pod named "secret-test-pod" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | secret-test-pod |
    Then the step should succeed
    And the output should contain:
      | value-1              |
      | secret-volume/data-1 |
    Given I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/secret.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | secret      |
      | name     | test-secret |
    Then the output should match:
      | data-1:\\s+9\\s+bytes  |
      | data-2:\\s+11\\s+bytes |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/secret-pod.yaml |
    Then the step should succeed
    And the pod named "secret-test-pod" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | secret-test-pod |
    Then the step should succeed
    And the output should contain:
      | value-1              |
      | secret-volume/data-1 |

  # @author yinzhou@redhat.com
  # @case_id OCP-11905
  Scenario: Use well-formed pull secret with incorrect credentials will fail to build and deploy
    Given I have a project
    And I run the :new_build client command with:
      | app_repo | centos/ruby-25-centos7~https://github.com/openshift/ruby-hello-world |
      | name     | test |
    Then the step should succeed

    Given the "test-1" build completed
    # Get user1's image as private docker image. Format is like: 172.31.168.158:5000/<project>/<istream>
    Then evaluation of `image_stream("test").docker_image_repository(user: user)` is stored in the :user1_image clipboard

    Given I switch to the second user
    And I create a new project

    When I run the :run client command with:
      | name      | frontend   |
      | image     | <%= cb.user1_image %>   |
      | dry_run   |            |
      | -o        | yaml       |
    Then the step should succeed
    And I save the output to file> dc.yaml

    # Use well-formed pull secret with incorrect credentials
    Given default registry service ip is stored in the :integrated_reg_ip clipboard
    When I run the :create_secret client command with:
      | secret_type      | docker-registry             |
      | name             | test                        |
      | docker_email     | serviceaccount@redhat.com   |
      | docker_password  | password                    |
      | docker_server    | <%= cb.integrated_reg_ip %> |
      | docker_username  | username                    |
    Then the step should succeed

    When I run oc create with "dc.yaml" replacing paths:
      | ["spec"]["template"]["spec"]["containers"][0]["imagePullPolicy"] | Always       |
      | ["spec"]["template"]["spec"]["imagePullSecrets"]                 | - name: test |
    Then the step should succeed
    And I wait up to 300 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | pod     |
    Then the step should succeed
    And the output should match "frontend-1-.*(ImagePullBackOff|ErrImagePull)"
    """

  # @author weinliu@redhat.com
  # @case_id OCP-10797
  Scenario: secret subcommand - docker-registry
    Given I have a project
    When I run the :create_secret client command with:
      | secret_type     | docker-registry              |
      | name            | secret1-with-docker-registry |
      | docker_server   | https://hub.docker.com       |
      | docker_username | weinliu                      |
      | docker_password | my_passwd                    |
      | docker_email    | weinliu@redhat.com           |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | secret                       |
      | name     | secret1-with-docker-registry |
    Then the output should match:
      | kubernetes\.io/(dockercfg\|dockerconfigjson) |

    #Step 2. --dry-run
    When I run the :create_secret client command with:
      | secret_type     | docker-registry        |
      | name            | secret2-dryrun         |
      | docker_server   | https://hub.docker.com |
      | docker_username | weinliu                |
      | docker_password | my_passwd              |
      | docker_email    | weinliu@redhat.com     |
      | dry_run         | true                   |
    Then the output should match:
      | secret.*created.*dry.*run.* |
    And the secret named "secret2-dryrun" does not exist in the project

    #Step 3. --generator
    When I run the :create_secret client command with:
      | secret_type     | docker-registry               |
      | name            | secret3-1-generator           |
      | docker_server   | https://hub.docker.com        |
      | docker_username | weinliu                       |
      | docker_password | my_passwd                     |
      | docker_email    | weinliu@redhat.com            |
      | generator       | secret-for-docker-registry/v3 |
    Then the output should match:
      | error.*Generator.*v3.*not.*supported |
    When I run the :create_secret client command with:
      | secret_type     | docker-registry               |
      | name            | secret3-2-generator           |
      | docker_server   | https://hub.docker.com        |
      | docker_username | weinliu                       |
      | docker_password | my_passwd                     |
      | docker_email    | weinliu@redhat.com            |
      | generator       | secret-for-docker-registry/v1 |
    Then the output should match:
      | secret.*created |

    #Step 4. --output
    When I run the :create_secret client command with:
      | secret_type     | docker-registry               |
      | name            | secret4-1-output              |
      | docker_server   | https://hub.docker.com        |
      | docker_username | weinliu                       |
      | docker_password | my_passwd                     |
      | docker_email    | weinliu@redhat.com            |
      | output          | json                          |
    Then the output should contain:
      | "kind": "Secret" |
    And I wait for the "secret4-1-output" secret to appear
    When I run the :create_secret client command with:
      | secret_type     | docker-registry        |
      | name            | secret4-2-output       |
      | docker_server   | https://hub.docker.com |
      | docker_username | weinliu                |
      | docker_password | my_passwd              |
      | docker_email    | weinliu@redhat.com     |
      | output          | yaml                   |
    Then the output should contain:
      | kind: Secret |
    And I wait for the "secret4-2-output" secret to appear

    #Step 6. --save-config
    When I run the :create_secret client command with:
      | secret_type     | docker-registry        |
      | name            | secret6-save-config    |
      | docker_server   | https://hub.docker.com |
      | docker_username | weinliu                |
      | docker_password | my_passwd              |
      | docker_email    | weinliu@redhat.com     |
      | save_config     | true                   |
    And I run the :get client command with:
      | resource      | secret              |
      | resource_name | secret6-save-config |
      | o             | yaml                |
    Then the output should contain:
      | kubectl.kubernetes.io/last-applied-configuration |

  # @author weinliu@redhat.com
  # @case_id OCP-11246
  Scenario: secret subcommand - generic
    Given I have a project
    Given I create the "testfolder" directory
    #Step 1.Create a new secret based on a directory
    Given a "testfolder/file1" file is created with the following lines:
      """
      1
      """
    Then the step should succeed
    Given a "testfolder/file2" file is created with the following lines:
      """
      2
      """
    Then the step should succeed
    Given a "testfolder/file3" file is created with the following lines:
      """
      3
      """
    Then the step should succeed
    When I run the :create_secret client command with:
      | secret_type | generic          |
      | name        |secret1-from-file |
      | from_file   |./testfolder      |
    Then the step should succeed
    And the expression should be true> secret("secret1-from-file").value_of("file1") == "1"
    And the expression should be true> secret("secret1-from-file").value_of("file2") == "2"
    And the expression should be true> secret("secret1-from-file").value_of("file3") == "3"

    #Step 2.Create a new secret based on a file
    Given I create the "testfolder2" directory
    And a "testfolder2/file4" file is created with the following lines:
      """
      1234
      """
    Then the step should succeed
    When I run the :create_secret client command with:
      | secret_type | generic          |
      | name        |secret2-from-file |
      | from_file   | ./testfolder2    |
    Then the step should succeed
    And the expression should be true> secret("secret2-from-file").value_of("file4") == "1234"
    #Step 3. Create a new secret with specified keys instead of names on disk
    Given a "testfolder2/id_rsa" file is created with the following lines:
      """
      key12345
      """
    Then the step should succeed
    Given a "testfolder2/id_rsa.pub" file is created with the following lines:
      """
      key6789012
      """
    Then the step should succeed
    When I run the :create_secret client command with:
      | secret_type | generic                                |
      | name        | secret3-from-file                      |
      | from_file   | ssh-privatekey=./testfolder2/id_rsa    |
      | from_file   | ssh-publickey=./testfolder2/id_rsa.pub |
    And the expression should be true> secret("secret3-from-file").value_of("ssh-privatekey") == "key12345"
    And the expression should be true> secret("secret3-from-file").value_of("ssh-publickey") == "key6789012"

    #Step 4. --from-literal
    When I run the :create_secret client command with:
      | secret_type  | generic              |
      | name         | secret4-from-literal |
      | from_literal | key1=abc             |
      | from_literal | key2=adbdefg         |
    Then the expression should be true> secret("secret4-from-literal").value_of("key1") == "abc"
    And the expression should be true> secret("secret4-from-literal").value_of("key2") == "adbdefg"

    #Step 5. --dry-run
    When I run the :create_secret client command with:
      | secret_type  | generic         |
      | name         | secret5-dry-run |
      | from_literal | key3=aaa        |
      | dry_run      | true            |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | secret          |
      | resource_name | secret5-dry-run |
    Then the step should fail

    #Step 6. --generator
    When I run the :create_secret client command with:
      | secret_type  | generic             |
      | name         | secret6-1-generator |
      | from_literal | key1=aaa            |
      | generator    | secret/v2           |
    Then the step should fail
    When I run the :create_secret client command with:
      | secret_type  | generic             |
      | name         | secret6-2-generator |
      | from_literal | key1=aaa            |
      | generator    | secret/v1           |
    Then the step should succeed

    #Step 7. --output
    # --output=json
    When I run the :create_secret client command with:
      | secret_type  | generic          |
      | name         | secret7-1-output |
      | from_literal | key1=aaa         |
      | output       | json             |
    Then the output should contain:
      | "kind": "Secret" |
    And I wait for the "secret7-1-output" secret to appear
    # --output=yaml
    When I run the :create_secret client command with:
      | secret_type  | generic          |
      | name         | secret7-2-output |
      | from_literal | key1=aaa         |
      | output       | yaml             |
    Then the output should contain:
      | kind: Secret |
    Then the output should not contain:
        | { |
    And I wait for the "secret7-2-output" secret to appear
    # --output=wide
    When I run the :create_secret client command with:
      | secret_type  | generic          |
      | name         | secret7-3-output |
      | from_literal | key1=aaa         |
      | output       | wide             |
    Then the output should contain:
      | NAME |
      | TYPE |
      | DATA |
      | AGE  |
    And I wait for the "secret7-3-output" secret to appear
    # --output=name
    When I run the :create_secret client command with:
      | secret_type  | generic          |
      | name         | secret7-4-output |
      | from_literal | key1=aaa         |
      | output       | name             |
    Then the output should contain:
      | secret/secret7-4-output |
    And I wait for the "secret7-4-output" secret to appear

    #Step 9. --save-config
    When I run the :create_secret client command with:
      | secret_type  | generic             |
      | name         | secret9-save-config |
      | from_literal | key1=aaa            |
      | save_config  | true                |
    And I run the :get client command with:
      | resource      | secret              |
      | resource_name | secret9-save-config |
      | o             | yaml                |
    Then the output should contain:
      | kubectl.kubernetes.io/last-applied-configuration |

    #Step 12. --type
    When I run the :create_secret client command with:
      | secret_type  | generic           |
      | name         | secret12-validate |
      | from_literal | key1=aaa          |
      | type         | Opaque            |
    Then the expression should be true> secret("secret12-validate").type == "Opaque"
    When I run the :create_secret client command with:
      | secret_type  | generic           |
      | name         | secret13-validate |
      | from_literal | key1=aaa          |
      | type         | dockercfg         |
    Then the expression should be true> secret("secret13-validate").type == "dockercfg"

  # @author xiuwang@redhat.com
  # @case_id OCP-14264
  Scenario: Use build source secret based on annotation on Secret --ssh
    Given I have a project
    When I have an ssh-git service in the project
    And the "secret" file is created with the following lines:
      | <%= cb.ssh_private_key.to_pem %> |
    And I run the :create_secret client command with:
      | secret_type | generic               |   
      | name        | sshsecret             |   
      | from_file   | ssh-privatekey=secret |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | secret                                                                         |
      | resourcename | sshsecret                                                                      |
      | keyval       | build.openshift.io/source-secret-match-uri-1=ssh://<%= cb.git_pod_ip_port %>/* |
    Then the step should succeed
    When I execute on the pod:
      | bash                                                                                                             |
      | -c                                                                                                               |
      | cd /repos/ && rm -rf sample.git && git clone --bare https://github.com/openshift/ruby-hello-world.git sample.git |
    Then the step should succeed
    When I run the :new_app client command with:
      | app_repo | ruby~<%= cb.git_repo_pod %> |
      | l        | app=newapp1                 |
    Then the step should succeed
    When I get project buildconfig as YAML
    And the output should match:
      | sourceSecret    |
      | name: sshsecret |
    Given the "sample-1" build completed
    When I run the :delete client command with:
      | all_no_dash |             |
      | l           | app=newapp1 |
    Then the step should succeed
    When I run the :new_build client command with:
      | app_repo | ruby~<%= cb.git_repo_pod %> |
    Then the step should succeed
    When I get project buildconfig as YAML
    And the output should match:
      | sourceSecret    |
      | name: sshsecret |
    Given the "sample-1" build completed

  # @author minmli@redhat.com
  # @case_id OCP-20859
  Scenario: secret subcommand - generic for 3.11
    Given I have a project
    Given I create the "testfolder" directory
    #Step 1.Create a new secret based on a directory
    Given a "testfolder/file1" file is created with the following lines:
      """
      1
      """
    Then the step should succeed
    Given a "testfolder/file2" file is created with the following lines:
      """
      2
      """
    Then the step should succeed
    Given a "testfolder/file3" file is created with the following lines:
      """
      3
      """
    Then the step should succeed
    When I run the :create_secret client command with:
      | secret_type | generic          |
      | name        |secret1-from-file |
      | from_file   |./testfolder      |
    Then the step should succeed
    And the expression should be true> secret("secret1-from-file").value_of("file1") == "1"
    And the expression should be true> secret("secret1-from-file").value_of("file2") == "2"
    And the expression should be true> secret("secret1-from-file").value_of("file3") == "3"

    #Step 2.Create a new secret based on a file
    Given I create the "testfolder2" directory
    And a "testfolder2/file4" file is created with the following lines:
      """
      1234
      """
    Then the step should succeed
    When I run the :create_secret client command with:
      | secret_type | generic          |
      | name        |secret2-from-file |
      | from_file   | ./testfolder2    |
    Then the step should succeed
    And the expression should be true> secret("secret2-from-file").value_of("file4") == "1234"
    #Step 3. Create a new secret with specified keys instead of names on disk
    Given a "testfolder2/id_rsa" file is created with the following lines:
      """
      key12345
      """
    Then the step should succeed
    Given a "testfolder2/id_rsa.pub" file is created with the following lines:
      """
      key6789012
      """
    Then the step should succeed
    When I run the :create_secret client command with:
      | secret_type | generic                                |
      | name        | secret3-from-file                      |
      | from_file   | ssh-privatekey=./testfolder2/id_rsa    |
      | from_file   | ssh-publickey=./testfolder2/id_rsa.pub |
    And the expression should be true> secret("secret3-from-file").value_of("ssh-privatekey") == "key12345"
    And the expression should be true> secret("secret3-from-file").value_of("ssh-publickey") == "key6789012"

    #Step 4. --from-literal
    When I run the :create_secret client command with:
      | secret_type  | generic              |
      | name         | secret4-from-literal |
      | from_literal | key1=abc             |
      | from_literal | key2=adbdefg         |
    Then the expression should be true> secret("secret4-from-literal").value_of("key1") == "abc"
    And the expression should be true> secret("secret4-from-literal").value_of("key2") == "adbdefg"

    #Step 5. --dry-run
    When I run the :create_secret client command with:
      | secret_type  | generic         |
      | name         | secret5-dry-run |
      | from_literal | key3=aaa        |
      | dry_run      | true            |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | secret          |
      | resource_name | secret5-dry-run |
    Then the step should fail

    #Step 6. --generator
    When I run the :create_secret client command with:
      | secret_type  | generic             |
      | name         | secret6-1-generator |
      | from_literal | key1=aaa            |
      | generator    | secret/v2           |
    Then the step should fail
    When I run the :create_secret client command with:
      | secret_type  | generic             |
      | name         | secret6-2-generator |
      | from_literal | key1=aaa            |
      | generator    | secret/v1           |
    Then the step should succeed

    #Step 7. --output
    # --output=json
    When I run the :create_secret client command with:
      | secret_type  | generic          |
      | name         | secret7-1-output |
      | from_literal | key1=aaa         |
      | output       | json             |
    Then the output should contain:
      | "kind": "Secret" |
    And I wait for the "secret7-1-output" secret to appear
    # --output=yaml
    When I run the :create_secret client command with:
      | secret_type  | generic          |
      | name         | secret7-2-output |
      | from_literal | key1=aaa         |
      | output       | yaml             |
    Then the output should contain:
      | kind: Secret |
    Then the output should not contain:
        | { |
    And I wait for the "secret7-2-output" secret to appear
    # --output=name
    When I run the :create_secret client command with:
      | secret_type  | generic          |
      | name         | secret7-4-output |
      | from_literal | key1=aaa         |
      | output       | name             |
    Then the output should contain:
      | secret/secret7-4-output |
    And I wait for the "secret7-4-output" secret to appear

    #Step 9. --save-config
    When I run the :create_secret client command with:
      | secret_type  | generic             |
      | name         | secret9-save-config |
      | from_literal | key1=aaa            |
      | save_config  | true                |
    And I run the :get client command with:
      | resource      | secret              |
      | resource_name | secret9-save-config |
      | o             | yaml                |
    Then the output should contain:
      | kubectl.kubernetes.io/last-applied-configuration |

    #Step 12. --type
    When I run the :create_secret client command with:
      | secret_type  | generic           |
      | name         | secret12-validate |
      | from_literal | key1=aaa          |
      | type         | Opaque            |
    Then the expression should be true> secret("secret12-validate").type == "Opaque"
    When I run the :create_secret client command with:
      | secret_type  | generic           |
      | name         | secret13-validate |
      | from_literal | key1=aaa          |
      | type         | dockercfg         |
    Then the expression should be true> secret("secret13-validate").type == "dockercfg"

