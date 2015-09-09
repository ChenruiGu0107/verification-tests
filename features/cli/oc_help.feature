Feature: oc related features
  # @author pruan@redhat.com
  # @case_id 497509
  Scenario: Check OpenShift Concepts and Types via oc types
    When I run the :help client command with:
      | help_word | -h | 
    Then the output should contain:
      | types        An introduction to concepts and types |
    When I run the :help client command with:
      | help_word | --help |
      | command | types |
    Then the output should contain:
      | Concepts: |
      | * Containers: |
      | A definition of how to run one or more processes inside of a portable Linux |
      | environment. Containers are started from an Image and are usually isolated  |
      | * Image:                                                                    |
      | * Pods [pod]:                                                               |
      | * Labels:                                                                   |
      | * Volumes:                                                                  |
      | * Nodes [node]:                                                           |
      | * Routes [route]:                                                   |
      | * Replication Controllers [rc]:                                     |
      | * Deployment Configuration [dc]:                                    |
      | * Build Configuration [bc]:                                         |
      | * Image Streams and Image Stream Tags [is,istag]:                   |
      | * Projects [project]:                                               |
      | Usage:                                                              |
      |  oc types [options]                                                 |

  # @author pruan@redhat.com
  # @case_id 497521
  Scenario: Check the help page of oc edit
    When I run the :edit client command with:
      | help | true |
    Then the output should contain:
      | Edit a resource from the default editor |
      | The edit command allows you to directly edit any API resource you can retrieve via the |
      | command line tools. It will open the editor defined by your OC_EDITOR, GIT_EDITOR,     |
      | or EDITOR environment variables, or fall back to 'vi' for Linux or 'notepad' for Windows. |
      | Usage:                                                                                    |
      | oc edit (RESOURCE/NAME \| -f FILENAME) [options] |

  # @author cryan@redhat.com
  # @case_id 497907
  Scenario: Check --list/-L option for new-app
    When I run the :new_app client command with:
      |help||
    Then the output should contain:
      | oc new-app --list |
      | -L, --list=false  |

  # @author cryan@redhat.com
  # @case_id 470720
  Scenario: Check help info for oc config
    When I run the :config client command with:
      | h ||
    Then the output should contain:
      | Manage the client config files |
      | oc config SUBCOMMAND [options] |
      | Examples |

  # @author pruan@redhat.com
  # @case_id 487931
  Scenario: Check the help page for oc export
    When I run the :help client command with:
      | help_word | --help |
      | command | export |
    Then the output should contain:
      | Export resources so they can be used elsewhere |
      | The export command makes it easy to take existing objects and convert them to configuration files |
      | for backups or for creating elsewhere in the cluster. |
      | oc export RESOURCE/NAME ... [options] [options] |

  # @author pruan@redhat.com
  # @case_id 483189
  Scenario: Check the help page for oc deploy
    When I run the :help client command with:
      | help_word | --help |
      | command   | deploy |
    Then the output should contain:
      | View, start, cancel, or retry a deployment |
      | This command allows you to control a deployment config. |
      | oc deploy DEPLOYMENTCONFIG [options]                    |
      | --cancel=false: Cancel the in-progress deployment.      |
      | --enable-triggers=false: Enables all image triggers for the deployment config. |
      | --latest=false: Start a new deployment now.                                    |
      | --retry=false: Retry the latest failed deployment.                             |

  # @author pruan@redhat.com
  # @case_id 492274
  Scenario: Check help doc of command 'oc tag'
    When I run the :help client command with:
      | help_word | -h  |
      | command   | tag |
    Then the output should contain:
      | Tag existing images into image streams                                         |
      | The tag command allows you to take an existing tag or image from an image      |
      | stream, or a Docker image pull spec, and set it as the most recent image for a |
      | tag in 1 or more other image streams. It is similar to the 'docker tag'        |
      | command, but it operates on image streams instead.                             |
      | oc tag [--source=SOURCETYPE] SOURCE DEST [DEST ...] [options]                  |
    When I run the :help client command with:
      | help_word | help  |
      | command   | tag   |
    Then the output should contain:
      | Tag existing images into image streams                                         |
      | The tag command allows you to take an existing tag or image from an image      |
      | stream, or a Docker image pull spec, and set it as the most recent image for a |
      | tag in 1 or more other image streams. It is similar to the 'docker tag'        |
      | command, but it operates on image streams instead.                             |
      | oc tag [--source=SOURCETYPE] SOURCE DEST [DEST ...] [options]                  |
  
  # @author wsun@redhat.com
  # @case_id 499948
  Scenario: Check the help page for oc annotate
    When I run the :help client command with:
      | help_word | -h |
    Then the output should contain:
      | annotate     Update the annotations on a resource |
    When I run the :help client command with:
      | help_word | --help |
      | command | annotate |
    Then the output should contain:
      | Update the annotations on one or more resources |
      | oc annotate [--overwrite] RESOURCE NAME KEY_1=VAL_1 ... KEY_N=VAL_N [--resource-version=version] [options] |
      | --all=false: select all resources in the namespace of the specified resource types |
      | --no-headers=false: When using the default output, don't print headers. |
      | --output-version='': Output the formatted object with the given version (default api-version). |
      | --overwrite=false: If true, allow annotations to be overwritten, otherwise reject annotation updates that overwrite existing annotations. |
      | --resource-version='': If non-empty, the annotation update will only succeed if this is the current resource-version for the object. Only valid when specifying a single resource. |
      | -t, --template='': Template string or path to template file to use when -o=template or -o=templatefile.  The template format is golang templates [http://golang.org/pkg/text/template/#pkg-overview] |
