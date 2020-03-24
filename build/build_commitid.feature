Feature: dockerbuild.feature
  # @author wewang@redhat.com
  Scenario Outline: Store commit id in sti build
    Given I have a project
    When I download a file from "<file>"
    Then the step should succeed
    And I replace lines in "<file_name>":
      | registry.access.redhat.com/ | <%= product_docker_repo %> |
    Then the step should succeed
    When I run the :new_app client command with:
      | file  | <file_name> |
    Then the step should succeed
    Given the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    When I run the :describe client command with:
      | resource        | build               |
      | name            | ruby-sample-build-1 |
    Then the output should match:
      | Commit:.*[a-zA-Z0-9]+                                |
      | Output to:.*ImageStreamTag origin-ruby-sample:latest |
    When I replace resource "bc" named "ruby-sample-build":
      | github.com/openshift/ruby-hello-world.git | github.com/openshift-qe/ruby-hello-world.git |
    Then the step should succeed
    And the output should contain "replaced"
    When I get project build_config named "ruby-sample-build" as JSON
    Then the output should contain:
      |github.com/openshift-qe/ruby-hello-world.git|
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    And the "ruby-sample-build-2" build was created
    And the "ruby-sample-build-2" build completed
    When I run the :describe client command with:
      | resource        | build               |
      | name            | ruby-sample-build-2 |
    Then the output should match:
      | Commit:.*[a-zA-Z0-9]+ |
      | Output to:.*ImageStreamTag origin-ruby-sample:latest |
    When I run the :patch client command with:
      | resource      | bc                |
      | resource_name | ruby-sample-build |
      | p             | {"spec":{"output":{"to":{"kind":"DockerImage"}}}} |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | bc                       |
      | resource_name | ruby-sample-build        |
      | template      | {{.spec.output.to.kind}} |
    Then the step should succeed
    And the output should contain "DockerImage"
    Given evaluation of `"image-registry.openshift-image-registry.svc:5000"` is stored in the :integrated_reg_ip clipboard 
    When I run the :patch client command with:
      | resource      | bc                |
      | resource_name | ruby-sample-build |
      | p             |{"spec":{"output":{"to":{"name":"<%= cb.integrated_reg_ip %>/<%= project.name %>/origin-ruby-sample:latest"}}}} |
    Then the step should succeed
    When I get project build_config named "ruby-sample-build" as YAML
    Then the step should succeed
    And the output should contain "<%= cb.integrated_reg_ip %>"
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    And the "ruby-sample-build-3" build was created
    And the "ruby-sample-build-3" build completed
    When I run the :describe client command with:
      | resource        | build               |
      | name            | ruby-sample-build-3 |
    Then the output should match:
      | Commit:.*[a-zA-Z0-9]+     |
      | Output to:.*DockerImage.* |

    Examples:
      | file                                                                                                      | file_name                        |
      | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/build/ruby22rhel7-template-docker.json | ruby22rhel7-template-docker.json | # @case_id OCP-10743
      | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/build/ruby22rhel7-template-sti.json    | ruby22rhel7-template-sti.json    | # @case_id OCP-11213

