Feature: Add pvc to pod from web related
  # @author yanpzhan@redhat.com
  # @case_id OCP-10752
  @admin
  @destructive
  Scenario: Attach pvc to pod with multiple containers from web console
    When I create a new project via web
    Then the step should succeed
    And I have a NFS service in the project

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template.json" where:
      | ["spec"]["nfs"]["server"]  | <%= service("nfs-service").ip %> |
      | ["metadata"]["name"]       | nfs-1-<%= project.name %>         |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]   | nfsc-1-<%= project.name %> |
      | ["spec"]["volumeName"] | nfs-1-<%= project.name %>  |
    Then the step should succeed
    And the "nfsc-1-<%= project.name %>" PVC becomes bound to the "nfs-1-<%= project.name %>" PV

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template.json" where:
      | ["spec"]["nfs"]["server"]  | <%= service("nfs-service").ip %> |
      | ["metadata"]["name"]       | nfs-2-<%= project.name %>         |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]   | nfsc-2-<%= project.name %> |
      | ["spec"]["volumeName"] | nfs-2-<%= project.name %>  |
    Then the step should succeed
    And the "nfsc-2-<%= project.name %>" PVC becomes bound to the "nfs-2-<%= project.name %>" PV

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/dc-with-two-containers.yaml |
    Then the step should succeed

    #Add pvc to one of the containers
    When I perform the :add_pvc_to_one_container web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | dctest              |
      | mount_path   | /mnt                |
      | volume_name  | v1                |
    Then the step should succeed
    And I wait until the status of deployment "dctest" becomes :complete

    Given 1 pods become ready with labels:
      | run=dctest |

    When I run the :exec client command with:
      | pod | <%= pod.name %>          |
      | c   | dctest-1                 |
      | exec_command | grep            |
      | exec_command_arg | mnt         |
      | exec_command_arg | /proc/mounts|
    Then the step should succeed

    #Add pvc to all containers by default
    When I perform the :add_pvc_to_all_default_containers web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | dctest              |
      | mount_path   | /tmp                |
      | volume_name  | v2                |
    Then the step should succeed
    And I wait until the status of deployment "dctest" becomes :complete

    Given 1 pods become ready with labels:
      | run=dctest |

    When I run the :exec client command with:
      | pod | <%= pod.name %>    |
      | c   | dctest-1           |
      | exec_command | touch     |
      | exec_command_arg |/tmp/f1|
    Then the step should succeed

    When I run the :exec client command with:
      | pod | <%= pod.name %>    |
      | c   | dctest-2           |
      | exec_command | ls        |
      | exec_command_arg |/tmp   |
    Then the step should succeed
    And the output should contain:
      | f1 |

  # @author yanpzhan@redhat.com
  # @case_id OCP-11547
  @admin
  @destructive
  Scenario: Display and attach PVC to pod from web console
    Given I have a project
    And I have a NFS service in the project

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template.json" where:
      | ["spec"]["nfs"]["server"]  | <%= service("nfs-service").ip %> |
      | ["metadata"]["name"]       | nfs-<%= project.name %>         |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]   | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"] | nfs-<%= project.name %>  |
    Then the step should succeed

    And the "nfsc-<%= project.name %>" PVC becomes bound to the "nfs-<%= project.name %>" PV

    When I run the :run client command with:
      | name         | mytest                    |
      | image        |<%= project_docker_repo %>aosqe/hello-openshift |
      | -l           | label=test |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | label=test |

    #Add pvc from rc page
    When I perform the :add_pvc_on_rc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | mytest              |
      | dc_number    | 1                   |
      | mount_path   | /test               |
      | volume_name  | v1                  |
    Then the step should succeed
    When  I perform the :check_mount_info web console action with:
      | mount_path   | /test               |
      | volume_name  | v1                  |
    Then the step should succeed

    When I run the :delete client command with:
      | object_type   | pod                   |
      | l             | label=test            |
    Then the step should succeed
    And I wait for the pod to die regardless of current status
    Given 1 pods become ready with labels:
      | label=test |

    When I run the :exec client command with:
      | pod | <%= pod.name %>          |
      | exec_command | grep            |
      | exec_command_arg | test        |
      | exec_command_arg | /proc/mounts|
    Then the step should succeed

    When I run the :volume client command with:
      | resource      | rc/mytest-1             |
      | action        | --remove                |
      | name          | v1                      |
    Then the step should succeed

    #Add pvc from dc page
    When I perform the :add_pvc_to_all_default_containers web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | mytest              |
      | mount_path   | /mnt                |
      | volume_name  | v2                  |
    Then the step should succeed
    When  I perform the :check_mount_info web console action with:
      | mount_path   | /mnt               |
      | volume_name  | v2                 |
    Then the step should succeed

    And I wait until the status of deployment "mytest" becomes :complete

    Given 1 pods become ready with labels:
      | label=test |

    When I run the :exec client command with:
      | pod | <%= pod.name %>          |
      | exec_command | grep            |
      | exec_command_arg | mnt         |
      | exec_command_arg | /proc/mounts|
    Then the step should succeed

    When I run the :volume client command with:
      | resource      | dc/mytest               |
      | action        | --remove                |
      | name          | v2                      |
    Then the step should succeed

    #Add pvc from pod page
    When I perform the :add_pvc_to_pod web console action with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= pod.name %>     |
      | mount_path   | /data               |
      | volume_name  | v3                  |
    Then the step should succeed

    And I wait until the status of deployment "mytest" becomes :complete

    Given 1 pods become ready with labels:
      | label=test |

    When I perform the :goto_one_pod_page web console action with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= pod.name %>     |
    Then the step should succeed
    When  I perform the :check_mount_info web console action with:
      | mount_path   | /data              |
      | volume_name  | v3                 |
    Then the step should succeed

    When I run the :exec client command with:
      | pod | <%= pod.name %>           |
      | exec_command | grep             |
      | exec_command_arg | data         |
      | exec_command_arg | /proc/mounts |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-11628
  @admin
  @destructive
  Scenario: Display and attach PVC to pod from web console - 3.3
    Given I have a project
    And I have a NFS service in the project

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template.json" where:
      | ["spec"]["nfs"]["server"]  | <%= service("nfs-service").ip %> |
      | ["metadata"]["name"]       | nfs-<%= project.name %>         |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]   | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"] | nfs-<%= project.name %>  |
    Then the step should succeed
    And the "nfsc-<%= project.name %>" PVC becomes bound to the "nfs-<%= project.name %>" PV

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template.json" where:
      | ["spec"]["nfs"]["server"]  | <%= service("nfs-service").ip %> |
      | ["metadata"]["name"]       | nfs-2-<%= project.name %>         |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]   | nfsc-2-<%= project.name %> |
      | ["spec"]["volumeName"] | nfs-2-<%= project.name %>  |
    Then the step should succeed
    And the "nfsc-2-<%= project.name %>" PVC becomes bound to the "nfs-2-<%= project.name %>" PV

    When I run the :run client command with:
      | name         | mytest                    |
      | image        |<%= project_docker_repo %>aosqe/hello-openshift |
      | -l           | label=test |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | label=test |

    #Add pvc from rc page
    When I perform the :add_pvc_on_rc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | mytest              |
      | dc_number    | 1                   |
      | mount_path   | /test               |
      | volume_name  | v1                  |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | dc     |
      | resource_name | mytest |
      | o             | yaml   |
    Then the step should succeed

    When I perform the :goto_one_deployment_page web console action with:
      | project_name | <%= project.name %>  |
      | dc_name      | mytest               |
      | dc_number    | <%= @result[:parsed]['status']['latestVersion'] %> |
    Then the step should succeed
    When  I perform the :check_mount_info web console action with:
      | mount_path   | /test               |
      | volume_name  | v1                  |
    Then the step should succeed

    And I wait until the status of deployment "mytest" becomes :complete

    When I run the :delete client command with:
      | object_type   | pod                   |
      | l             | label=test            |
    Then the step should succeed
    And I wait for the pod to die regardless of current status
    Given 1 pods become ready with labels:
      | label=test |

    When I execute on the pod:
      | grep | test | /proc/mounts |
    Then the step should succeed

    #Add pvc from dc page
    When I perform the :add_pvc_to_all_default_containers web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | mytest              |
      | mount_path   | /mnt                |
      | volume_name  | v2                  |
    Then the step should succeed

    When I run the :get client command with:
      | resource      | dc     |
      | resource_name | mytest |
      | o             | yaml   |
    Then the step should succeed

    When I perform the :goto_one_deployment_page web console action with:
      | project_name | <%= project.name %>  |
      | dc_name      | mytest               |
      | dc_number    | <%= @result[:parsed]['status']['latestVersion'] %> |
    Then the step should succeed

    When  I perform the :check_mount_info web console action with:
      | mount_path   | /mnt               |
      | volume_name  | v2                 |
    Then the step should succeed

    And I wait until the status of deployment "mytest" becomes :complete

    Given 1 pods become ready with labels:
      | label=test |

    When I execute on the pod:
      | grep | mnt | /proc/mounts |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-10126
  Scenario: Create persist volume claim from web console
    Given I have a project

    # Create ROX type pvc
    When I perform the :create_pvc_from_storage_page web console action with:
      | project_name    | <%= project.name %> |
      | pvc_name        | wehe-100            |
      | pvc_access_mode | ReadOnlyMany        |
      | storage_size    | 0.01                |
      | storage_unit    | TiB                 |
    Then the step should succeed

    When I perform the :check_pvc_info web console action with:
      | project_name    | <%= project.name %>  |
      | pvc_name        | wehe-100             |
      | pvc_access_mode | ROX (Read-Only-Many) |
      | storage_size    | 10995116277760 mB    |
    Then the step should succeed

    # Create pvc with existing pvc name
    When I perform the :create_pvc_from_storage_page web console action with:
      | project_name    | <%= project.name %> |
      | pvc_name        | wehe-100            |
      | pvc_access_mode | ReadOnlyMany        |
      | storage_size    | 0.01                |
      | storage_unit    | TiB                 |
    Then the step should succeed
    When I perform the :check_prompt_info_for_pvc web console action with:
      | prompt_info | "wehe-100" already exists |
    Then the step should succeed

    When I run the :cancel_pvc_creation web console action
    Then the step should succeed

    # Create RWX type pvc
    When I perform the :create_pvc_from_storage_page web console action with:
      | project_name    | <%= project.name %> |
      | pvc_name        | 0123456789          |
      | pvc_access_mode | ReadWriteMany       |
      | storage_size    | 1024                |
      | storage_unit    | GiB                 |
    Then the step should succeed

    When I perform the :check_pvc_info web console action with:
      | project_name    | <%= project.name %>   |
      | pvc_name        | 0123456789            |
      | pvc_access_mode | RWX (Read-Write-Many) |
      | storage_size    | 1 TiB                 |
    Then the step should succeed

    # Delete pvc from web console
    When I perform the :delete_resources_pvc web console action with:
      | project_name    | <%= project.name %> |
      | pvc_name        | 0123456789          |
    Then the step should succeed
    When I perform the :check_prompt_info_for_pvc web console action with:
      | prompt_info | marked for deletion |
    Then the step should succeed

    # Create RWO type pvc
    When I perform the :create_pvc_from_storage_page web console action with:
      | project_name    | <%= project.name %> |
      | pvc_name        | wehepvc             |
      | pvc_access_mode | ReadWriteOnce       |
      | storage_size    | 1025                |
      | storage_unit    | MiB                 |
    Then the step should succeed

    When I perform the :check_pvc_info web console action with:
      | project_name    | <%= project.name %>   |
      | pvc_name        | wehepvc               |
      | pvc_access_mode | RWO (Read-Write-Once) |
      | storage_size    | 1025 MiB              |
    Then the step should succeed

    # Check invalid pvc name with special symbol
    When I perform the :create_pvc_with_invalid_name_and_check web console action with:
      | project_name    | <%= project.name %> |
      | pvc_name        | $%$#                |
      | storage_size    | 100                 |
    Then the step should succeed

    # Check invalid pvc name with '-' at the beginning
    When I perform the :create_pvc_with_invalid_name_and_check web console action with:
      | project_name    | <%= project.name %> |
      | pvc_name        | -test               |
      | storage_size    | 100                 |
    Then the step should succeed

    # Check invalid pvc name with '-' at the end
    When I perform the :create_pvc_with_invalid_name_and_check web console action with:
      | project_name    | <%= project.name %> |
      | pvc_name        | test-               |
      | storage_size    | 100                 |
    Then the step should succeed

    # Check invalid pvc name with more than 253 characters
    When I perform the :create_pvc_with_invalid_value_and_check web console action with:
      | project_name    | <%= project.name %>        |
      | pvc_name        | <%= rand_str(254, :dns) %> |
      | storage_size    | 100                        |
    Then the step should succeed

    # Check invalid pvc name one character(min length)
    When I perform the :create_pvc_with_min_length_and_check web console action with:
      | project_name    | <%= project.name %>      |
      | pvc_name        | <%= rand_str(1, :dns) %> |
      | storage_size    | 100                      |
    Then the step should succeed

    # Check invalid pvc size
    When I perform the :create_pvc_with_invalid_value_and_check web console action with:
      | project_name    | <%= project.name %> |
      | pvc_name        | pvctest             |
      | storage_size    | $$$####%            |
    Then the step should succeed

  # @author wehe@redhat.com
  # @case_id 538184 544977 544978
  @admin
  Scenario Outline: Create persist volume claim with storage class on web console
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass.yaml" where:
      | ["metadata"]["name"]                                                            | <%= project.name %>         |
      | ["provisioner"]                                                                 | kubernetes.io/<provisioner> |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | "false"                     |
    Then the step should succeed

    # Create ROX type pvc
    When I perform the :create_pvc_with_storage_class web console action with:
      | project_name     | <%= project.name %> |
      | pvc_name         | pvc-1               |
      | pvc_access_mode  | ReadOnlyMany        |
      | storage_size     | 0.001               |
      | storage_unit     | TiB                 | 
    Then the step should succeed

    When I perform the :check_pvcs_detail_on_storage_page web console action with:
      | project_name    | <%= project.name %>  |
      | pvc_name        | pvc-1                |
      | pvc_status      | Bound                |
      | pvc_access_mode | ROX (Read-Only-Many) |
      | storage_size    | 2 GiB                |
    Then the step should succeed
    Given admin ensures "<%= pvc("pvc-1").volume_name(user: user) %>" pv is deleted after scenario

    When I perform the :check_pvc_info_with_status web console action with:
      | project_name    | <%= project.name %>  |
      | pvc_name        | pvc-1                |
      | pvc_status      | Bound                |
      | pvc_access_mode | ROX (Read-Only-Many) |
      | storage_size    | 1099511627776 mB     |
    Then the step should succeed

    # Create RWX type pvc
    Given I wait up to 180 seconds for the steps to pass:
    """
    When I perform the :create_pvc_with_storage_class web console action with:
      | project_name    | <%= project.name %> |
      | pvc_name        | 0123456789          |
      | pvc_access_mode | ReadWriteMany       |
      | storage_size    | 2048                |
      | storage_unit    | MiB                 |
    Then the step should succeed

    When I perform the :check_pvcs_detail_on_storage_page web console action with:
      | project_name    | <%= project.name %>   |
      | pvc_name        | 0123456789            |
      | pvc_status      | Bound                 |
      | pvc_access_mode | RWX (Read-Write-Many) |
      | storage_size    | 2 GiB                 |
    Then the step should succeed
    """
    Given admin ensures "<%= pvc("0123456789").volume_name(user: user) %>" pv is deleted after scenario

    When I perform the :check_pvc_info_with_status web console action with:
      | project_name    | <%= project.name %>   |
      | pvc_name        | 0123456789            |
      | pvc_status      | Bound                 |
      | pvc_access_mode | RWX (Read-Write-Many) |
      | storage_size    | 2 GiB                 |
    Then the step should succeed
    
    # Create RWO type pvc
    Given I wait up to 180 seconds for the steps to pass:
    """
    When I perform the :create_pvc_with_storage_class web console action with:
      | project_name    | <%= project.name %> |
      | pvc_name        | wehepvcrwo          |
      | pvc_access_mode | ReadWriteOnce       |
      | storage_size    | 1025                |
      | storage_unit    | MiB                 |
    Then the step should succeed

    When I perform the :check_pvcs_detail_on_storage_page web console action with:
      | project_name    | <%= project.name %>   |
      | pvc_name        | wehepvcrwo            |
      | pvc_status      | Bound                 |
      | pvc_access_mode | RWO (Read-Write-Once) |
      | storage_size    | 2 GiB                 |
    Then the step should succeed
    """
    Given admin ensures "<%= pvc("wehepvcrwo").volume_name(user: user) %>" pv is deleted after scenario

    When I perform the :check_pvc_info_with_status web console action with:
      | project_name    | <%= project.name %>   |
      | pvc_name        | wehepvcrwo            |
      | pvc_status      | Bound                 |
      | pvc_access_mode | RWO (Read-Write-Once) |
      | storage_size    | 1025 MiB              |
    Then the step should succeed
    
    # Create No Storage Class pvc
    Given I wait up to 180 seconds for the steps to pass:
    """
    When I perform the :create_pvc_no_storage_class web console action with:
      | project_name    | <%= project.name %> |
      | pvc_name        | nsc                 |
      | pvc_access_mode | ReadWriteOnce       |
      | storage_size    | 1                   |
      | storage_unit    | GiB                 |
    Then the step should succeed

    When I perform the :check_pvcs_detail_on_storage_page web console action with:
      | project_name    | <%= project.name %>   |
      | pvc_name        | nsc                   |
      | pvc_status      | Pending               |
      | pvc_access_mode | RWO (Read-Write-Once) |
      | storage_size    | -                     |
    Then the step should succeed
    """

    When I perform the :check_pvc_info web console action with:
      | project_name    | <%= project.name %>    |
      | pvc_name        | nsc                    |
      | pvc_access_mode | RWO (Read-Write-Once)  |
      | storage_size    | 1 GiB                  |
    Then the step should succeed    

    # Delete all pvc from web console
    When I perform the :delete_resources_pvc web console action with:
      | project_name    | <%= project.name %> |
      | pvc_name        | pvc-1               |
    Then the step should succeed
    When I perform the :check_prompt_info_for_pvc web console action with:
      | prompt_info | marked for deletion |
    Then the step should succeed

    When I perform the :delete_resources_pvc web console action with:
      | project_name    | <%= project.name %> |
      | pvc_name        | 0123456789          |
    Then the step should succeed
    When I perform the :check_prompt_info_for_pvc web console action with:
      | prompt_info | marked for deletion |
    Then the step should succeed

    When I perform the :delete_resources_pvc web console action with:
      | project_name    | <%= project.name %> |
      | pvc_name        | wehepvcrwo          |
    Then the step should succeed
    When I perform the :check_prompt_info_for_pvc web console action with:
      | prompt_info | marked for deletion |
    Then the step should succeed

    Examples:
      | provisioner | 
      | aws-ebs     |
      | gce-pd      |
      | cinder      |
