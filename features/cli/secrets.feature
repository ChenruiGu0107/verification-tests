Feature: secrets related scenarios
  # @author pruan@redhat.com
  # @case_id 484328
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
  # @case_id 490966
  Scenario: Generate dockercfg type secrets via oc secrets new-dockercfg
    Given I have a project
    When I run the :oc_secrets_new_dockercfg client command with:
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
    And the output should contain:
      |kubernetes.io/dockercfg|
      
  # @author xiacwan@redhat.com
  # @case_id 484337
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
    When I run the :secrets admin command with:
      | action | new                                                    |
      | name   | <%= "secret2"+project.name %>                          |
      | source | myquota.yaml |
      | n        | <%= project.name %> |
    Then the step should not succeed
    And the output should contain:
      |  limit |

  # @author yinzhou@redhat.com
  # @case_id 510612
  Scenario: deployment hook volume inheritance --with secret volume
    Given I have a project
    When I run the :secrets client command with:
      | action | new        |
      | name   | my-secret  |
      | source | /etc/hosts |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/tc510612/hook-inheritance-secret-volume.json |
    Then the step should succeed
  ## mount should be correct to the pod, no-matter if the pod is completed or not, check the case checkpoint
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource  | pod  |
      | resource_name | hooks-1-hook-pre |
      |  o        | yaml |
    Then the output by order should match:
      | - mountPath: /opt1    |
      | name: secret          |
      | secretName: my-secret |
    """

  # @author xiuwang@redhat.com
  # @case_id 508970
  Scenario: Create new secrets for basic authentication
    Given I have a project
    When I run the :oc_secrets_new_basicauth client command with:
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
    When I run the :oc_secrets_new_basicauth client command with:
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
    When I run the :oc_secrets_new_basicauth client command with:
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

  # @author xiuwang@redhat.com
  # @case_id 508971
  Scenario: Create new secrets for ssh authentication
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cases/508971/id_rsa"
    When I run the :oc_secrets_new_sshauth client command with:
      |secret_name    |testsecret |
      |ssh_privatekey |id_rsa     |
    Then the step should succeed
    When I run the :get client command with:
      |resource      |secrets    |
      |resource_name |testsecret |
      |o             |yaml       |
    Then the step should succeed
    And the output should contain:
      |ssh-privatekey:|
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cases/508970/ca.crt"
    When I run the :oc_secrets_new_sshauth client command with:
      |secret_name    |testsecret2 |
      |ssh_privatekey |id_rsa      |
      |cafile         |ca.crt      |
    Then the step should succeed
    When I run the :get client command with:
      |resource      |secrets     |
      |resource_name |testsecret2 |
      |o             |yaml        |
    Then the step should succeed
    And the output should contain:
      |ssh-privatekey:|
      |ca.crt:        |


  # @author qwang@redhat.com
  # @case_id 483168
  Scenario: Pods do not have access to each other's secrets in the same namespace
    Given I have a project
    When I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/tc483168/first-secret.json |
    And I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/tc483168/second-secret.json |
    Then the step should succeed
    When I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/tc483168/first-secret-pod.yaml |
    And I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/tc483168/second-secret-pod.yaml |
    Then the step should succeed
    Given the pod named "first-secret-pod" status becomes :running
    When I run the :exec client command with:
      | pod              | first-secret-pod            |
      | exec_command     | cat                         |
      | exec_command_arg | /etc/secret-volume/username |
    Then the output should contain:
      | first-username |
    When I run the :exec client command with:
      | pod              | first-secret-pod            |
      | exec_command     | cat                         |
      | exec_command_arg | /etc/secret-volume/password |
    Then the output should contain:
      | password-first |
    Given the pod named "second-secret-pod" status becomes :running
    When I run the :exec client command with:
      | pod              | second-secret-pod           |
      | exec_command     | cat                         |
      | exec_command_arg | /etc/secret-volume/username |
    Then the output should contain:
      | second-username |
    When I run the :exec client command with:
      | pod              | second-secret-pod           |
      | exec_command     | cat                         |
      | exec_command_arg | /etc/secret-volume/password |
    Then the output should contain:
      | password-second |



  # @author xxia@redhat.com
  # @case_id 491403
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
    And the output should contain:
      | openshift.io/token-secret.name=default-token- |

    When I run the :describe client command with:
      | resource | secret               |
      | name     | deployer-dockercfg-  |
    Then the step should succeed
    And the output should contain:
      | openshift.io/token-secret.name=deployer-token- |

    When I run the :describe client command with:
      | resource | secret               |
      | name     | builder-dockercfg-   |
    Then the step should succeed
    And the output should contain:
      | openshift.io/token-secret.name=builder-token- |

  # @author cryan@redhat.com
  # @case_id 519256
  @admin
  Scenario: Secret can be used to download dependency from private registry - custom build
    Given I have a project
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

  # @author qwang@redhat.com
  # @case_id 483169
  Scenario: Pods do not have access to each other's secrets with the same secret name in different namespaces
    Given I have a project
    When I run the :create client command with:
      | filename  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/tc483169/secret1.json |
    And I run the :create client command with:
      | filename  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/tc483169/secret-pod-1.yaml |
    Then the step should succeed
    And the pod named "secret-pod-1" status becomes :running
    When I create a new project
    And I run the :create client command with:
      | filename  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/tc483169/secret2.json |
    And I run the :create client command with:
      | filename  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/tc483169/secret-pod-2.yaml |
    Then the step should succeed
    And the pod named "secret-pod-2" status becomes :running
    When I run the :exec client command with:
      | pod              | secret-pod-2                  |
      | exec_command     | cat                           |
      | exec_command_arg | /etc/secret-volume-2/password |
      | namespace        | <%= project(1).name %>        |
    Then the output should contain:
      | password-second |
    When I run the :exec client command with:
      | pod              | secret-pod-1                  |
      | exec_command     | cat                           |
      | exec_command_arg | /etc/secret-volume-1/username |
      | namespace        | <%= project(0).name %>        |
    Then the output should contain:
      | first-username |
