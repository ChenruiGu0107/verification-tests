Feature: oc plugin related tests
  # @author yinzhou@redhat.com
  # @case_id OCP-21039
  Scenario: The oc plugin mechanism - git-style
    Given the master version >= "4.1"
    Given I have a project
    # invoke your custom command with a underscore
    When I run the :exec_extension_oc_cmd client command with:
      | _env     | PATH=<%= ENV['PATH'] %>:<%= BushSlicer::HOME %>/features/tierN/testdata/cli/oc_plugin/plugins-git-style/moreplugin |
      | cmd_name | cmd21039                                                                                                           |
      | cmd_name | barcmd_bazcmd                                                                                                      |
    Then the step should succeed
    And the output should match:
      | I'm a plugin named 'oc-cmd21039-barcmd_bazcmd' |
    # invoke your custom command with an dash
    When I run the :exec_extension_oc_cmd client command with:
      | _env     | PATH=<%= ENV['PATH'] %>:<%= BushSlicer::HOME %>/features/tierN/testdata/cli/oc_plugin/plugins-git-style/moreplugin |
      | cmd_name | cmd21039                                                                                                           |
      | cmd_name | barcmd-bazcmd                                                                                                      |
    Then the step should succeed
    And the output should match:
      | I'm a plugin named 'oc-cmd21039-barcmd_bazcmd' |
    # invoke with argument
    When I run the :exec_extension_oc_cmd client command with:
      | _env     | PATH=<%= ENV['PATH'] %>:<%= BushSlicer::HOME %>/features/tierN/testdata/cli/oc_plugin/plugins-git-style/moreplugin |
      | cmd_name | cmd21039                                                                                                           |
      | cmd_name | barcmd-bazcmd                                                                                                      |
      | arg      | anyany                                                                                                             |
    Then the step should succeed
    And the output should match:
      | I'm a plugin named 'oc-cmd21039-barcmd_bazcmd',my first command-line argument was anyany |
    # Name conflicts and overshadowing
    When I run the :exec_extension_oc_cmd client command with:
      | _env     | PATH=<%= ENV['PATH'] %>:<%= BushSlicer::HOME %>/features/tierN/testdata/cli/oc_plugin/plugins-git-style/moreplugin |
      | cmd_name | cmd21039                                                                                                           |
      | arg      | version                                                                                                            |
    Then the step should succeed
    And the output should match:
      | 1.0.0 |
    When I run the :exec_extension_oc_cmd client command with:
      | _env     | PATH=<%= ENV['PATH'] %>:<%= BushSlicer::HOME %>/features/tierN/testdata/cli/oc_plugin/plugins-git-style:<%= BushSlicer::HOME %>/features/tierN/testdata/cli/oc_plugin/plugins-git-style/moreplugin |
      | cmd_name | cmd21039                                                                                                                                                                                           |
      | arg      | version                                                                                                                                                                                            |
    Then the step should succeed
    And the output should match:
      | 2.0.0 |
    # Invocation of the longest executable filename
    When I run the :exec_extension_oc_cmd client command with:
      | _env     | PATH=<%= ENV['PATH'] %>:<%= BushSlicer::HOME %>/features/tierN/testdata/cli/oc_plugin/plugins-git-style |
      | cmd_name | cmd21039                                                                                                |
      | cmd_name | barcmd                                                                                                  |
    Then the step should succeed
    And the output should match:
      | Plugin oc-cmd21039-barcmd is executed |
    When I run the :exec_extension_oc_cmd client command with:
      | _env     | PATH=<%= ENV['PATH'] %>:<%= BushSlicer::HOME %>/features/tierN/testdata/cli/oc_plugin/plugins-git-style |
      | cmd_name | cmd21039                                                                                                |
      | cmd_name | barcmd                                                                                                  |
      | cmd_name | bazcmd                                                                                                  |
    Then the step should succeed
    And the output should match:
      | Plugin oc-cmd21039-barcmd-bazcmd is executed |
    When I run the :exec_extension_oc_cmd client command with:
      | _env     | PATH=<%= ENV['PATH'] %>:<%= BushSlicer::HOME %>/features/tierN/testdata/cli/oc_plugin/plugins-git-style |
      | cmd_name | cmd21039                                                                                                |
      | cmd_name | barcmd                                                                                                  |
      | cmd_name | bazcmd                                                                                                  |
      | arg      | anythings                                                                                               |
    Then the step should succeed
    And the output should match:
      | Plugin oc-cmd21039-barcmd-bazcmd is executed, with anythings as its first argument |
    # Checking for plugin warnings
    When I run the :exec_extension_oc_cmd client command with:
      | _env | PATH=<%= ENV['PATH'] %>:<%= BushSlicer::HOME %>/features/tierN/testdata/cli/oc_plugin/plugins-git-style:<%= BushSlicer::HOME %>/features/tierN/testdata/cli/oc_plugin/plugins-git-style/moreplugin |
      | arg  | plugin                                                                                                                                                                                             |
      | arg  | list                                                                                                                                                                                               |
    And the output by order should match:
      | warning: .*/oc-invalid identified as a kubectl plugin, but it is not executable                                |
      | warning: .*/moreplugin/oc-cmd21039 is overshadowed by a similarly named plugin: .*lugins-git-style/oc-cmd21039 |
