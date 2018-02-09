Feature: Persistent Volume Recycling
  # @author lxia@redhat.com
  # @case_id OCP-9696
  @admin
  @destructive
  Scenario: Using configurable nfs recycler
    Given I have a project
    And I have a NFS service in the project
    When I execute on the pod:
      | chmod | g+w | /mnt/data |
    Then the step should succeed

    Given the "/etc/origin/master/my-recycler.json" path is removed on all masters after scenario
    Given I run commands on all masters:
      | curl -sS https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/pv-scrubber.json -o /etc/origin/master/my-recycler.json |
      | sed -i 's/127.0.0.1/<%= service("nfs-service").ip %>/' /etc/origin/master/my-recycler.json                                               |
    Given master config is merged with the following hash:
    """
    kubernetesMasterConfig:
      controllerArguments:
        pv-recycler-pod-template-filepath-nfs:
        - "/etc/origin/master/my-recycler.json"
        pv-recycler-minimum-timeout-nfs:
        - "300"
        pv-recycler-increment-timeout-nfs:
        - "30"
    """
    And the master service is restarted on all master nodes

    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv.json" where:
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |
      | ["metadata"]["name"]      | nfs-<%= project.name %>          |
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]   | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"] | nfs-<%= project.name %>  |
    Then the step should succeed
    And the "nfsc-<%= project.name %>" PVC becomes bound to the "nfs-<%= project.name %>" PV

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | nfsc-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod                    |
    Then the step should succeed

    Given the pod named "mypod" becomes ready

    When I execute on the pod:
      | touch | /mnt/.file1 | /mnt/.file2 | /mnt/file3 | /mnt/file4 |
    Then the step should succeed
    When I execute on the pod:
      | mkdir | -p | /mnt/.folder1 | /mnt/folder2 | /mnt/.folder3/.folder33 | /mnt/folder4/folder44 | /mnt/.folder5/folder55 | /mnt/folder6/.folder66 |
    Then the step should succeed

    Given I ensure "mypod" pod is deleted
    And I ensure "nfsc-<%= project.name %>" pvc is deleted
    And the PV becomes :available within 300 seconds
    When I execute on the "nfs-server" pod:
      | ls | -A | /mnt/data/ |
    Then the output should not contain:
      | file |
      | folder |

  # @author lxia@redhat.com
  # @case_id OCP-10519
  @admin
  @destructive
  Scenario: Recycler using pod template without volume should fail with error
    Given the "/etc/origin/master/my-recycler.json" path is removed on all masters after scenario
    Given I run commands on all masters:
      | curl -sS https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/pv-recycler-invalid.json -o /etc/origin/master/my-recycler.json |
    Given master config is merged with the following hash:
    """
    kubernetesMasterConfig:
      controllerArguments:
        pv-recycler-pod-template-filepath-nfs:
        - "/etc/origin/master/my-recycler.json"
        pv-recycler-minimum-timeout-nfs:
        - "300"
        pv-recycler-increment-timeout-nfs:
        - "30"
        pv-recycler-pod-template-filepath-hostpath:
        - "/etc/origin/master/my-recycler.json"
        pv-recycler-minimum-timeout-hostpath:
        - "60"
        pv-recycler-timeout-increment-hostpath:
        - "30"
    """
    And the master service is restarted on all master nodes
    Given I use the first master host
    When I run commands on the host:
      | journalctl -l --since "5 min ago" \| grep '/etc/origin/master/my-recycler.json' |
    Then the step should succeed
    And the output should contain:
      | not contain any volume |

  # @author lxia@redhat.com
  # @case_id OCP-9637
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
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv.json" where:
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |
      | ["metadata"]["name"]      | nfs-<%= project.name %>          |
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]   | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"] | nfs-<%= project.name %>  |
    Then the step should succeed
    And the "nfsc-<%= project.name %>" PVC becomes bound to the "nfs-<%= project.name %>" PV

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | nfsc-<%= project.name %>  |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
    Then the step should succeed

    Given the pod named "mypod-<%= project.name %>" becomes ready

    When I execute on the pod:
      | df |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/.file1 | /mnt/.file2 | /mnt/file3 | /mnt/file4 |
    Then the step should succeed
    When I execute on the pod:
      | mkdir | -p | /mnt/.folder1 | /mnt/folder2 | /mnt/.folder3/.folder33 | /mnt/folder4/folder44 | /mnt/.folder5/folder55 | /mnt/folder6/.folder66 |
    Then the step should succeed

    Given I ensure "mypod-<%= project.name %>" pod is deleted
    And I ensure "nfsc-<%= project.name %>" pvc is deleted
    And the PV becomes :available within 300 seconds
    When I execute on the "nfs-server" pod:
      | ls | -A | /mnt/data/ |
    Then the output should not contain:
      | file |
      | folder |
