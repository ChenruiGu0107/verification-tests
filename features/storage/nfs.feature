Feature: NFS Persistent Volume

  # @author lxia@redhat.com
  # @case_id 510432
  @admin
  @destructive
  Scenario: NFS volume failed to mount returns more verbose message
    # Preparations
    Given I have a project
    And I have a NFS service in the project

    # Creating PV and PVC
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template.json" where:
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |
      | ["spec"]["nfs"]["path"]   | /non-exist-path                  |
      | ["metadata"]["name"]      | nfs-<%= project.name %>          |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]   | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"] | nfs-<%= project.name %>  |
    Then the step should succeed
    And the PV becomes :bound
    And the "nfsc-<%= project.name %>" PVC becomes :bound

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | nfsc-<%= project.name %>  |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
    Then the step should succeed
    When I run the :get client command with:
      | resource | pod/mypod-<%= project.name %> |
    Then the output should not contain:
      | Running |
    And I wait up to 300 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod                       |
      | name     | mypod-<%= project.name %> |
    Then the output should contain:
      | Unable to mount volumes for pod |
      | Mount failed: exit status       |
      | Mounting arguments              |
    """

  # @author lxia@redhat.com
  # @case_id 508049
  @admin
  @destructive
  Scenario: NFS volume plugin with RWO access mode and Recycle policy
    # Preparations
    Given I have a project
    And I have a NFS service in the project
    When I execute on the pod:
      | chmod | g+w | /mnt/data |
    Then the step should succeed

    # Creating PV and PVC
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto-nfs-recycle-rwo.json" where:
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json |
    Then the step should succeed

    Given the PV becomes :bound

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json |
    Then the step should succeed
    Given the pod named "nfs" becomes ready
    When I execute on the pod:
      | id |
    Then the step should succeed
    When I execute on the pod:
      | ls | -ld | /mnt/ |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/myfile |
    Then the step should succeed
    And the output should not contain "Permission denied"

    Given I run the :delete client command with:
      | object_type       | pod |
      | object_name_or_id | nfs |
    And I run the :delete client command with:
      | object_type       | pvc  |
      | object_name_or_id | nfsc |
    Then the step should succeed
    Then the PV becomes :available

  # @author lxia@redhat.com
  # @case_id 508050
  @admin
  @destructive
  Scenario: NFS volume plugin with ROX access mode and Retain policy
    # Preparations
    Given I have a project
    And I have a NFS service in the project
    When I execute on the pod:
      | chmod | g+w | /mnt/data |
    Then the step should succeed

    # Creating PV and PVC
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto-nfs-retain-rox.json" where:
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json |
    Then the step should succeed

    Given the PV becomes :bound

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json |
    Then the step should succeed
    Given the pod named "nfs" becomes ready
    When I execute on the pod:
      | id |
    Then the step should succeed
    When I execute on the pod:
      | ls | -ld | /mnt/ |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/myfile |
    Then the step should succeed
    And the output should not contain "Permission denied"

    Given I run the :delete client command with:
      | object_type       | pod |
      | object_name_or_id | nfs |
    And I run the :delete client command with:
      | object_type       | pvc  |
      | object_name_or_id | nfsc |
    Then the step should succeed
    Then the PV becomes :released
    When I run the :exec client command with:
      | pod | nfs-server |
      | exec_command | ls |
      | exec_command_arg | /mnt/data/myfile |
    Then the step should succeed

  # @author lxia@redhat.com
  # @case_id 508051
  @admin
  @destructive
  Scenario: NFS volume plugin with RWX access mode and Default policy
    # Preparations
    Given I have a project
    And I have a NFS service in the project
    When I execute on the pod:
      | chmod | g+w | /mnt/data |
    Then the step should succeed

    # Creating PV and PVC
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto-nfs-default-rwx.json" where:
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwx.json |
    Then the step should succeed

    Given the PV becomes :bound

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json |
    Then the step should succeed
    Given the pod named "nfs" becomes ready
    When I execute on the pod:
      | id |
    Then the step should succeed
    When I execute on the pod:
      | ls | -ld | /mnt/ |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/myfile |
    Then the step should succeed
    And the output should not contain "Permission denied"

    Given I run the :delete client command with:
      | object_type       | pod |
      | object_name_or_id | nfs |
    And I run the :delete client command with:
      | object_type       | pvc  |
      | object_name_or_id | nfsc |
    Then the step should succeed
    Then the PV becomes :released
    When I run the :exec client command with:
      | pod | nfs-server |
      | exec_command | ls |
      | exec_command_arg | /mnt/data/myfile |
    Then the step should succeed

  # @author jhou@redhat.com
  # @case_id 488980
  @admin @destructive
  Scenario: Retain NFS Persistent Volume on release
    Given I have a project
    And I have a NFS service in the project

    And admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-retain.json" where:
      | ["metadata"]["name"]      | nfs-<%= project.name %>          |
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-rwx.json" URL replacing paths:
      | ["spec"]["volumeName"] | <%= pv.name %> |
    Then the step should succeed
    And the "nfsc" PVC becomes :bound

    # Create tester pod
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json |
    Then the step should succeed

    Given the pod named "nfs" becomes ready
    And I execute on the "nfs" pod:
      | touch | /mnt/created_testfile |
    Then the step should succeed

    # Delete pod and PVC to release the PV
    Given I run the :delete client command with:
      | object_type       | pod |
      | object_name_or_id | nfs |
    And I run the :delete client command with:
      | object_type       | pvc  |
      | object_name_or_id | nfsc |
    And the PV becomes :released

    # After PV is released, verify the created file in nfs export is reserved.
    When I execute on the "nfs-server" pod:
      | ls | /mnt/data/ |
    Then the output should contain:
      | created_testfile |
    And the PV status is :released
