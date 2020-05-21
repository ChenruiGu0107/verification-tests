Feature: oc credential related scenarios
  # @author yinzhou@redhat.com
  # @case_id OCP-29365
  @admin
  @destructive
  Scenario: Multiple credential sources being provided to oc client during prune
    Given the master version >= "4.1"
    And evaluation of `image_stream("cli", project("openshift")).tags.first.from.name` is stored in the :oc_cli clipboard
    Given I have a project
    Given cluster role "system:image-pruner" is added to the "default" service account
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/cli/OCP-29365/cli-29365.yaml" replacing paths:
      | ["spec"]["containers"][0]["image"] | <%= cb.oc_cli %> |
    Then the step should succeed
    Given the pod named "cli" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | cli |
    Then the output should contain:
      | Dry run enabled - no modifications will be made |
