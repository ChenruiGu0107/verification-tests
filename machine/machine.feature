Feature: Machine features testing

  # @author jhou@redhat.com
  @admin
  Scenario Outline: Machines phase should become 'Failed' when it has create error
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And I pick a random machineset to scale

    # Create an invalid machineset
    Given I run the :get admin command with:
      | resource      | machineset              |
      | resource_name | <%= machine_set.name %> |
      | namespace     | openshift-machine-api   |
      | o             | yaml                    |
    Then the step should succeed
    And I save the output to file> machineset-invalid.yaml
    And I replace content in "machineset-invalid.yaml":
      | <%= machine_set.name %> | machineset-invalid |
      | <valid_field>           | <invalid_value>    |
      | /replicas:.*/           | replicas: 1        |

    When I run the :create admin command with:
      | f | machineset-invalid.yaml |
    Then the step should succeed
    And admin ensures "machineset-invalid" machineset is deleted after scenario

    # Verified machine has 'Failed' phase
    Given I store the last provisioned machine in the :invalid_machine clipboard
    And I wait up to 60 seconds for the steps to pass:
    """
    Then the expression should be true> machine(cb.invalid_machine).phase(cached: false) == "Failed"
    """

    # Verify alert is fired
    Given I wait up to 180 seconds for the steps to pass:
    """
    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query?                                |
      | query | ALERTS{alertname="MachineWithNoRunningPhase"} |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["data"]["result"][0]["metric"]["alertstate"] =~ /pending|firing/

    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query?                              |
      | query | ALERTS{alertname="MachineWithoutValidNode"} |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["data"]["result"][0]["metric"]["alertstate"] =~ /pending|firing/
    """

    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query?              |
      | query | mapi_instance_create_failed |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["status"] == "success"
    And the expression should be true> @result[:parsed]["data"]["result"][0]["metric"]["__name__"] == "mapi_instance_create_failed"

    Examples:
      | valid_field       | invalid_value         |
      | /machineType:.*/  | machineType: invalid  | # @case_id OCP-25927
      | /instanceType:.*/ | instanceType: invalid | # @case_id OCP-28817
      | /vmSize:.*/       | vmSize: invalid       | # @case_id OCP-28818
      | /flavor:.*/       | flavor: invalid       | # @case_id OCP-28916
      | /folder:.*/       | folder: invalid       | # @case_id OCP-28971

  # @author zhsun@redhat.com
  # @case_id OCP-29351
  Scenario Outline: Use oc explain to see detailed documentation of the resources
    When I run the :explain client command with:
      | resource | <resource> |
    Then the step should succeed
    And the output should contain:
      | apiVersion |
    And the output should not contain:
      | <empty> |
      | <none>  |

    Examples:
      | resource           |
      | machine            |
      | machineset         |
      | machinehealthcheck |
      | clusterautoscaler  |
      | machineautoscaler  |

  # @author zhsun@redhat.com
  # @case_id OCP-30257
  @admin
  Scenario Outline: Cluster-reader should be able to view machine resources	
    Given cluster role "cluster-reader" is added to the "first" user 
    Given I switch to the first user
    Then I use the "openshift-machine-api" project

    When I run the :get client command with:
      | resource | <resource> |
    Then the step should succeed
    And the output should not contain:
      | Error |

    Examples:
      | resource           |
      | machine            |
      | machineset         |
      | machinehealthcheck |
      | clusterautoscaler  |
      | machineautoscaler  |

  # @author zhsun@redhat.com
  # @case_id OCP-30836
  @admin
  @destructive
  Scenario: Specify a delete policy in the spec of the machineset
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And admin ensures machine number is restored after scenario

    Given I clone a machineset and name it "machineset-clone-30836"
    Given I store the last provisioned machine in the :oldest_machine clipboard

    # scale up machine with replicas=3
    Given I scale the machineset to +2
    Then the step should succeed
    And the machineset should have expected number of running machines
    Given I store the last provisioned machine in the :newest_machine clipboard

    # deletePolicy - Newest
    Given as admin I successfully merge patch resource "machineset/machineset-clone-30836" with:
      | {"spec":{"deletePolicy": "Newest" }} |

    When I scale the machineset to -1
    Then the step should succeed
    And the machineset should have expected number of running machines
    And the machine named "<%= cb.newest_machine %>" does not exist

    # deletePolicy - Oldest
    Given as admin I successfully merge patch resource "machineset/machineset-clone-30836" with:
      | {"spec":{"deletePolicy": "Oldest" }} |

    When I scale the machineset to -1
    Then the step should succeed
    And the machineset should have expected number of running machines
    And the machine named "<%= cb.oldest_machine %>" does not exist

  # @author miyadav@redhat.com
  # @case_id OCP-29344
  @admin
  Scenario: Validation of `oc adm inspect co/xx` command
    Given I switch to cluster admin pseudo user
    Then I saved following keys to list in :resourcesid clipboard:
      | machine-api        | |
      | cluster-autoscaler | |

    And I use the "openshift-machine-api" project
    Then I repeat the following steps for each :id in cb.resourcesid:
    """
    When I run the :oadm_inspect admin command with:
      | resource_type | co       |
      | resource_name | #{cb.id} |
    And the step should succeed
    Then the output should contain "Wrote inspect data to inspect.local"
    """
    
  # @author zhsun@redhat.com
  # @case_id OCP-32392
  @admin
  @destructive
  Scenario: Create windows VM using machineset on Azure
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And admin ensures machine number is restored after scenario
    And I pick a random machineset to scale

    # Create a machineset 
    Given I run the :get admin command with:
      | resource      | machineset              |
      | resource_name | <%= machine_set.name %> |
      | namespace     | openshift-machine-api   |
      | o             | yaml                    |
    Then the step should succeed
    And I save the output to file> machineset-clone-32392.yaml
    And I replace content in "machineset-clone-32392.yaml":
      | <%= machine_set.name %> | win-32392                         |
      | /osType.*/              | osType: Windows                   |
      | /offer.*/               | offer: WindowsServer              |
      | /publisher.*/           | publisher: MicrosoftWindowsServer |
      | /sku.*/                 | sku: 2019-Datacenter              |
      | /version.*/             | version: latest                   |
      | /resourceID.*/          | resourceID: ""                    |
      | /replicas.*/            | replicas: 1                       |

    When I run the :create admin command with:
      | f | machineset-clone-32392.yaml |
    Then the step should succeed
    And admin ensures "win-32392" machineset is deleted after scenario

    # Verify machine could be created successful
    Given I store the last provisioned machine in the :win_machine clipboard
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> machine(cb.win_machine).phase(cached: false) == "Provisioned"
    """

  # @author zhsun@redhat.com
  # @case_id OCP-34313
  @admin
  Scenario Outline: Warning appears when creating windows VM using invalid values
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And I pick a random machineset to scale

    # Either resourceID or [Offer, Publisher, SKU, Version] must be set
    When I get project machineset named "<%= machine_set.name %>" as YAML 
    And I save the output to file> machineset-clone-34313.yaml
    And I replace content in "machineset-clone-34313.yaml":
      | <%= machine_set.name %> | win-34313                |
      | /osType.*/              | osType: Windows          |
      | /replicas.*/            | replicas: 0              |
      | /offer.*/               | offer: <offer>           |
      | /publisher.*/           | publisher: <publisher>   |
      | /sku.*/                 | sku: <sku>               |
      | /version.*/             | version: <version>       |
      | /resourceID.*/          | resourceID: <resourceID> |

    When I run the :create admin command with:
      | f | machineset-clone-34313.yaml |
    Then the step should fail
    And the output should contain:
      | <output> |

    Examples:
      | offer         | publisher              | sku             | version | resourceID | output                          |
      | WindowsServer | MicrosoftWindowsServer | 2019-Datacenter | latest  | resourceID | resourceID is already specified |
      | ""            | MicrosoftWindowsServer | 2019-Datacenter | latest  | ""         | Offer must be provided          |
      | WindowsServer | ""                     | 2019-Datacenter | latest  | ""         | Publisher must be provided      |
      | WindowsServer | MicrosoftWindowsServer | ""              | latest  | ""         | SKU must be provided            |
      | WindowsServer | MicrosoftWindowsServer | 2019-Datacenter | ""      | ""         | Version must be provided        |

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
