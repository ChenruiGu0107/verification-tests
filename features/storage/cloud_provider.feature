Feature: kubelet restart and node restart
  # @author lxia@redhat.com
  # @case_id OCP-11613 OCP-11317 OCP-10907
  @admin
  @destructive
  Scenario Outline: kubelet restart should not affect attached/mounted volumes
    Given admin creates a project with a random schedulable node selector 
    And evaluation of `%w{ReadWriteOnce ReadWriteMany ReadOnlyMany}` is stored in the :accessmodes clipboard
    And I run the steps 3 times:
    """
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | dynamic-pvc-#{cb.i}       |
      | ["spec"]["accessModes"][0]                   | #{cb.accessmodes[cb.i-1]} |
      | ["spec"]["resources"]["requests"]["storage"] | #{cb.i}Gi                 |   
    Then the step should succeed
    And the "dynamic-pvc-#{cb.i}" PVC becomes :bound
    When I run the :get admin command with:
      | resource | pv |
    Then the output should contain:
      | dynamic-pvc-#{cb.i} |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc-#{cb.i} |
      | ["metadata"]["name"]                                         | mypod#{cb.i}        |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/<platform>     |
    Then the step should succeed
    Given the pod named "mypod#{cb.i}" becomes ready
    When I execute on the pod:
      | touch | /mnt/<platform>/testfile_before_restart_#{cb.i} |
    Then the step should succeed
    """
    # restart kubelet on the node
    Given I use the "<%= node.name %>" node
    And the node service is restarted on the host
    # verify previous created files still exist
    And I wait up to 120 seconds for the steps to pass:
    """
    # verify previous created files still exist
    Given I run the steps 3 times:
    <%= '"'*3 %> 
    When I execute on the "mypod#{cb.i}" pod:
      | ls | /mnt/<platform>/testfile_before_restart_#{cb.i} |
    Then the step should succeed
    # write to the mounted storage
    When I execute on the "mypod#{cb.i}" pod:
      | touch | /mnt/<platform>/testfile_after_restart_#{cb.i} |
    Then the step should succeed
    <%= '"'*3 %> 
    """

    Examples:
      | platform |
      | gce      |
      | cinder   |
      | aws      |

  # @author lxia@redhat.com
  # @case_id OCP-11620 OCP-11330 OCP-10919
  @admin
  @destructive
  Scenario Outline: node restart should not affect attached/mounted volumes
    Given admin creates a project with a random schedulable node selector 
    And evaluation of `%w{ReadWriteOnce ReadWriteMany ReadOnlyMany}` is stored in the :accessmodes clipboard
    And I run the steps 3 times:
    """
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | dynamic-pvc-#{cb.i}       |
      | ["spec"]["accessModes"][0]                   | #{cb.accessmodes[cb.i-1]} |
      | ["spec"]["resources"]["requests"]["storage"] | #{cb.i}Gi                 |   
    Then the step should succeed
    And the "dynamic-pvc-#{cb.i}" PVC becomes :bound
    When I run the :get admin command with:
      | resource | pv |
    Then the output should contain:
      | dynamic-pvc-#{cb.i} |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc-#{cb.i} |
      | ["metadata"]["name"]                                         | mypod#{cb.i}        |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/<platform>     |
    Then the step should succeed
    Given the pod named "mypod#{cb.i}" becomes ready
    When I execute on the pod:
      | touch | /mnt/<platform>/testfile_before_restart_#{cb.i} |
    Then the step should succeed
    """
    # restart node
    Given I use the "<%= node.name %>" node
    And the host is rebooted and I wait it to become available
    # verify previous created files still exist
    And I wait up to 120 seconds for the steps to pass:
    """
    # verify previous created files still exist
    Given I run the steps 3 times:
    <%= '"'*3 %> 
    When I execute on the "mypod#{cb.i}" pod:
      | ls | /mnt/<platform>/testfile_before_restart_#{cb.i} |
    Then the step should succeed
    # write to the mounted storage
    When I execute on the "mypod#{cb.i}" pod:
      | touch | /mnt/<platform>/testfile_after_restart_#{cb.i} |
    Then the step should succeed
    <%= '"'*3 %> 
    """

    Examples:
      | platform |
      | gce      |
      | cinder   |
      | aws      |

  # @author wehe@redhat.com
  # @case_id OCP-13333
  @admin
  @destructive
  Scenario: azureDisk kubelet restart should not affect attached/mounted volume 
    Given admin creates a project with a random schedulable node selector 
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azsc-NOPAR.yaml" where:
      | ["metadata"]["name"]      | sc-<%= project.name %> |
    Then the step should succeed
    Given evaluation of `%w{ReadWriteOnce ReadWriteMany ReadOnlyMany}` is stored in the :accessmodes clipboard
    And I run the steps 3 times:
    """
    When I run oc create over "https://raw.githubusercontent.com/weherdh/v3-testfiles/azsc/persistent-volumes/azure/azpvc-sc.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | dpvc-#{cb.i}              |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>    |
      | ["spec"]["accessModes"][0]                                             | #{cb.accessmodes[cb.i-1]} |
      | ["spec"]["resources"]["requests"]["storage"]                           | #{cb.i}Gi                 |   
    Then the step should succeed
    And the "dpvc-#{cb.i}" PVC becomes :bound
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvcpod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dpvc-#{cb.i} |
      | ["metadata"]["name"]                                         | mypod#{cb.i} |
    Then the step should succeed
    And the pod named "mypod#{cb.i}" becomes ready
    When I execute on the pod:
      | touch | /mnt/azure/testfile_before_restart_#{cb.i} |
    Then the step should succeed
    """
    # restart kubelet on the node
    Given I use the "<%= node.name %>" node
    And the node service is restarted on the host
    And I wait up to 120 seconds for the steps to pass:
    """
    # verify previous created files still exist
    Given I run the steps 3 times:
    <%= '"'*3 %> 
    When I execute on the "mypod#{cb.i}" pod:
      | ls | /mnt/azure/testfile_before_restart_#{cb.i} |
    Then the step should succeed
    # write to the mounted storage
    When I execute on the "mypod#{cb.i}" pod:
      | touch | /mnt/azure/testfile_after_restart_#{cb.i} |
    Then the step should succeed
    <%= '"'*3 %> 
    """

  # @author wehe@redhat.com
  # @case_id OCP-13435
  @admin
  @destructive
  Scenario: azureDisk node restart should not affect attached/mounted volumes 
    Given admin creates a project with a random schedulable node selector 
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azsc-NOPAR.yaml" where:
      | ["metadata"]["name"]      | sc-<%= project.name %> |
    Then the step should succeed
    Given evaluation of `%w{ReadWriteOnce ReadWriteMany ReadOnlyMany}` is stored in the :accessmodes clipboard
    And I run the steps 3 times:
    """
    When I run oc create over "https://raw.githubusercontent.com/weherdh/v3-testfiles/azsc/persistent-volumes/azure/azpvc-sc.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | dpvc-#{cb.i}              |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>    |
      | ["spec"]["accessModes"][0]                                             | #{cb.accessmodes[cb.i-1]} |
      | ["spec"]["resources"]["requests"]["storage"]                           | #{cb.i}Gi                 |
    Then the step should succeed
    And the "dpvc-#{cb.i}" PVC becomes :bound
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvcpod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dpvc-#{cb.i} |
      | ["metadata"]["name"]                                         | mypod#{cb.i} |
    Then the step should succeed
    And the pod named "mypod#{cb.i}" becomes ready
    When I execute on the pod:
      | touch | /mnt/azure/testfile_before_restart_#{cb.i} |
    Then the step should succeed
    """
    # restart kubelet on the node
    Given I use the "<%= node.name %>" node
    And the host is rebooted and I wait it to become available
    And I wait up to 120 seconds for the steps to pass:
    """
    # verify previous created files still exist
    Given I run the steps 3 times:
    <%= '"'*3 %> 
    When I execute on the "mypod#{cb.i}" pod:
      | ls | /mnt/azure/testfile_before_restart_#{cb.i} |
    Then the step should succeed
    # write to the mounted storage
    When I execute on the "mypod#{cb.i}" pod:
      | touch | /mnt/azure/testfile_after_restart_#{cb.i} |
    Then the step should succeed
    <%= '"'*3 %> 
    """
