Feature: edit.feature

  # @author cryan@redhat.com
  # @case_id 497628
  Scenario: Edit inexistent resource via oc edit
    When I run the :edit client command with:
      | filename | test |
    Then the output should contain "the path "test" does not exist"
