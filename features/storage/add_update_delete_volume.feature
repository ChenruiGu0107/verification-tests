Feature: Add, update remove volume to rc/dc and --overwrite option

  # @author jialiu@redhat.com
  # @case_id 491430
  @admin @destructive
  Scenario: Add/Remove persistentVolumeClaim to dc and rc and '--overwrite' option
    # Preparations
    Given I have a project
    And I have a NFS service in the project
    When I run the :new_app client command with:
      | image_stream | openshift/mongodb |
      | env | MONGODB_USER=tester,MONGODB_PASSWORD=xxx,MONGODB_DATABASE=testdb,MONGODB_ADMIN_PASSWORD=yyy |
      | name | mydb |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=mydb |

    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template.json"
    And I replace lines in "pv-template.json":
      |#NFS-Service-IP#|<%= service.ip %>|
      |#NS#|<%= project.name %>|
    Then admin creates a PV from "pv-template.json" where:
    ||
    Then the step should succeed

    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-template.json"
    And I replace lines in "pvc-template.json":
      |#NS#|<%= project.name %>|
    Then I run the :create client command with:
      | f | pvc-template.json |
    Then the step should succeed

    Given the PV becomes :bound

    # add pvc to dc
    When I run the :volume client command with:
      | resource      | dc/mydb                 |
      | action        | --add                   |
      | type          | persistentVolumeClaim   |
      | mount-path    | /opt1                   |
      | name          | v1                      |
      | claim-name    | nfsc-<%= project.name %>|
    Then the step should succeed
    And I wait for the pod to die
    And a pod becomes ready with labels:
      | app=mydb |

    # check after add pvc to dc
    When I run the :get client command with:
      | resource      | dc/mydb            |
      | output        | yaml               |
    And the output should contain:
      | - mountPath: /opt1         |
      |   name: v1                 |
      | - name: v1                 |
      |   persistentVolumeClaim:   |
      |   claimName: nfsc-<%= project.name %>|
    When I run the :get client command with:
      | resource      | rc/mydb-2          |
      | output        | yaml               |
    And the output should contain:
      | - mountPath: /opt1         |
      |   name: v1                 |
      | - name: v1                 |
      |   persistentVolumeClaim:   |
      |   claimName: nfsc-<%= project.name %>|
    When I execute on the pod:
      | grep | opt1 | /proc/mounts |
    Then the step should succeed

    # remove pvc from dc
    When I run the :volume client command with:
      | resource      | dc/mydb               |
      | action        | --remove              |
      | name          | v1                    |
    Then the step should succeed
    And I wait for the pod to die
    And a pod becomes ready with labels:
      | app=mydb |

    # check after remove pvc from dc
    When I run the :get client command with:
      | resource      | dc/mydb            |
      | output        | yaml               |
    And the output should not contain:
      |   name: v1                 |
    When I run the :get client command with:
      | resource      | rc/mydb-3          |
      | output        | yaml               |
    And the output should not contain:
      |   name: v1                 |
    When I execute on the pod:
      | grep | opt1 | /proc/mounts |
    Then the step should fail

    # add pvc to rc
    When I run the :volume client command with:
      | resource      | rc/mydb-3               |
      | action        | --add                   |
      | type          | persistentVolumeClaim   |
      | mount-path    | /opt2                   |
      | name          | v2                      |
      | claim-name    | nfsc-<%= project.name %>|
    Then the step should succeed
    
    # check after add pvc to rc
    When I run the :get client command with:
      | resource      | rc/mydb-3            |
      | output        | yaml                 |
    And the output should contain:
      | - mountPath: /opt2         |
      |   name: v2                 |
      | - name: v2                 |
      |   persistentVolumeClaim:   |
      |   claimName: nfsc-<%= project.name %>|
    When I run the :delete client command with:
      | object_type   | pod                   |
      | l             | app=mydb              |
    Then the step should succeed
    And I wait for the pod to die
    And a pod becomes ready with labels:
      | app=mydb |
    When I execute on the pod:
      | grep | opt2 | /proc/mounts |
    Then the step should succeed

    # remove pvc from rc
    When I run the :volume client command with:
      | resource      | rc/mydb-3               |
      | action        | --remove                |
      | name          | v2                      |
    Then the step should succeed
    
    # check after remove pvc from rc
    When I run the :get client command with:
      | resource      | rc/mydb-3            |
      | output        | yaml                 |
    And the output should not contain:
      |   name: v2                 |
    When I run the :delete client command with:
      | object_type   | pod                   |
      | l             | app=mydb              |
    Then the step should succeed
    And I wait for the pod to die
    And a pod becomes ready with labels:
      | app=mydb |
    When I execute on the pod:
      | grep | opt2 | /proc/mounts |
    Then the step should fail

    # add pvc to dc with '--overwrite' option 
    When I run the :volume client command with:
      | resource      | dc/mydb                 |
      | action        | --add                   |
      | type          | persistentVolumeClaim   |
      | mount-path    | /var/lib/mongodb/data   |
      | claim-name    | nfsc-<%= project.name %>|
    Then the step should fail
    And the output should contain:
      |   already exists         |
    When I run the :volume client command with:
      | resource      | dc/mydb                 |
      | action        | --add                   |
      | type          | persistentVolumeClaim   |
      | mount-path    | /var/lib/mongodb/data   |
      | name          | mydb-volume-1           |
      | claim-name    | nfsc-<%= project.name %>|
    Then the step should fail
    And the output should contain:
      | Use --overwrite to replace |
    When I run the :volume client command with:
      | resource      | dc/mydb                 |
      | action        | --add                   |
      | type          | persistentVolumeClaim   |
      | mount-path    | /var/lib/mongodb/data   |
      | name          | mydb-volume-1           |
      | claim-name    | nfsc-<%= project.name %>|
      | overwrite     |                         |
    Then the step should succeed
    And I wait for the pod to die
    And a pod becomes ready with labels:
      | app=mydb |
    When I execute on the pod:
      | grep | mongodb | /proc/mounts |
    Then the step should succeed

