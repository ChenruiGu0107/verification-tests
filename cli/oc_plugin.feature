Feature: oc plugin related tests

  # @author xxia@redhat.com
  # @case_id OCP-14854
  Scenario: add plugin with subcommand and flags
    Given I have a project
    And I create the "plugins-dir/myplugin" directory
    And I obtain test data file "cli/oc_plugin/myplugin/plugin.yaml" into the "plugins-dir/myplugin" dir
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
    And the output should contain:
      | this is the long description field  |
      | Usage:                              |
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

  # @author xxia@redhat.com
  # @case_id OCP-14849
  @admin @destructive
  Scenario: check search order and list folders for oc plugins
    Given I log the message> this auto script is not suitable for container installed env
    Given I select a random node's host
    When I run commands on the host:
      | mkdir -p kubectl_plugins_path/mytestplugin                 |
      | mkdir -p xdg_data_dirs/kubectl/plugins/mytestplugin        |
      | curl -o xdg_data_dirs/kubectl/plugins/mytestplugin/plugin.yaml <%= BushSlicer::HOME %>/features/tierN/testdata/cli/oc_plugin/xdg_data_dirs.yaml |
      | curl -o kubectl_plugins_path/mytestplugin/plugin.yaml <%= BushSlicer::HOME %>/features/tierN/testdata/cli/oc_plugin/kubectl_plugins_path.yaml   |
      | KUBECTL_PLUGINS_PATH=kubectl_plugins_path XDG_DATA_DIRS=xdg_data_dirs oc plugin -h |
    Then the step should succeed
    And the output should contain "myKUBECTL_PLUGINS_PATH"
    And the output should not contain "myXDG_DATA_DIRS"

    # Check parent path
    When I run commands on the host:
      | mv kubectl_plugins_path/mytestplugin/kubectl_plugins_path.yaml kubectl_plugins_path |
      | KUBECTL_PLUGINS_PATH=kubectl_plugins_path oc plugin -h                              |
    Then the step should succeed
    And the output should contain "myKUBECTL_PLUGINS_PATH"

    Given I register clean-up steps:
    """
    When I run commands on the host:
      | rm -rf /usr/share/kubectl/plugins/mytestplugin ~/.kube/plugins/mytestplugin |
    Then the step should succeed
    """

    When I run commands on the host:
      | mkdir -p ~/.kube/plugins/mytestplugin            |
      | mkdir -p /usr/share/kubectl/plugins/mytestplugin |
      | curl -o ~/.kube/plugins/mytestplugin/plugin.yaml <%= BushSlicer::HOME %>/features/tierN/testdata/cli/oc_plugin/kube.yaml                 |
      | curl -o /usr/share/kubectl/plugins/mytestplugin/plugin.yaml <%= BushSlicer::HOME %>/features/tierN/testdata/cli/oc_plugin/usr-share.yaml |
      | unset KUBECTL_PLUGINS_PATH XDG_DATA_DIRS         |
      | oc plugin -h                                     |
    Then the step should succeed
    And the output should match:
      | mykubeplugin.*My plugin's short description   |
      | mysharedplugin.*My plugin's short description |

    When I run commands on the host:
      | XDG_DATA_DIRS=xdg_data_dirs oc plugin -h |
    Then the step should succeed
    And the output should match:
      | mykubeplugin.*My plugin's short description     |
      | myXDG_DATA_DIRS.*My plugin's short description  |
    And the output should not contain:
      | mysharedplugin |

    When I run commands on the host:
      | KUBECTL_PLUGINS_PATH=kubectl_plugins_path oc plugin -h |
    Then the step should succeed
    And the output should match:
      | myKUBECTL_PLUGINS_PATH.*My plugin's short description |
    And the output should not contain:
      | mykubeplugin   |
      | mysharedplugin |
