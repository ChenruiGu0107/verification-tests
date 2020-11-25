Feature: test master config related steps

  # @author scheng@redhat.com
  # @case_id OCP-15816
  @admin
  Scenario: accessTokenMaxAgeSeconds in oauthclient could not be set to other than positive integer number
    When I run the :patch admin command with:
      | resource      | oauthclient                         |
      | resource_name | openshift-browser-client            |
      | p             | {"accessTokenMaxAgeSeconds": abcde} |
    Then the step should fail
    And the output should contain "invalid character 'a' looking for beginning of value"
    When I run the :patch admin command with:
      | resource      | oauthclient                          |
      | resource_name | openshift-browser-client             |
      | p             | {"accessTokenMaxAgeSeconds": !@#$$%# |
    Then the step should fail
    And the output should contain "invalid character '!' looking for beginning of value"
    When I run the :patch admin command with:
      | resource      | oauthclient                          |
      | resource_name | openshift-browser-client             |
      | p             | {"accessTokenMaxAgeSeconds": 12.345} |
    Then the step should fail
    And the output should contain "cannot convert float64 to int32"
