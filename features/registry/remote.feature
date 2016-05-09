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

  # @author pruan@redhat.com
  # @case_id 518928
  @admin
  @destructive
  Scenario: Pull image will failed when integrated registry with option:pullthrough=false
    Given I have a project
    Given  default docker-registry deployment config is restored after scenario
    # must run this step prior to calling the step 'I run commands on the host'
    And I select a random node's host
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/registry/tc518928/config.yaml"
    And I run the :secrets client command with:
      | action | new         |
      | name   | tc518928    |
      | source | config.yaml |
    Then the step should succeed
    # save the original project name since we will need to switch it back from using 'default'
    And evaluation of `project.name` is stored in the :original_proj clipboard
    When I find a bearer token of the deployer service account
#    And I switch to cluster admin pseudo user
    And I run the :set_env admin command with:
      | resource | dc/docker-registry                      |
      | e        | REGISTRY_CONFIGURATION_PATH=config.yaml |
    Then the step should succeed
    And I run the :set_volume admin command with:
      | resource    | dc/docker-registry |
      | action      | --add              |
      | name        | config             |
      | mount-path  | /config            |
      | type        | secret             |
      | secret-name | tc518928           |
      | overwrite   | true               |
    Then the step should succeed
    When I run the :tag admin command with:
      | source_type | docker          |
      | source      | aosqe/sleep     |
      | dest        | mystream:latest |
    Then the step should succeed
    And evaluation of `service("docker-registry", project("default")).url(user: :admin)` is stored in the :integrated_reg_ip clipboard
    When I run commands on the host:
      | docker login -u dnm -p <%= service_account.get_bearer_token.token %> -e dnm@redmail.com <%= cb.integrated_reg_ip %> |
    Then the step should succeed
    When I use the "<%= cb.original_proj %>" project
    When I run commands on the host:
      | docker pull <%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:latest |
    Then the step should fail
    And the output should contain "not found"

