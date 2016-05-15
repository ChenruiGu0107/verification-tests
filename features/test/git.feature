Feature: test git steps
  Scenario: git test
    And I git clone the repo "https://github.com/openshift/ruby-hello-world"
    And I git clone the repo "https://github.com/openshift/ruby-hello-world" to "dummy"
    And I get the latest git commit id from repo "https://github.com/openshift/ruby-hello-world"
    And I get the latest git commit id from repo "ruby-hello-world"
    And I get the latest git commit id from repo "dummy"
    Given a "dummy/testfile" file is created with the following lines:
    """
    TC 510666 test
    """
    And I git add all files from repo "dummy"
    And I make a commit with message "test" to repo "dummy"
    And I get the latest git commit id from repo "dummy"
