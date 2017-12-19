Feature: oc plugin related tests

  # @author xxia@redhat.com
  # @case_id OCP-14854
  Scenario: add plugin with subcommand and flags
    Given I have a project
    And I create the "plugins-dir/myplugin" directory
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cli/oc_plugin/myplugin/plugin.yaml" into the "plugins-dir/myplugin" dir
    When I run the :plugin client command with:
      | h    |                                   |
      | _env | KUBECTL_PLUGINS_PATH=plugins-dir  |
    Then the step should succeed
    And the output by order should match:
      | Available [Cc]ommands:      |
      | test *this is plugin test   |
    When I run the :plugin client command with:
      | cmd_name | test                              |
      | h        |                                   |
      | _env     | KUBECTL_PLUGINS_PATH=plugins-dir  |
    Then the step should succeed
    And the output by order should contain:
      | this is the long description field  |
      | Usage:                              |
      |   oc plugin test [options]          |
      | Examples:                           |
      |   oc plugin test                    |
      | Options:                            |
      |   -a, --all='all': this is my flag  |
    When I run the :plugin client command with:
      | cmd_name | test                              |
      | _env     | KUBECTL_PLUGINS_PATH=plugins-dir  |
    Then the step should succeed
    And the output should contain "plugin.yaml"
    When I run the :plugin client command with:
      | cmd_name | test                              |
      | cmd_flag | -a                                |
      | config   | :false                            |
      | _env     | KUBECTL_PLUGINS_PATH=plugins-dir  |
    Then the step should fail
    And the output should match:
      | flag needs an argument.*-a |
    When I run the :plugin client command with:
      | cmd_name | test                              |
      | cmd_flag | --all                             |
      | config   | :false                            |
      | _env     | KUBECTL_PLUGINS_PATH=plugins-dir  |
    Then the step should fail
    And the output should match:
      | flag needs an argument.*--all |
    When I run the :plugin client command with:
      | cmd_name     | test                              |
      | cmd_flag     | -a                                |
      | cmd_flag_val | anyvalue                          |
      | _env         | KUBECTL_PLUGINS_PATH=plugins-dir  |
    Then the step should succeed
    And the output should contain "plugin.yaml"

    # When no longDesc, shortDesc is used
    Given I replace lines in "plugins-dir/myplugin/plugin.yaml":
      | shortDesc: "this is plugin test"               | shortDesc: "I say hello!"   |
      | longDesc: "this is the long description field" |                             |
    When I run the :plugin client command with:
      | cmd_name | test                              |
      | h        |                                   |
      | _env     | KUBECTL_PLUGINS_PATH=plugins-dir  |
    Then the step should succeed
    And the output should contain "I say hello!"

    # Execute dependent ruby code that is relative to plugin.yaml
    Given I create the "plugins-dir/aging" directory
    And I download a file from "https://raw.githubusercontent.com/kubernetes/kubernetes/6b03a43/pkg/kubectl/plugins/examples/aging/plugin.yaml" into the "plugins-dir/aging" dir
    And I download a file from "https://raw.githubusercontent.com/kubernetes/kubernetes/6b03a43/pkg/kubectl/plugins/examples/aging/aging.rb" into the "plugins-dir/aging" dir
    And the "plugins-dir/aging/aging.rb" file is made executable
    And I save kube config in file "plugins-dir/aging/my.config"
    And I replace lines in "plugins-dir/aging/aging.rb":
      | kubectl --namespace #{namespace} | oc --config my.config |
    When I run the :plugin client command with:
      | cmd_name | aging                             |
      | _env     | KUBECTL_PLUGINS_PATH=plugins-dir  |
    Then the step should succeed
    And the output should contain:
      | The Magnificent Aging Plugin |
      | No pods                      |
