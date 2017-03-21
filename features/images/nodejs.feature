Feature: nodejs.feature

  # @author dyan@redhat.com
  # @case_id OCP-12183 OCP-12231 OCP-13516
  Scenario Outline: Add NPM_MIRROR env var to Nodejs S2I
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | openshift/nodejs:<image>~https://github.com/openshift/nodejs-ex |
      | e        | NPM_MIRROR=http://not/a/valid/index                             |
    Then the step should succeed
    Given the "nodejs-ex-1" build failed
    When I run the :logs client command with:
      | resource_name | bc/nodejs-ex |
    Then the output should contain "npm ERR! network"
    Examples:
      | image |
      | 0.10  | # @case_id OCP-12183
      | 4     | # @case_id OCP-12183
      | 6     | # @case_id OCP-13516
