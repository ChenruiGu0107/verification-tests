Feature: Add pvc to pod from web related
  # @author wehe@redhat.com
  @admin
  @destructive
  Scenario Outline: Create persist volume claim with storage class on web console
    Given I have a project
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass.yaml" where:
      | ["metadata"]["name"] | <%= project.name %>         |
      | ["provisioner"]      | kubernetes.io/<provisioner> |
    Then the step should succeed

    Given I wait up to 180 seconds for the steps to pass:
    """
    When I perform the :create_pvc_with_storage_class web console action with:
      | project_name     | <%= project.name %> |
      | pvc_name         | pvc-1               |
      | pvc_access_mode  | ReadWriteOnce       |
      | storage_size     | 0.001               |
      | storage_unit     | TiB                 |
    Then the step should succeed

    When I perform the :check_pvcs_detail_on_storage_page web console action with:
      | project_name    | <%= project.name %>   |
      | pvc_name        | pvc-1                 |
      | pvc_status      | Bound                 |
      | pvc_access_mode | RWO (Read-Write-Once) |
      | storage_size    | 2 GiB                 |
    Then the step should succeed
    """
    Given admin ensures "<%= pvc("pvc-1").volume_name(user: user) %>" pv is deleted after scenario

    When I perform the :check_pvc_info_with_status web console action with:
      | project_name    | <%= project.name %>   |
      | pvc_name        | pvc-1                 |
      | pvc_status      | Bound                 |
      | pvc_access_mode | RWO (Read-Write-Once) |
      | storage_size    | 1099511627776 mB      |
    Then the step should succeed

    Given I wait up to 180 seconds for the steps to pass:
    """
    When I perform the :create_pvc_with_storage_class web console action with:
      | project_name    | <%= project.name %> |
      | pvc_name        | 0123456789          |
      | pvc_access_mode | ReadWriteOnce       |
      | storage_size    | 2048                |
      | storage_unit    | MiB                 |
    Then the step should succeed

    When I perform the :check_pvcs_detail_on_storage_page web console action with:
      | project_name    | <%= project.name %>   |
      | pvc_name        | 0123456789            |
      | pvc_status      | Bound                 |
      | pvc_access_mode | RWO (Read-Write-Once) |
      | storage_size    | 2 GiB                 |
    Then the step should succeed
    """
    Given admin ensures "<%= pvc("0123456789").volume_name(user: user) %>" pv is deleted after scenario

    When I perform the :check_pvc_info_with_status web console action with:
      | project_name    | <%= project.name %>   |
      | pvc_name        | 0123456789            |
      | pvc_status      | Bound                 |
      | pvc_access_mode | RWO (Read-Write-Once) |
      | storage_size    | 2 GiB                 |
    Then the step should succeed

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
      | gce-pd      | # @case_id OCP-10557
      | azure-disk  | # @case_id OCP-10458
