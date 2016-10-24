Feature: storageClass related feature
  # @author lxia@redhat.com
  # @case_id 534820
  @admin
  @destructive
  Scenario: No dynamic provision when no storage class
    Given I have a project
    # "oc get storageclass -o yaml"
    # should not contain string 'kind: StorageClass' when there are no storageclass
    When I run the :get admin command with:
      | resource | storageclass |
      | o        | yaml         |
    Then the step should succeed
    And the output should not contain "kind: StorageClass"
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-without-annotations.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :pending
    Given 30 seconds have passed
    And the "pvc-<%= project.name %>" PVC status is :pending

  # @author lxia@redhat.com
  # @case_id 535042
  @admin
  @destructive
  Scenario Outline: No dynamic provision when no default storage class
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass.yaml" where:
      | ["metadata"]["name"]                                                            | sc-<%= project.name %>      |
      | ["provisioner"]                                                                 | kubernetes.io/<provisioner> |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | "false"                     |
    Then the step should succeed
    # "oc get storageclass -o yaml"
    # should contain string 'kind: StorageClass' when there are storageclass
    # should not contain string 'is-default-class: "true"' when there are no default storageclass
    When I run the :get admin command with:
      | resource | storageclass |
      | o        | yaml         |
    Then the step should succeed
    And the output should contain "kind: StorageClass"
    And the output should not contain:
      | is-default-class: "true" |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-without-annotations.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :pending
    Given 30 seconds have passed
    And the "pvc-<%= project.name %>" PVC status is :pending

    Examples:
      | provisioner |
      | gce-pd      |

  # @author lxia@redhat.com
  # @case_id 534816 534817
  @admin
  @destructive
  Scenario Outline: storage class provisioner
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/storageClass.yaml" where:
      | ["metadata"]["name"]                                                            | sc-<%= project.name %>      |
      | ["provisioner"]                                                                 | kubernetes.io/<provisioner> |
      | ["parameters"]["type"]                                                          | <type>                      |
      | ["parameters"]["zone"]                                                          | <zone>                      |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | <is-default>                |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["spec"]["accessModes"][0]                                             | ReadWriteOnce           |
      | ["spec"]["resources"]["requests"]["storage"]                           | <size>                  |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound
    And the expression should be true> pvc.capacity(user: user) == "<size>"
    And the expression should be true> pvc.access_modes(user: user)[0] == "ReadWriteOnce"
    And the expression should be true> pv(pvc.volume_name(user: user)).reclaim_policy(user: admin) == "Delete"
    # ToDo
    # check storage size info
    # check storage type info
    # check storage zone info
    # gcloud compute disks describe --zone <zone> diskNameViaPvInfo

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/iaas               |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=frontendhttp |
    When I execute on the pod:
      | ls | -ld | /mnt/iaas/ |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/iaas/testfile |
    Then the step should succeed
    Given I ensure "pod-<%= project.name %>" pod is deleted
    Given I ensure "pvc-<%= project.name %>" pvc is deleted
    And I wait for the resource "pv" named "<%= pvc.volume_name(user: user) %>" to disappear within 300 seconds

    Examples:
      | provisioner | type        | zone          | is-default | size |
      | gce-pd      | pd-ssd      | us-central1-a | false      | 1Gi  |
      | gce-pd      | pd-standard | us-central1-a | false      | 2Gi  |

  # @author lxia@redhat.com
  # @case_id 534824
  @admin
  @destructive
  Scenario: Do not allow creation of GCE PDs in unmanaged zones
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/storageClass.yaml" where:
      | ["metadata"]["name"]   | sc-<%= project.name %> |
      | ["parameters"]["zone"] | europe-west1-d         |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :pending
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc/pvc-<%= project.name %> |
    Then the output should contain:
      | ProvisioningFailed |
      | Failed to provision volume with StorageClass "sc-<%= project.name %>" |
      | does not manage zone "europe-west1-d" |
    """

  # @author lxia@redhat.com
  # @case_id 534825 534826
  @admin
  @destructive
  Scenario Outline: PVC request storage class with specific provisioner
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
      | ["provisioner"]      | <provisioner>          |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :pending
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc/pvc-<%= project.name %> |
    Then the output should contain:
      | <str1> |
      | <str2> |
    """
    And the "pvc-<%= project.name %>" PVC status is :pending

    Examples:
      | provisioner           | str1                 | str2 |
      | manual                | ExternalProvisioning | provisioned either manually or via external software |
      | kubernetes.io/unknown | ProvisioningFailed   | no volume plugin matched                             |
