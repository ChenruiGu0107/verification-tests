Feature: remote registry related scenarios

  # @author pruan@redhat.com
  # @case_id 518927
  @admin
  Scenario: Pull image by digest value in the OpenShift registry
    Given I store the token from whoami to :token clipboard
    Given the openshift service information is stored in the :svc clipboard
    Given I have a project
    And evaluation of `cb.svc['docker-registry']['spec']['clusterIP']+":"+cb.svc['docker-registry']['spec']['ports'][0]['targetPort'].to_s` is stored in the :integrated_reg_ip clipboard
    When I run the :tag client command with:
      | source_type | docker                  |
      | source      | openshift/origin:latest |
      | dest        | mystream:latest         |
    Then the step should succeed
    When I run commands on a node:
      | docker login -u <%= user.name %> -p <%= cb.token %> -e any@redmail.com <%= cb.integrated_reg_ip %> |
    Then the step should succeed
    When I run commands on a node:
      | docker pull <%= cb.integrated_reg_ip %>/<%= project.name %>/mystream |
    Then the step should succeed
    And I save the docker image digest from output to :img_digest clipboard
    And I run commands on a node:
      | docker rmi -f  <%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:latest |
    Then the step should succeed
    When I run commands on a node:
      | docker pull <%= cb.integrated_reg_ip %>/<%= project.name %>/mystream@<%= cb.img_digest %> |
    Then the step should succeed
