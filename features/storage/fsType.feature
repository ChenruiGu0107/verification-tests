Feature: testing for parameter fsType
  # @author chaoyang@redhat.com
  # @author lxia@redhat.com
  # @case_id 499979 529377 529378
  # @case_id 530177 530178 530179
  # @case_id 530181 530182 530183
  @admin
  Scenario Outline: persistent volume formated with fsType
    Given I have a project
    And I have a 1 GB volume and save volume id in the :vid clipboard
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/<type>/security/<type>-selinux-fsgroup-test.json" replacing paths:
      | ["metadata"]["name"]                                      | pod-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"] | /mnt                    |
      | ["spec"]["securityContext"]["fsGroup"]                    | 24680                   |
      | ["spec"]["volumes"][0]["<storage_type>"]["<volume_name>"] | <%= cb.vid %>           |
      | ["spec"]["volumes"][0]["<storage_type>"]["fsType"]        | <fsType>                |
    Then the step should succeed
    And the pod named "pod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | mount |
    Then the step should succeed
    And the output should contain:
      | /mnt type <fsType> |
    When I execute on the pod:
      | touch | /mnt/testfile |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/testfile |
    Then the step should succeed

    Examples:
      | fsType | storage_type         | volume_name | type   |
      | ext3   | gcePersistentDisk    | pdName      | gce    |
      | ext4   | gcePersistentDisk    | pdName      | gce    |
      | xfs    | gcePersistentDisk    | pdName      | gce    |
      | ext3   | awsElasticBlockStore | volumeID    | ebs    |
      | ext4   | awsElasticBlockStore | volumeID    | ebs    |
      | xfs    | awsElasticBlockStore | volumeID    | ebs    |
      | ext3   | cinder               | volumeID    | cinder |
      | ext4   | cinder               | volumeID    | cinder |
      | xfs    | cinder               | volumeID    | cinder |
