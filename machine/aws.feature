Feature: AWS machine specific features testing

  # @author zhsun@redhat.com
  # @case_id OCP-37915
  @admin
  @destructive
  Scenario: Creating machines using KMS keys from AWS
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And admin ensures machine number is restored after scenario
    And I pick a random machineset to scale

    # Create a machineset
    Given I get project machineset named "<%= machine_set.name %>" as YAML 
    And I save the output to file> machineset-clone-37915.yaml
    And I replace content in "machineset-clone-37915.yaml":
      | <%= machine_set.name %> | machineset-clone-37915 |
      | /replicas.*/            | replicas: 0            |

    When I run the :create admin command with:
      | f | machineset-clone-37915.yaml |
    Then the step should succeed
    And admin ensures "machineset-clone-37915" machineset is deleted after scenario

    Given as admin I successfully merge patch resource "machineset/machineset-clone-37915" with:
      | {"spec":{"replicas": 1,"template": {"spec":{"providerSpec":{"value":{"blockDevices": [{"ebs":{"encrypted":true,"iops":0,"kmsKey":{"arn":"arn:aws:kms:us-east-2:301721915996:key/c228ef83-df2c-4151-84c4-d9f39f39a972"},"volumeSize":120,"volumeType":"gp2"}}]}}}}}} |

    # Verify machine could be created successful
    And I wait up to 300 seconds for the steps to pass:
    """ 
    Then the expression should be true> machine_set("machineset-clone-37915").desired_replicas(cached: false) == 1
    """ 
    Then the machineset should have expected number of running machines

  # @author zhsun@redhat.com
  # @case_id OCP-35513
  @admin
  @destructive
  Scenario: Windows machine should successfully provision for aws
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And admin ensures machine number is restored after scenario
    And I pick a random machineset to scale

    # Create a machineset 
    Given I run the :get admin command with:
      | resource      | machineset              |
      | resource_name | <%= machine_set.name %> |
      | o             | yaml                    |
    Then the step should succeed
    And I save the output to file> machineset-clone-35513.yaml
    And I replace content in "machineset-clone-35513.yaml":
      | <%= machine_set.name %> | win-35513                 |
      | /id: ami.*/             | id: ami-0c7a9c9d17f8a5b64 |
      | /replicas.*/            | replicas: 0               |

    When I run the :create admin command with:
      | f | machineset-clone-35513.yaml |
    Then the step should succeed
    And admin ensures "win-35513" machineset is deleted after scenario

    Given as admin I successfully merge patch resource "machineset/win-35513" with:
      | {"spec":{"replicas": 1,"template":{"metadata":{"labels":{"machine.openshift.io/os-id": "Windows"}}}}} |

    # Verify machine could be created successful
    Given I store the last provisioned machine in the :win_machine clipboard
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> machine(cb.win_machine).phase(cached: false) == "Provisioned"
    """

  # @author zhsun@redhat.com
  # @case_id OCP-32122
  @admin
  @destructive
  Scenario: AWS Machine API Support of more than one block device
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And admin ensures machine number is restored after scenario
    And I pick a random machineset to scale

    When I get project machineset named "<%= machine_set.name %>" as YAML
    And I save the output to file> machineset-clone-32122.yaml
    And I replace content in "machineset-clone-32122.yaml":
      | <%= machine_set.name %> | machineset-clone-32122 |
      | /replicas.*/            | replicas: 0            |

    When I run the :create admin command with:
      | f | machineset-clone-32122.yaml |
    Then the step should succeed
    And admin ensures "machineset-clone-32122" machineset is deleted after scenario
    
    # Add another two block devices
    Given as admin I successfully merge patch resource "machineset/machineset-clone-32122" with:
      | {"spec":{"replicas": 1,"template": {"spec":{"providerSpec":{"value":{"blockDevices": [{"deviceName":"/dev/sdf","ebs":{"encrypted":true,"iops":0,"kmsKey":{"arn":""},"volumeSize":120,"volumeType":"gp2"}},{"deviceName":"/dev/sdg","ebs":{"encrypted":true,"iops":0,"kmsKey":{"arn":""},"volumeSize":120,"volumeType":"gp2"}},{"ebs":{"encrypted":true,"iops":0,"kmsKey":{"arn":""},"volumeSize":120,"volumeType":"gp2"}}]}}}}}} |
    And I wait up to 300 seconds for the steps to pass:
    """ 
    Then the expression should be true> machine_set("machineset-clone-32122").desired_replicas(cached: false) == 1
    """ 
    Then the machineset should have expected number of running machines

    # Check another two devices are attached
    Given I store the last provisioned machine in the :machine clipboard
    And evaluation of `machine(cb.machine).node_name` is stored in the :noderef_name clipboard
    When I run the :debug client command with:
      | resource     | node/<%= cb.noderef_name %> |
      | oc_opts_end  |                             |
      | exec_command | lsblk                       |
    Then the step should succeed
    And the output should match 3 times:
      | 120G |