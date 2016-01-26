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
        Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/pv-invalid-path.json" where:
          | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |
        When I run the :create client command with:
          | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc.json |
        Then the step should succeed

        Given the PV becomes :bound

        When I run the :create client command with:
          | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json |
        Then the step should succeed
        When I run the :get client command with:
          | resource | pod/nfs |
        Then the output should not contain:
          | Running |
        Given I wait for the steps to pass:
        """
        When I run the :describe client command with:
          | resource | pod |
          | name     | nfs |
        Then the output should contain:
          | Unable to mount volumes for pod |
          | Mount failed: exit status       |
          | Mounting arguments              |
        """

        Given I run the :delete client command with:
          | object_type       | pod |
          | object_name_or_id | nfs |
        And I run the :delete client command with:
          | object_type       | pvc  |
          | object_name_or_id | nfsc |
        Then the step should succeed

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
        Given I wait for the steps to pass:
        """
        Then the PV becomes :available
        """

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
        Given I wait for the steps to pass:
        """
        Then the PV becomes :released
        """
