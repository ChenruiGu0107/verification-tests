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
      | <%= machine_set.name %> | <machineset-name>  |
      | <valid_field>           | <invalid_value>    |
      | /replicas:.*/           | replicas: 1        |

    When I run the :create admin command with:
      | f | machineset-invalid.yaml |
    Then the step should succeed
    And admin ensures "<machineset-name>" machineset is deleted after scenario

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

    Examples:
      | valid_field       | invalid_value                       | machineset-name          |
      | /machineType:.*/  | machineType: invalid                | machineset-invalid-25927 | # @case_id OCP-25927
      | /instanceType:.*/ | instanceType: invalid               | machineset-invalid-28817 | # @case_id OCP-28817
      | /vmSize:.*/       | vmSize: invalid                     | machineset-invalid-28818 | # @case_id OCP-28818
      | /flavor:.*/       | flavor: invalid                     | machineset-invalid-28916 | # @case_id OCP-28916
      | /folder:.*/       | folder: /SDDC-Datacenter/vm/invalid | machineset-invalid-28971 | # @case_id OCP-28971

  # @author zhsun@redhat.com
  # @case_id OCP-29351
  Scenario: Use oc explain to see detailed documentation of the resources
    Given evaluation of `["machine", "machineset", "machinehealthcheck", "clusterautoscaler", "machineautoscaler"]` is stored in the :resources clipboard
    And I repeat the following steps for each :resource in cb.resources:
    """
    When I run the :explain client command with:
      | resource | #{cb.resource} |
    Then the step should succeed
    And the output should contain:
      | apiVersion |
    And the output should not contain:
      | <empty> |
      | <none>  |
    """

  # @author zhsun@redhat.com
  # @case_id OCP-30257
  @admin
  Scenario: Cluster-reader should be able to view machine resources
    Given cluster role "cluster-reader" is added to the "first" user
    Given I switch to the first user
    Then I use the "openshift-machine-api" project
    When I run the :get client command with:
      | resource | machine,machineset,machinehealthcheck,machineautoscaler |
    Then the step should succeed
    And the output should not contain:
      | Error |

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
  # @case_id OCP-36153
  @admin
  @destructive
  Scenario: Creating VMs using KMS keys from GCP
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And admin ensures machine number is restored after scenario
    And I pick a random machineset to scale

    # Create a machineset
    Given I get project machineset named "<%= machine_set.name %>" as YAML
    And I save the output to file> machineset-clone-36153.yaml
    And I replace content in "machineset-clone-36153.yaml":
      | <%= machine_set.name %> | machineset-clone-36153 |
      | /replicas.*/            | replicas: 0            |

    When I run the :create admin command with:
      | f | machineset-clone-36153.yaml |
    Then the step should succeed
    And admin ensures "machineset-clone-36153" machineset is deleted after scenario

    Given as admin I successfully merge patch resource "machineset/machineset-clone-36153" with:
      | {"spec":{"replicas":1,"template":{"spec":{"providerSpec":{"value":{"disks":[{"autoDelete":true,"boot":true,"encryptionKey":{"kmsKey":{"keyRing":"openshiftqe","location":"global","name":"openshiftqe"},"kmsKeyServiceAccount":"aos-qe-serviceaccount@openshift-qe.iam.gserviceaccount.com"},"sizeGb":128,"type":"pd-ssd"}]}}}}}} |

    # Verify machine could be created successful
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set("machineset-clone-36153").desired_replicas(cached: false) == 1
    """
    Then the machineset should have expected number of running machines

  # @author zhsun@redhat.com
  # @case_id OCP-37384
  @admin
  Scenario: Machine API components should honour cluster wide proxy settings
    Given I switch to cluster admin pseudo user
    When I run the :get admin command with:
      | resource      | proxy   |
      | resource_name | cluster |
      | o             | yaml    |
    Then the step should succeed
    And evaluation of `YAML.load @result[:response]` is stored in the :proxy clipboard

    When I use the "openshift-machine-api" project
    And 1 pod becomes ready with labels:
      | api=clusterapi |
    When I run the :describe admin command with:
      | resource | pod             |
      | name     | <%= pod.name %> |
    And the output should match:
      | HTTP_PROXY.*<%= cb.proxy["spec"]["httpProxy"] %>  |
      | HTTPS_PROXY.*<%= cb.proxy["spec"]["httpProxy"] %> |
      | NO_PROXY.*<%= cb.proxy["spec"]["noProxy"] %>      |

  # @author zhsun@redhat.com
  # @case_id OCP-37689
  @admin
  Scenario Outline: Machines phase should become 'Failed' when the key permissions are invalid - GCP
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And I pick a random machineset to scale

    # Create a machineset
    Given I get project machineset named "<%= machine_set.name %>" as YAML
    And I save the output to file> machineset-clone-37689.yaml
    And I replace content in "machineset-clone-37689.yaml":
      | <%= machine_set.name %> | machineset-clone-37689 |
      | /replicas.*/            | replicas: 0            |

    When I run the :create admin command with:
      | f | machineset-clone-37689.yaml |
    Then the step should succeed
    And admin ensures "machineset-clone-37689" machineset is deleted after scenario

    Given as admin I successfully merge patch resource "machineset/machineset-clone-37689" with:
      | {"spec":{"replicas":1,"template":{"spec":{"providerSpec":{"value":{"disks":[{"autoDelete":true,"boot":true,"encryptionKey":<value>,"sizeGb":128,"type":"pd-ssd"}]}}}}}} |

    # Verified machine has 'Failed' phase
    Given I store the last provisioned machine in the :invalid_machine clipboard
    And I wait up to 60 seconds for the steps to pass:
    """
    Then the expression should be true> machine(cb.invalid_machine).phase(cached: false) == "Failed"
    """

    Examples:
      | value                                                                                                                                                                     |
      | {"kmsKey":{"keyRing":"openshiftqe-invalid","location":"global","name":"openshiftqe"},"kmsKeyServiceAccount":"aos-qe-serviceaccount@openshift-qe.iam.gserviceaccount.com"} |
      | {"kmsKey":{"keyRing":"openshiftqe","location":"global-invalid","name":"openshiftqe"},"kmsKeyServiceAccount":"aos-qe-serviceaccount@openshift-qe.iam.gserviceaccount.com"} |
      | {"kmsKey":{"keyRing":"openshiftqe","location":"global","name":"openshiftqe-invalid"},"kmsKeyServiceAccount":"aos-qe-serviceaccount@openshift-qe.iam.gserviceaccount.com"} |
      | {"kmsKey":{"keyRing":"openshiftqe","location":"global","name":"openshiftqe"},"kmsKeyServiceAccount":"aos-qe-serviceaccount@openshift-qe.iam.gserviceaccount.com-invalid"} |

  # @author zhsun@redhat.com
  # @case_id OCP-37497
  @admin
  @destructive
  Scenario:  Dedicated Spot Instances could be created
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And admin ensures machine number is restored after scenario
    And I pick a random machineset to scale

    # Create a machineset
    Given I get project machineset named "<%= machine_set.name %>" as YAML
    And I save the output to file> machineset-clone-37497.yaml
    And I replace content in "machineset-clone-37497.yaml":
      | <%= machine_set.name %> | machineset-clone-37497 |
      | /replicas.*/            | replicas: 0            |

    When I run the :create admin command with:
      | f | machineset-clone-37497.yaml |
    Then the step should succeed
    And admin ensures "machineset-clone-37497" machineset is deleted after scenario

    Given as admin I successfully merge patch resource "machineset/machineset-clone-37497" with:
      | {"spec":{"replicas":1,"template":{"spec":{"providerSpec":{"value":{"spotMarketOptions":{},"instanceType":"c4.8xlarge","placement":{"tenancy": "dedicated"}}}}}}} |

    # Verify machine could be created successful
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set("machineset-clone-37497").desired_replicas(cached: false) == 1
    """
    Then the machineset should have expected number of running machines
    
  # @author zhsun@redhat.com
  # @case_id OCP-27651
  @admin
  @destructive
  Scenario:  Machine not in a running state should get terminated when the machineset gets deleted
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And admin ensures machine number is restored after scenario
    And I pick a random machineset to scale

    # Create a machineset
    Given I get project machineset named "<%= machine_set.name %>" as YAML
    And I save the output to file> machineset-clone-27651.yaml
    And I replace content in "machineset-clone-27651.yaml":
      | <%= machine_set.name %> | machineset-clone-27651 |

    When I run the :create admin command with:
      | f | machineset-clone-27651.yaml |
    Then the step should succeed
    And admin ensures "machineset-clone-27651" machineset is deleted after scenario

    Given I store the last provisioned machine in the :machine clipboard
    When I run the :get background admin command with:
      | resource      | machine           |
      | resource_name | <%= cb.machine %> |
      | w             | true              |
    Then the step should succeed
    When I terminate last background process
    Then the expression should be true> machine(cb.machine).phase(cached: false) == "Provisioning"

    Then admin ensures "machineset-clone-27651" machineset is deleted
    And I wait up to 300 seconds for the steps to pass:
    """
    And the machine named "<%= cb.machine %>" does not exist
    """
