Feature: Testing registry

  # @author: yinzhou@redhat.com
  # @case_id: OCP-10010
  Scenario: Re-using the Registry IP address
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I store master image version in the clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=docker-registry |
    Given default docker-registry replica count is restored after scenario
    And admin ensures "tc-528303" dc is deleted after scenario
    And admin ensures "tc-528303" service is deleted after scenario
    When I run the :scale client command with:
      | resource | dc |
      | name | docker-registry |
      | replicas | 0 |
    Then the step should succeed
    When I run the :oadm_registry admin command with:
      | images | <%= product_docker_repo %>openshift3/ose-docker-registry:<%= cb.master_version %> |
      | volume | /registrytest |
      | stats_user | tc528303 |
      | stats_passwd | 483532tc |
      | service_account | router |
    And a pod becomes ready with labels:
      | deploymentconfig=tc-528303 |
    Given I switch to the first user
    And I have a project
    When I run the :new_build client command with:
      | app_repo | centos/ruby-22-centos7~https://github.com/openshift/ruby-ex.git |
    Then the step should succeed
    And the "ruby-ex-1" build was created
    Given the "ruby-ex-1" build completes

  # @author haowang@redhat.com
  # @case_id OCP-10015
  @admin
  @destructive
  Scenario: Docker-registry with whitelist
    Given I have a project
    And I select a random node's host
    Given the node service is verified
    And the node service is restarted on the host after scenario
    And I register clean-up steps:
    """
    And I run commands on the host:
      | systemctl restart docker |
    Then the step should succeed
    """
    And the "/etc/sysconfig/docker" file is restored on host after scenario
    And I run commands on the host:
      | sed -i '/^BLOCK_REGISTRY*/d' /etc/sysconfig/docker |
    Then the step should succeed
    And I run commands on the host:
      | sed -i '/^*ADD_REGISTRY/d' /etc/sysconfig/docker |
    Then the step should succeed
    And I run commands on the host:
      | echo "BLOCK_REGISTRY='--block-registry=all'" >> /etc/sysconfig/docker |
    Then the step should succeed
    And I run commands on the host:
      | systemctl restart docker |
    Then the step should succeed
    And I run commands on the host:
      | docker pull docker.io/library/centos:latest |
    Then the step failed
    And the output should contain:
      | blocked |
    And I run commands on the host:
      | echo "ADD_REGISTRY='--add-registry docker.io'" >> /etc/sysconfig/docker |
    Then the step should succeed
    And I run commands on the host:
      | systemctl restart docker |
    Then the step should succeed
    And I run commands on the host:
      | docker pull docker.io/library/centos:latest |
    Then the step should succeed
