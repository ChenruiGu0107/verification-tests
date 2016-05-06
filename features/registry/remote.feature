Feature: remote registry related scenarios

  # @author pruan@redhat.com
  # @case_id 518927
  @admin
  Scenario: Pull image by digest value in the OpenShift registry
    Given I have a project
    # must run this step prior to calling the step 'I run commands on the host'
    And I select a random node's host
    # save the original project name since we will need to switch it back from using 'default'
    And evaluation of `project.name` is stored in the :original_proj clipboard
    When I find a bearer token of the deployer service account
    When I run the :tag client command with:
      | source_type | docker                  |
      | source      | openshift/origin:latest |
      | dest        | mystream:latest         |
    Then the step should succeed
    And evaluation of `service("docker-registry", project("default")).url(user: :admin)` is stored in the :integrated_reg_ip clipboard
    When I run commands on the host:
      | docker login -u dnm -p <%= service_account.get_bearer_token.token %> -e dnm@redmail.com <%= cb.integrated_reg_ip %> |
    Then the step should succeed
    When I use the "<%= cb.original_proj %>" project
    When I run commands on the host:
      | docker pull <%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:latest |
    Then the step should succeed
    And evaluation of `@result[:response].match(/Digest:\s+(.*)/)[1].strip` is stored in the :img_digest clipboard
    And I run commands on the host:
      | docker rmi -f  <%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:latest |
    Then the step should succeed
    When I run commands on the host:
      | docker pull <%= cb.integrated_reg_ip %>/<%= project.name %>/mystream@<%= cb.img_digest %> |
    Then the step should succeed
