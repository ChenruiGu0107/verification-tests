Feature: Persistent Volume reclaim policy tests

    # @author jhou@redhat.com
    # @case_id 488979
    @admin
    Scenario: Recycle reclaim policy for persistent volumes
        # Preparations
        Given I have a project
        And I have a NFS service in the project

        # Creating PV and PVC
        Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv.json"
        And I replace content in "pv.json":
            | #NFS-Service-IP# | <%= service("nfs-service").ip %> |
        And I run the :create admin command with:
            | f | pv.json |
        And I run the :create client command with:
            | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc.json |
        When I run the :get admin command with:
            | resource | pv/nfs |
        Then the output should contain:
            | Bound |

        Given I run the :create client command with:
            | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json |
        And the pod named "nfs" becomes ready
        When I run the :get client command with:
            | resource | pod/nfs |
        Then the output should contain:
            | Running |

        Given I run the :delete client command with:
            | object_type       | pod |
            | object_name_or_id | nfs |
        And I run the :delete client command with:
            | object_type       | pvc  |
            | object_name_or_id | nfsc |
        And 60 seconds have passed
        When I run the :get admin command with:
            | resource | pv/nfs |
        Then the output should contain:
            | Available |

        And I run the :delete admin command with:
            | object_type       | pv  |
            | object_name_or_id | nfs |
