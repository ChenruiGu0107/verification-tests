Feature: admin build related features
  # @author akostadi@redhat.com
  # @case_id OCP-10618
  # @note marked destructive because it prunes builds older than 1m and this
  #   could be unexpected by other scenarios that check older builds
  @admin
  @destructive
  Scenario: Prune old builds by admin command
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | openshift/ruby~https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed

    #Generate enough builds for the oadm command to clean
    Given the "ruby-hello-world-1" build completes
    And I run the steps 7 times:
    """
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    """

    When I run the :oadm_prune_builds client command with:
      | help ||
    Then the step should succeed
    And the output should contain "completed and failed builds"
    #Wait for the builds to finish:
    Given the "ruby-hello-world-1" build finished
    And the "ruby-hello-world-2" build finished
    And the "ruby-hello-world-3" build finished
    And the "ruby-hello-world-4" build finished
    And the "ruby-hello-world-5" build finished
    And the "ruby-hello-world-6" build finished
    And the "ruby-hello-world-7" build finished
    And the "ruby-hello-world-8" build finished

    ## the real running env is really slow to finish build, enlarge the time scope for oadm_prune_builds
    When I run the :oadm_prune_builds admin command with:
      | keep_younger_than | 1s    |
      | confirm           | false |
      | keep_complete     | 2     |
      | keep_failed       | 1     |
    Then the step should succeed
    And the output should match:
      | Dry run |
      # make sure we match only builds for current project
      # some builds will succeed, some will fail so can't match exact numbers
      | <%= project.name %>\\s*ruby-hello-world- |
    And I save pruned builds in the "<%= project.name %>" project into the :pruned1 clipboard

    When I run the :oadm_prune_builds admin command with:
      | keep_younger_than | 1s    |
      | confirm           | true  |
      | keep_complete     | 2     |
      | keep_failed       | 1     |
    Then the step should succeed
    And the output should match:
      # make sure we match only builds for current project
      # some builds will succeed, some will fail so can't match exact numbers
      | <%= project.name %>\\s*ruby-hello-world- |

    When I save pruned builds in the "<%= project.name %>" project into the :pruned2 clipboard
    Then the expression should be true> cb.pruned1.to_set == cb.pruned2.to_set

    When I save project builds into the :builds clipboard
    # no pruned builds exist anymore
    Then the expression should be true> (cb.builds & cb.pruned1).empty?
    # completed builds are <= 2
    And the expression should be true> cb.builds.select{|b| b.status?(user: user, status: :complete)[:success]}.size <= 2
    # failed builds are <= 1
    And the expression should be true> cb.builds.select{|b| b.status?(user: user, status: [:failed, :error, :cancelled])[:success]}.size <= 1

    When I run the :delete client command with:
      | object_type       | buildconfig       |
      | object_name_or_id | ruby-hello-world  |
      | cascade           | false             |
    Then the step should succeed

    When I run the :oadm_prune_builds admin command with:
      | keep_younger_than | 1s    |
      | confirm           | false |
      | keep_complete     | 2     |
      | keep_failed       | 1     |
      | orphans_noopt     |       |
    Then the step should succeed
    And the output should match:
      | Dry run |
      # make sure we match only builds for current project
      # some builds will succeed, some will fail so can't match exact numbers
      | <%= project.name %>\\s*ruby-hello-world- |
    And I save pruned builds in the "<%= project.name %>" project into the :pruned1 clipboard

    When I run the :oadm_prune_builds admin command with:
      | keep_younger_than | 1s    |
      | confirm           | true  |
      | keep_complete     | 2     |
      | keep_failed       | 1     |
      | orphans_noopt     |       |
    Then the step should succeed
    And the output should match:
      # make sure we match only builds for current project
      # some builds will succeed, some will fail so can't match exact numbers
      | <%= project.name %>\\s*ruby-hello-world- |

    When I save pruned builds in the "<%= project.name %>" project into the :pruned2 clipboard
    Then the expression should be true> cb.pruned1.to_set == cb.pruned2.to_set
    And the project should contain no builds

  # @author cryan@redhat.com
  # @case_id OCP-11702
  Scenario: Show friendly messages when invalid options and values for chain-build sub-command
    When I run the :oadm_build_chain client command with:
      | invalid_option | -invalid-opt|
    Then the step should fail
    And the output should contain "unknown shorthand flag"
    When I run the :oadm_build_chain client command with:
      | invalid_option | ---all |
    Then the step should fail
    And the output should contain "bad flag syntax"
    When I run the :oadm_build_chain client command with:
      | invalid_option | -all |
    Then the step should fail
    And the output should contain "unknown shorthand flag"
    When I run the :oadm_build_chain client command with:
      | imagestreamtag | not-existing/image-repo |
    Then the step should fail
    And the output should contain:
      | doesn't have a resource type "not-existing" |
    When I run the :oadm_build_chain client command with:
      | imagestreamtag | ruby:latest |
      | all | true |
    Then the step should fail
    And the output should contain "Error"

  # @author xxia@redhat.com
  # @case_id OCP-11493
  @admin
  Scenario: Negative/invalid options test for oadm prune builds
    When I run the :oadm_prune_builds admin command with:
      | confirm           | false  |
      | keep_complete     | -2.1   |
      | keep_failed       | 1      |
      | keep_younger_than | 1m     |
    Then the step should fail
    And the output should match:
      | [Ii]nvalid argument.*-2.1  |

    When I run the :oadm_prune_builds admin command with:
      | confirm           | false  |
      | keep_complete     | letter |
      | keep_failed       | 1      |
      | keep_younger_than | 1m     |
    Then the step should fail
    And the output should match:
      | [Ii]nvalid argument.*letter|

    When I run the :oadm_prune_builds admin command with:
      | confirm           | false  |
      | keep_complete     | 2      |
      | keep_failed       | 1      |
      | keep_younger_than | 1min   |
    Then the step should fail
    And the output should match:
      | [Ii]nvalid argument.*1min  |
