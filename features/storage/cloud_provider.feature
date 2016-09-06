Feature: kubelet restart and node restart
  # @author lxia@redhat.com
  # @case_id 532742 532741 532740
  @admin
  @destructive
  Scenario Outline: kubelet restart should not affect attached/mounted volumes
    # create project with node selector
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :oadm_new_project admin command with:
      | project_name  | <%= cb.proj_name %>         |
      | node_selector | <%= cb.proj_name %>=restart |
      | admin         | <%= user.name %>            |
    Then the step should succeed

    # label node
    Given I store the schedulable nodes in the :nodes clipboard
    And label "<%= cb.proj_name %>=restart" is added to the "<%= cb.nodes[0].name %>" node

    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.proj_name %>" project

    # create dynamic pvc
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | dynamic-pvc1-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce                    |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                              |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | dynamic-pvc2-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteMany                    |
      | ["spec"]["resources"]["requests"]["storage"] | 2Gi                              |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | dynamic-pvc3-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadOnlyMany                     |
      | ["spec"]["resources"]["requests"]["storage"] | 3Gi                              |
    Then the step should succeed
    And the "dynamic-pvc1-<%= project.name %>" PVC becomes :bound
    And the "dynamic-pvc2-<%= project.name %>" PVC becomes :bound
    And the "dynamic-pvc3-<%= project.name %>" PVC becomes :bound

    When I run the :get admin command with:
      | resource | pv |
    Then the output should contain:
      | dynamic-pvc1-<%= project.name %> |
      | dynamic-pvc2-<%= project.name %> |
      | dynamic-pvc3-<%= project.name %> |

    # create pod using above pvc
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc1-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod1                           |
      | ["spec"]["containers"][0]["volumeMounts"]["mountPath"]       | /mnt/<platform>                  |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc2-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod2                           |
      | ["spec"]["containers"][0]["volumeMounts"]["mountPath"]       | /mnt/<platform>                  |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc3-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod3                           |
      | ["spec"]["containers"][0]["volumeMounts"]["mountPath"]       | /mnt/<platform>                  |
    Then the step should succeed

    # write to the mounted storage
    Given the pod named "mypod1" becomes ready
    When I execute on the pod:
      | touch | /mnt/<platform>/testfile_before_restart_1 |
    Then the step should succeed
    Given the pod named "mypod2" becomes ready
    When I execute on the pod:
      | touch | /mnt/<platform>/testfile_before_restart_2 |
    Then the step should succeed
    Given the pod named "mypod3" becomes ready
    When I execute on the pod:
      | touch | /mnt/<platform>/testfile_before_restart_3 |
    Then the step should succeed

    # restart kubelet on the node
    Given I use the "<%= cb.nodes[0].name %>" node
    And the node service is restarted on the host

    # verify previous created files still exist
    When I execute on the "mypod1" pod:
      | ls | /mnt/<platform>/testfile_before_restart_1 |
    Then the step should succeed
    When I execute on the "mypod2" pod:
      | ls | /mnt/<platform>/testfile_before_restart_2 |
    Then the step should succeed
    When I execute on the "mypod3" pod:
      | ls | /mnt/<platform>/testfile_before_restart_3 |
    Then the step should succeed

    # write to the mounted storage
    When I execute on the "mypod1" pod:
      | touch | /mnt/<platform>/testfile_after_restart_1 |
    Then the step should succeed
    When I execute on the "mypod2" pod:
      | touch | /mnt/<platform>/testfile_after_restart_2 |
    Then the step should succeed
    When I execute on the "mypod3" pod:
      | touch | /mnt/<platform>/testfile_after_restart_3 |
    Then the step should succeed

    Examples:
      | platform |
      | gce      |
      | cinder   |
      | aws      |

  # @author lxia@redhat.com
  # @case_id 533194 533193 533192
  @admin
  @destructive
  Scenario Outline: node restart should not affect attached/mounted volumes
    # create project with node selector
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :oadm_new_project admin command with:
      | project_name  | <%= cb.proj_name %>         |
      | node_selector | <%= cb.proj_name %>=restart |
      | admin         | <%= user.name %>            |
    Then the step should succeed

    # label node
    Given I store the schedulable nodes in the :nodes clipboard
    And label "<%= cb.proj_name %>=restart" is added to the "<%= cb.nodes[0].name %>" node

    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.proj_name %>" project

    # create dynamic pvc
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | dynamic-pvc1-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce                    |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                              |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | dynamic-pvc2-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteMany                    |
      | ["spec"]["resources"]["requests"]["storage"] | 2Gi                              |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | dynamic-pvc3-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadOnlyMany                     |
      | ["spec"]["resources"]["requests"]["storage"] | 3Gi                              |
    Then the step should succeed
    And the "dynamic-pvc1-<%= project.name %>" PVC becomes :bound
    And the "dynamic-pvc2-<%= project.name %>" PVC becomes :bound
    And the "dynamic-pvc3-<%= project.name %>" PVC becomes :bound

    When I run the :get admin command with:
      | resource | pv |
    Then the output should contain:
      | dynamic-pvc1-<%= project.name %> |
      | dynamic-pvc2-<%= project.name %> |
      | dynamic-pvc3-<%= project.name %> |

    # create pod using above pvc
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc1-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod1                           |
      | ["spec"]["containers"][0]["volumeMounts"]["mountPath"]       | /mnt/<platform>                  |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc2-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod2                           |
      | ["spec"]["containers"][0]["volumeMounts"]["mountPath"]       | /mnt/<platform>                  |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc3-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod3                           |
      | ["spec"]["containers"][0]["volumeMounts"]["mountPath"]       | /mnt/<platform>                  |
    Then the step should succeed

    # write to the mounted storage
    Given the pod named "mypod1" becomes ready
    When I execute on the pod:
      | touch | /mnt/<platform>/testfile_before_restart_1 |
    Then the step should succeed
    Given the pod named "mypod2" becomes ready
    When I execute on the pod:
      | touch | /mnt/<platform>/testfile_before_restart_2 |
    Then the step should succeed
    Given the pod named "mypod3" becomes ready
    When I execute on the pod:
      | touch | /mnt/<platform>/testfile_before_restart_3 |
    Then the step should succeed

    # restart node
    Given I use the "<%= cb.nodes[0].name %>" node
    And the host is rebooted and I wait it to become available

    # verify previous created files still exist
    When I execute on the "mypod1" pod:
      | ls | /mnt/<platform>/testfile_before_restart_1 |
    Then the step should succeed
    When I execute on the "mypod2" pod:
      | ls | /mnt/<platform>/testfile_before_restart_2 |
    Then the step should succeed
    When I execute on the "mypod3" pod:
      | ls | /mnt/<platform>/testfile_before_restart_3 |
    Then the step should succeed

    # write to the mounted storage
    When I execute on the "mypod1" pod:
      | touch | /mnt/<platform>/testfile_after_restart_1 |
    Then the step should succeed
    When I execute on the "mypod2" pod:
      | touch | /mnt/<platform>/testfile_after_restart_2 |
    Then the step should succeed
    When I execute on the "mypod3" pod:
      | touch | /mnt/<platform>/testfile_after_restart_3 |
    Then the step should succeed

    Examples:
      | platform |
      | gce      |
      | cinder   |
      | aws      |
