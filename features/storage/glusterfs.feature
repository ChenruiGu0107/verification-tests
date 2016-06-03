Feature: Storage of GlusterFS plugin testing

  # @author wehe@redhat.com
  # @case_id 522140
  @admin
  @destructive
  Scenario: Gluster storage testing with Invalid gluster endpoint
    Given I have a project

    #Create a invlid endpoint
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/endpoints.json"
    And I replace content in "endpoints.json":
      |/\d{2}/|11|
    And I run the :create client command with:
      | f | endpoints.json |
    Then the step should succeed
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/pv-retain-rwo.json" where:
      | ["metadata"]["name"] | gluster-<%= project.name %> |
    Then the step should succeed

    #Create gluster pvc
    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/claim-rwo.json |
    Then the step should succeed
    And the PV becomes :bound

    #Creat the pod
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/pod.json |
    Then the step should succeed
    And I wait up to 500 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pods |
      | name | gluster |
    Then the output should contain:
      | FailedMount |
      | glusterfs: mount failed |
    """

  # @author lxia@redhat.com
  # @case_id 508054
  @admin
  @destructive
  Scenario: GlusterFS volume plugin with RWO access mode and Retain policy
    Given I have a project
    And I have a Gluster service in the project
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I execute on the pod:
      | chmod | g+w | /vol |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/endpoints.json" replacing paths:
      | ["metadata"]["name"]                 | glusterfs-cluster             |
      | ["subsets"][0]["addresses"][0]["ip"] | <%= service("glusterd").ip %> |
      | ["subsets"][0]["ports"][0]["port"]   | 24007                         |
    Then the step should succeed
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/pv-retain-rwo.json" where:
      | ["metadata"]["name"]                      | pv-gluster-<%= project.name %> |
      | ["spec"]["accessModes"][0]                | ReadWriteOnce                  |
      | ["spec"]["glusterfs"]["endpoints"]        | glusterfs-cluster              |
      | ["spec"]["glusterfs"]["path"]             | testvol                        |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Retain                         |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]       | pvc-gluster-<%= project.name %> |
      | ["spec"]["accessModes"][0] | ReadWriteOnce                   |
      | ["spec"]["volumeName"]     | pv-gluster-<%= project.name %>  |
    Then the step should succeed
    And the PV becomes :bound
    And the "pvc-gluster-<%= project.name %>" PVC becomes :bound

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | mypod-<%= project.name %>        |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-gluster-<%= project.name %>  |
    Then the step should succeed
    Given the pod named "mypod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | ls | -ld | /mnt/gluster |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/gluster/tc508054 |
    Then the step should succeed

    When I run the :delete client command with:
      | object_type       | pod                       |
      | object_name_or_id | mypod-<%= project.name %> |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | pvc                             |
      | object_name_or_id | pvc-gluster-<%= project.name %> |
    Then the step should succeed
    And the PV becomes :released
    When I execute on the "glusterd" pod:
      | ls | /vol/tc508054 |
    Then the step should succeed
    And the PV becomes :released

  # @author chaoyang@redhat.com
  # @case_id 510730
  @admin @destructive
  Scenario: Glusterfs volume security testing
    Given I have a project
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    Given I have a Gluster service in the project
    When I execute on the pod:
      | chown | -R | root:123456 | /vol|
    Then the step should succeed
    And I execute on the pod:
      | chmod | -R | 770 | /vol |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/endpoints.json" replacing paths:
      | ["metadata"]["name"]                 | glusterfs-cluster             |
      | ["subsets"][0]["addresses"][0]["ip"] | <%= service("glusterd").ip %> |
      | ["subsets"][0]["ports"][0]["port"]   | 24007                         |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/security/gluster_pod_sg.json" replacing paths:
      | ["metadata"]["name"]                    | glusterpd-<%= project.name %>   |
    Then the step should succeed

    Given the pod named "glusterpd-<%= project.name %>" becomes ready
    And I execute on the "glusterpd-<%= project.name %>" pod:
      | ls | /mnt/glusterfs |
    Then the step should succeed

    And I execute on the "glusterpd-<%= project.name %>" pod:
      | touch | /mnt/glusterfs/gluster_testfile |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/security/gluster_pod_sg.json" replacing paths:
      | ["metadata"]["name"]                               | glusterpd-negative-<%= project.name %>   |
      | ["spec"]["securityContext"]["supplementalGroups"]  | [123460]                                 |
    Then the step should succeed
    Given the pod named "glusterpd-negative-<%= project.name %>" becomes ready
    And I execute on the "glusterpd-negative-<%= project.name %>" pod:
      | ls | /mnt/glusterfs |
    Then the step should fail
    Then the outputs should contain:
      | Permission denied  |

    And I execute on the "glusterpd-negative-<%= project.name %>" pod:
      | touch | /mnt/glusterfs/gluster_testfile |
    Then the step should fail
    Then the outputs should contain:
      | Permission denied  |

  # @author jhou@redhat.com
  # @case_id 484932
  @admin
  @destructive
  Scenario: Pod references GlusterFS volume directly from its template
    Given I have a project
    And I have a Gluster service in the project

    # Create endpoint
    And I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-gluster/master/endpoints.json" replacing paths:
      | ["subsets"][0]["addresses"][0]["ip"] | <%= service("glusterd").ip %> |

    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/docker-gluster/master/pod-direct.json |
    Then the step should succeed
    And the pod named "gluster" becomes ready
