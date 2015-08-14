Feature: oc related features
  #@author pruan@redhat.com
  #@case_id 497509
  Scenario: Check OpenShift Concepts and Types via oc types
    When I run the :help client command
    Then the output should contain:
      | types        An introduction to concepts and types |
    When I run the :types client command
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

  #@author pruan@redhat.com
  #@case_id 497521
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


