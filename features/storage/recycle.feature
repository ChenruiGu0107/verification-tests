Feature: Persistent Volume Recycling

    # @author lxia@redhat.com
    # @case_id 507675
    @admin
    @destructive
    Scenario: PV recycling should work fine when there are dot files/dirs
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
          | df |
        Then the step should succeed
        When I execute on the pod:
          | touch | /mnt/.file1 | /mnt/.file2 | /mnt/file3 | /mnt/file4 |
        Then the step should succeed
        When I execute on the pod:
          | mkdir | -p | /mnt/.folder1 | /mnt/folder2 | /mnt/.folder3/.folder33 | /mnt/folder4/folder44 | /mnt/.folder5/folder55 | /mnt/folder6/.folder66 |
        Then the step should succeed

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

        When I run the :exec client command with:
          | pod | nfs-server |
          | oc_opts_end | |
          | exec_command | ls |
          | exec_command_arg | -a |
          | exec_command_arg | /mnt/data/ |
        Then the output should not contain:
          | file |
          | folder |

