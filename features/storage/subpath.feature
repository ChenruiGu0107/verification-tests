Feature: volumeMounts should be able to use subPath
  # @author jhou@redhat.com
  # @case_id OCP-14087
  @admin
  Scenario: Subpath should receive right permissions - emptyDir
    Given I have a project
    When I run the :create admin command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/emptydir/subpath.yml |
        | n | <%= project.name %>                                                                                        |
    Then the step should succeed
    Given the pod named "subpath" becomes ready

    When admin executes on the pod:
      | ls | -ld | /mnt/direct |
    Then the output should contain:
      | drwxrwsrwx |
    When admin executes on the pod:
      | ls | -ld | /mnt/subpath |
    Then the output should contain:
      | drwxrwsrwx |

    When admin executes on the pod:
      | touch | /mnt/subpath/testfile |
    Then the step should succeed
