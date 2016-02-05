Feature: test git steps
  Scenario: git test
    Given I have a project
    And I git clone the repo "https://github.com/openshift/ruby-hello-world"
    And I git clone the repo "https://github.com/openshift/ruby-hello-world" to "dummy"
    And I get the latest git commit id from repo "https://github.com/openshift/ruby-hello-world"
    And I get the latest git commit id from repo "ruby-hello-world"
    And I get the latest git commit id from repo "dummy"
