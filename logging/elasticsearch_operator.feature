@clusterlogging
Feature: elasticsearch operator related tests

  # @author qitang@redhat.com
  @admin
  @destructive
  Scenario Outline: Redundancy policy testing
    Given I delete the clusterlogging instance
    Given I register clean-up steps:
    """
      Given I delete the clusterlogging instance
    """
    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging/clusterlogging/<file> |
    Then the step should succeed
    Given I wait for the "elasticsearch" config_map to appear
    Then the expression should be true> elasticsearch('elasticsearch').redundancy_policy == <redundancy_policy>
    Given evaluation of `YAML.load(config_map('elasticsearch').value_of('index_settings'))` is stored in the :data clipboard
    And the expression should be true> cb.data == <index_settings>

    Examples:
      | file                    | index_settings                      | redundancy_policy    |
      | singleredundancy.yaml   | "PRIMARY_SHARDS=3 REPLICA_SHARDS=1" | "SingleRedundancy"   | # @case_id OCP-21929
      | fullredundancy.yaml     | "PRIMARY_SHARDS=3 REPLICA_SHARDS=2" | "FullRedundancy"     | # @case_id OCP-22007
      | zeroredundancy.yaml     | "PRIMARY_SHARDS=3 REPLICA_SHARDS=0" | "ZeroRedundancy"     | # @case_id OCP-22006
      | multipleredundancy.yaml | "PRIMARY_SHARDS=5 REPLICA_SHARDS=2" | "MultipleRedundancy" | # @case_id OCP-22005
