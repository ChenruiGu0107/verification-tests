Feature: deployment related steps

  # @author geliu@redhat.com
  # @case_id OCP-11599
  Scenario: Cleanup policy - Cleanup all previous RSs older than the latest N replica sets in pause
    Given I have a project
    Given I obtain test data file "deployment/hello-deployment-1.yaml"
    When I run the :create client command with:
      | f | hello-deployment-1.yaml |
    Then the step should succeed
    Given 10 pods become ready with labels:
      | app=hello-openshift |
    When I run the :patch client command with:
      | resource      | deployment                                                                                                           |
      | resource_name | hello-openshift                                                                                                      |
      | p             | {"spec":{"template":{"spec":{"containers":[{"image":"quay.io/openshifttest/hello-openshift@sha256:424e57db1f2e8e8ac9087d2f5e8faea6d73811f0b6f96301bc94293680897073","name":"hello-openshift"}]}}}} |
    Then the step should succeed
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output should match:
      | .*[Ii]mage.*quay.io/openshifttest/hello-openshift.* |
    Given 10 pods become ready with labels:
      | app=hello-openshift |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | deployment                                                                                                        |
      | resource_name | hello-openshift                                                                                                   |
      | p             | {"spec":{"template":{"spec":{"containers":[{"image":"quay.io/openshifttest/deployment-example@sha256:97adb15f1238c4c9216c1e6bf3986e2468d0709fc5c3625e96d463c81240f652","name":"hello-openshift"}]}}}} |
    Then the step should succeed
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output should match:
      | .*[Ii]mage.*openshift/deployment-example.* |
    Given 10 pods become ready with labels:
      | app=hello-openshift |
    Then the step should succeed
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | revision      | 3               |
    Then the step should succeed
    And the output should match:
      | .*[iI]mage.*openshift/deployment-example.* |
    When I run the :rollout_pause client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed
    Given 10 pods become ready with labels:
      | app=hello-openshift |
    Then the step should succeed
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | .*[Pp]aused.*:.*true |
    When I run the :patch client command with:
      | resource      | deployment                          |
      | resource_name | hello-openshift                     |
      | p             | {"spec":{"revisionHistoryLimit":1}} |
    Then the step should succeed
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output should match:
      | .*revisionHistoryLimit.*:.*1.*|
    Given 10 pods become ready with labels:
      | app=hello-openshift |
    Then the step should succeed
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | revision      | 2               |
    Then the step should succeed
    And the output should match:
      | .*[iI]mage.*quay.io/openshifttest/hello-openshift.* |
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | revision      | 3               |
    Then the step should succeed
    And the output should match:
      | .*[iI]mage.*openshift/deployment-example.* |
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | revision      | 1               |
    Then the step should fail
    And the output should match:
      | .*error.*unable to find the specified revision.* |
    When I run the :rollout_resume client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | revision      | 1               |
    Then the step should fail
    And the output should match:
      | .*error.*unable to find the specified revision.* |
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | revision      | 2               |
    Then the step should succeed
    And the output should match:
      | .*[iI]mage.*quay.io/openshifttest/hello-openshift.* |
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | revision      | 3               |
    Then the step should succeed
    And the output should match:
      | .*[iI]mage.*openshift/deployment-example.* |

  # @author geliu@redhat.com
  # @case_id OCP-12073
  Scenario: Proportionally scale - Rollout deployment succeed in unpause and pause
    Given I have a project
    Given I obtain test data file "deployment/hello-deployment-1.yaml"
    When I run the :create client command with:
      | f | hello-deployment-1.yaml |
    Then the step should succeed
    Given 10 pods become ready with labels:
      | app=hello-openshift |
    And current replica set name of "hello-openshift" deployment stored into :rs1 clipboard
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 10 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 10 |
    When I run the :patch client command with:
      | resource      | deployment                                                                                              |
      | resource_name | hello-openshift                                                                                         |
      | p             | {"spec":{"template":{"spec":{"containers":[{"image":"openshift/nonexist","name":"hello-openshift"}]}}}} |
    Then the step should succeed
    Given replica set "<%= cb.rs1 %>" becomes non-current for the "hello-openshift" deployment
    And current replica set name of "hello-openshift" deployment stored into :rs2 clipboard
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 13 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 8 |
    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 5 |
    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | 20              |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | deployment                                                                                               |
      | resource_name | hello-openshift                                                                                          |
      | p             | {"spec":{"template":{"spec":{"containers":[{"image":"openshift/nonexist1","name":"hello-openshift"}]}}}} |
    Then the step should succeed
    Given replica set "<%= cb.rs2 %>" becomes non-current for the "hello-openshift" deployment
    And current replica set name of "hello-openshift" deployment stored into :rs3 clipboard
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 23 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 9 |
    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 9 |
    Given number of replicas of "<%= cb.rs3 %>" replica set becomes:
      | current | 5 |
    When I run the :rollout_pause client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | .*[Pp]aused.*:.*true |
    When I run the :patch client command with:
      | resource      | deployment                                                                                               |
      | resource_name | hello-openshift                                                                                          |
      | p             | {"spec":{"template":{"spec":{"containers":[{"image":"openshift/nonexist2","name":"hello-openshift"}]}}}} |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | 50              |
    Then the step should succeed
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 53 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 21 |
    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 21 |
    Given number of replicas of "<%= cb.rs3 %>" replica set becomes:
      | current | 11 |
    When I run the :rollout_resume client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed
    Given replica set "<%= cb.rs3 %>" becomes non-current for the "hello-openshift" deployment
    And current replica set name of "hello-openshift" deployment stored into :rs4 clipboard
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 53 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 16 |
    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 21 |
    Given number of replicas of "<%= cb.rs3 %>" replica set becomes:
      | current | 11 |
    Given number of replicas of "<%= cb.rs4 %>" replica set becomes:
      | current | 5 |
    When I run the :patch client command with:
      | resource      | deployment                                                                                                           |
      | resource_name | hello-openshift                                                                                                      |
      | p             | {"spec":{"template":{"spec":{"containers":[{"image":"quay.io/openshifttest/hello-openshift@sha256:424e57db1f2e8e8ac9087d2f5e8faea6d73811f0b6f96301bc94293680897073","name":"hello-openshift"}]}}}} |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | 8               |
    Then the step should succeed
    Given replica set "<%= cb.rs4 %>" becomes non-current for the "hello-openshift" deployment
    And current replica set name of "hello-openshift" deployment stored into :rs5 clipboard
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 8 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 0 |
    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 0 |
    Given number of replicas of "<%= cb.rs3 %>" replica set becomes:
      | current | 0 |
    Given number of replicas of "<%= cb.rs4 %>" replica set becomes:
      | current | 0 |
    Given number of replicas of "<%= cb.rs5 %>" replica set becomes:
      | current | 8 |
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | revision      | 4               |
    Then the step should succeed
    And the output should match:
      | .*nonexist2.* |

  # @author geliu@redhat.com
  # @case_id OCP-12161
  Scenario: Proportionally scale - Scale down deployment succeed in unpause and pause
    Given I have a project

    Given I obtain test data file "deployment/hello-deployment-2.yaml"
    When I run the :create client command with:
      | f | hello-deployment-2.yaml |
    Then the step should succeed

    Given 60 pods become ready with labels:
      | app=hello-openshift |

    And current replica set name of "hello-openshift" deployment stored into :rs1 clipboard

    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 60 |

    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 60 |

    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | 50              |
    Then the step should succeed

    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 50 |

    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 50 |

    When I run the :patch client command with:
      | resource      | deployment                                                                                                           |
      | resource_name | hello-openshift                                                                                                      |
      | p             | {"spec":{"template":{"spec":{"containers":[{"image":"quay.io/openshifttest/hello-openshift@sha256:424e57db1f2e8e8ac9087d2f5e8faea6d73811f0b6f96301bc94293680897073","name":"hello-openshift"}]}}}} |
    Then the step should succeed

    Given replica set "<%= cb.rs1 %>" becomes non-current for the "hello-openshift" deployment

    And current replica set name of "hello-openshift" deployment stored into :rs2 clipboard

    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 50 |

    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 0 |

    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 50 |

    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | 40              |
    Then the step should succeed

    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 40 |

    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 0 |

    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 40 |

    When I run the :patch client command with:
      | resource      | deployment                                                                                              |
      | resource_name | hello-openshift                                                                                         |
      | p             | {"spec":{"template":{"spec":{"containers":[{"image":"openshift/nonexist","name":"hello-openshift"}]}}}} |
    Then the step should succeed

    Given replica set "<%= cb.rs2 %>" becomes non-current for the "hello-openshift" deployment

    And current replica set name of "hello-openshift" deployment stored into :rs3 clipboard

    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output should match:
      | .*image.*openshift/nonexist.* |

    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 43 |

    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 0 |

    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 38 |

    Given number of replicas of "<%= cb.rs3 %>" replica set becomes:
      | current | 5 |

    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | 30              |
    Then the step should succeed

    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 33 |

    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 0 |

    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 28 |

    Given number of replicas of "<%= cb.rs3 %>" replica set becomes:
      | current | 5 |

    When I run the :rollout_pause client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed

    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | 10              |
    Then the step should succeed

    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 13 |

    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 0 |

    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 11 |

    Given number of replicas of "<%= cb.rs3 %>" replica set becomes:
      | current | 2 |

    When I run the :rollout_resume client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed

    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 13 |

    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 0 |

    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 8 |

    Given number of replicas of "<%= cb.rs3 %>" replica set becomes:
      | current | 5 |

  # @author geliu@redhat.com
  # @case_id OCP-11802
  Scenario: Proportionally scale - Mixture of surging, scaling and rollout
    Given I have a project
    Given I obtain test data file "deployment/hello-deployment-1.yaml"
    When I run the :create client command with:
      | f | hello-deployment-1.yaml |
    Then the step should succeed
    Given 10 pods become ready with labels:
      | app=hello-openshift |
    And current replica set name of "hello-openshift" deployment stored into :rs1 clipboard
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 10 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 10 |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | pods |
    Then the output should not match:
      | .*hello-openshift.*ContainerCreating.* |
    """
    When I run the :patch client command with:
      | resource      | deployment                                                                                              |
      | resource_name | hello-openshift                                                                                         |
      | p             | {"spec":{"template":{"spec":{"containers":[{"image":"openshift/nonexist","name":"hello-openshift"}]}}}} |
    Then the step should succeed
    And I wait up to 360 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | pods |
    Then the output should not match:
      | .*hello-openshift.*ContainerCreating.* |
    """
    Given replica set "<%= cb.rs1 %>" becomes non-current for the "hello-openshift" deployment
    And current replica set name of "hello-openshift" deployment stored into :rs2 clipboard
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 13 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 8 |
    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 5 |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output should match:
      | .*image.*openshift/nonexist.* |
    When I run the :rollout_pause client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output should match:
      | .*[Pp]aused.*:.*true |
    When I run the :patch client command with:
      | resource      | deployment                                                                                                                                                         |
      | resource_name | hello-openshift                                                                                                                                                    |
      | p             | {"spec":{"replicas":50,"strategy":{"rollingUpdate":{"maxSurge":6}},"template":{"spec":{"containers":[{"image":"openshift/nonexist1","name":"hello-openshift"}]}}}} |
    Then the step should succeed
    And I wait up to 360 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | pods |
    Then the output should not match:
      | .*hello-openshift.*ContainerCreating.* |
    """
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 56 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 34 |
    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 22 |
    When I run the :rollout_resume client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed
    And I wait up to 240 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | pods |
    Then the output should not match:
      | .*hello-openshift.*ContainerCreating.* |
    """
    And current replica set name of "hello-openshift" deployment stored into :rs3 clipboard
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 56 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 34 |
    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 14 |
    Given number of replicas of "<%= cb.rs3 %>" replica set becomes:
      | current | 8 |
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | revision      | 1               |
    Then the step should succeed
    And the output should match:
      | .*[iI]mage.*openshift/hello-openshift.* |
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | revision      | 2               |
    Then the step should succeed
    And the output should match:
      | .*[iI]mage.*openshift/nonexist.* |
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | revision      | 3               |
    Then the step should succeed
    And the output should match:
      | .*[iI]mage.*openshift/nonexist1.* |

  # @author geliu@redhat.com
  # @case_id OCP-11966
  Scenario: Proportionally scale - Rolling back succeed after scale up deployment
    Given I have a project
    Given I obtain test data file "deployment/hello-deployment-1.yaml"
    When I run the :create client command with:
      | f | hello-deployment-1.yaml |
    Then the step should succeed
    Given 10 pods become ready with labels:
      | app=hello-openshift |
    And current replica set name of "hello-openshift" deployment stored into :rs1 clipboard
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 10 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 10 |
    When I run the :patch client command with:
      | resource      | deployment                                                                                              |
      | resource_name | hello-openshift                                                                                         |
      | p             | {"spec":{"template":{"spec":{"containers":[{"image":"openshift/nonexist","name":"hello-openshift"}]}}}} |
    Then the step should succeed
    Given replica set "<%= cb.rs1 %>" becomes non-current for the "hello-openshift" deployment
    And current replica set name of "hello-openshift" deployment stored into :rs2 clipboard
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 13 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 8 |
    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 5 |
    When I run the :rollout_pause client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | .*[Pp]aused.*:.*true |
    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | 20              |
    Then the step should succeed
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 23 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 14 |
    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 9 |
    When I run the :rollout_resume client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 23 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 14 |
    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 9 |
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
    Then the step should succeed
    When I run the :rollout_undo client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
    Then the step should succeed
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 20 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 20 |
    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 0 |

  # @author geliu@redhat.com
  # @case_id OCP-12266
  Scenario: Proportionally scale - Special value test for proportional scaling
    Given I have a project
    Given I obtain test data file "deployment/hello-deployment-1.yaml"
    When I run the :create client command with:
      | f | hello-deployment-1.yaml |
    Then the step should succeed
    Given 10 pods become ready with labels:
      | app=hello-openshift |
    And current replica set name of "hello-openshift" deployment stored into :rs1 clipboard
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 10 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 10 |
    When I run the :patch client command with:
      | resource      | deployment                                                                                              |
      | resource_name | hello-openshift                                                                                         |
      | p             | {"spec":{"template":{"spec":{"containers":[{"image":"openshift/nonexist","name":"hello-openshift"}]}}}} |
    Then the step should succeed
    Given replica set "<%= cb.rs1 %>" becomes non-current for the "hello-openshift" deployment
    And current replica set name of "hello-openshift" deployment stored into :rs2 clipboard
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 13 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 8 |
    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 5 |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output should match:
      | .*image.*openshift/nonexist.* |
    When I run the :rollout_pause client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | .*[Pp]aused.*:.*true |
    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | -10             |
    Then the step should fail
    Then the output should match:
      | .*[Ee]rror.*replicas.*is required.* |
    When I run the :rollout_resume client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | test            |
    Then the step should fail
    Then the output should match:
      | .*[Ee]rror.*invalid argument.*test.* |
    When I run the :rollout_resume client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should fail
    Then the output should match:
      | .*[Ee]rror.*deployments.*hello-openshift.* |

  # @author geliu@redhat.com
  # @case_id OCP-14348
  Scenario: Proportionally scale - [OSO]deployment of scaling and rollout
    Given I have a project
    Given I obtain test data file "deployment/hello-deployment-oso.yaml"
    When I run the :create client command with:
      | f | hello-deployment-oso.yaml |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | app=hello-openshift |
    And current replica set name of "hello-openshift" deployment stored into :rs1 clipboard
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 2 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 2 |
    When I run the :rollout_pause client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | deployment      |
      | name     | hello-openshift |
      | replicas | 1               |
    Then the step should succeed
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 1 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 1 |
    When I run the :patch client command with:
      | resource      | deployment                                                                                               |
      | resource_name | hello-openshift                                                                                          |
      | p             | {"spec":{"template":{"spec":{"containers":[{"image":"openshift/nonexist1","name":"hello-openshift"}]}}}} |
    Then the step should succeed
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 1 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 1 |
    When I run the :rollout_resume client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed
    Given replica set "<%= cb.rs1 %>" becomes non-current for the "hello-openshift" deployment
    And current replica set name of "hello-openshift" deployment stored into :rs2 clipboard
    Given number of replicas of "hello-openshift" deployment becomes:
      | current | 1 |
    Given number of replicas of "<%= cb.rs1 %>" replica set becomes:
      | current | 0 |
    Given number of replicas of "<%= cb.rs2 %>" replica set becomes:
      | current | 1 |
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | revision      | 2               |
    Then the step should succeed
    And the output should match:
      | .*[iI]mage.*openshift/nonexist1.* |

  # @author yinzhou@redhat.com
  # @case_id OCP-19922
  Scenario: Terminating pod should removed from endpoints list for service
    Given I have a project
    Given I obtain test data file "deployment/deployment-with-shutdown-gracefully.json"
    When I run the :create client command with:
      | f | deployment-with-shutdown-gracefully.json |
    Then the step should succeed
    When I run the :expose client command with:
      | resource      | deploymentconfigs |
      | resource_name | nettest           |
    Then the step should succeed
    And I wait until the status of deployment "nettest" becomes :complete
    Given status becomes :running of 1 pods labeled:
      | app=nettest                       |
    When I run the :rollout_latest client command with:
      | resource | dc/nettest             |
    Then the step should succeed
    Given the pod named "<%= pod.name %>" becomes terminating
    When I run the :describe client command with:
      | resource | svc                    |
      | name     | nettest                |
    Then the output should not match:
      | <%= pod.ip %>:8080                |


  # @author yinzhou@redhat.com
  # @case_id OCP-30885
  Scenario: --dry-run parameter test
    Given the master version >= "4.5"
    Given I have a project
    When I run the :create_deployment client command with:
      | name    | mytest                                                                                                        |
      | image   | quay.io/openshifttest/hello-openshift@sha256:424e57db1f2e8e8ac9087d2f5e8faea6d73811f0b6f96301bc94293680897073 |
      | dry_run | client                                                                                                        |
    Then the step should succeed
    And the deployment named "mytest" does not exist in the project
    When I run the :create_deployment client command with:
      | name    | mytest                                                                                                        |
      | image   | quay.io/openshifttest/hello-openshift@sha256:424e57db1f2e8e8ac9087d2f5e8faea6d73811f0b6f96301bc94293680897073 |
      | dry_run | server                                                                                                        |
    Then the step should succeed
    Then the output should match:
      | server dry run |
    And the deployment named "mytest" does not exist in the project
    When I run the :create_deployment client command with:
      | name    | mytest                                                                                                        |
      | image   | quay.io/openshifttest/hello-openshift@sha256:424e57db1f2e8e8ac9087d2f5e8faea6d73811f0b6f96301bc94293680897073 |
      | dry_run | none                                                                                                          |
    Then the step should succeed
    Then the output should match:
      | mytest created |
    And I check that the "mytest" deployment exists in the project
