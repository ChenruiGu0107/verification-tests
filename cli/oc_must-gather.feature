Feature: template related scenarios:

  # @author yinzhou@redhat.com
  # @case_id OCP-28091
  @admin
  Scenario: `oc adm must-gather` command could be used in disconnected env
    Given the master version >= "4.1"
    Given I switch to cluster admin pseudo user
    When I run the :import_image client command with:
      | image_name | must-gather |
      | n          | openshift   |
    Then the step should succeed
    When I run the :oadm_must_gather admin command with:
      | dest_dir | ocp28091 |
    Then the step should succeed
    And the "ocp28091" file is present
    Given the "ocp28091" directory is removed
