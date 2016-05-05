Feature: remote registry related scenarios

  # @author pruan@redhat.com
  # @case_id 518927
  @admin
  Scenario: Pull image by digest value in the OpenShift registry
    Given I have a project
    # save the original project name since we will need to switch it back from using 'default'
    And evaluation of `project.name` is stored in the :original_proj clipboard
    When I run the :tag client command with:
      | source_type | docker                  |
      | source      | openshift/origin:latest |
      | dest        | mystream:latest         |
    Then the step should succeed
    When I switch to cluster admin pseudo user
    And evaluation of `service("docker-registry", project("default")).url(user: :admin)` is stored in the :integrated_reg_ip clipboard
    And I switch to the first user
    When I run commands on a node:
      | docker login -u <%= user.name %> -p <%= user.get_bearer_token.token %> -e any@redmail.com <%= cb.integrated_reg_ip %> |
    Then the step should succeed
    # need to switch the project back to the regular user project
    When I use the "<%= cb.original_proj %>" project
    When I run commands on a node:
      | docker pull <%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:latest |
    Then the step should succeed
    And evaluation of `@result[:response].match(/Digest:\s+(.*)/)[1].strip` is stored in the :img_digest clipboard
    And I run commands on a node:
      | docker rmi -f  <%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:latest |
    Then the step should succeed
    When I run commands on a node:
      | docker pull <%= cb.integrated_reg_ip %>/<%= project.name %>/mystream@<%= cb.img_digest %> |
    Then the step should succeed
