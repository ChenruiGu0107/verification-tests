Feature: oc annotate related features
  # @author xxia@redhat.com
  Scenario Outline: Update the annotations on more resources
    Given I have a project
    Given I obtain test data file "pods/hello-pod.json"
    When I run the :create client command with:
      | f | hello-pod.json |
    Then the step should succeed
    When I run oc create with "hello-pod.json" replacing paths:
      | ["metadata"]["name"]  | hello-again |
    Then the step should succeed
    And all existing pods are ready with labels:
      | name=hello-openshift |
    When I run the :annotate client command with:
      | _tool        | <tool>                  |
      | resource     | pod                     |
      | resourcename | hello-openshift         |
      | resourcename | hello-again             |
      | keyval       | description=many-pods   |
    Then the step should succeed
    When I run the :get client command with:
      | _tool    | <tool>  |
      | resource | pod     |
      |  o       | yaml    |
    Then the step should succeed
    And the output should contain 2 times:
      | description: many-pods  |

    # Check --overwrite
    When I run the :annotate client command with:
      | _tool        | <tool>                  |
      | resource     | pod                     |
      | resourcename | hello-openshift         |
      | resourcename | hello-again             |
      | overwrite    | true                    |
      | keyval       | description=more-pods   |
    Then the step should succeed
    When I run the :get client command with:
      | resource | pod     |
      |  o       | yaml    |
    Then the step should succeed
    And the output should contain 2 times:
      | description: more-pods  |

    # Check no --overwrite (false by default)
    When I run the :annotate client command with:
      | _tool        | <tool>             |
      | resource     | pod                |
      | resourcename | hello-openshift    |
      | resourcename | hello-again        |
      | keyval       | description=pods   |
    Then the step should fail
    And the output should match 2 times:
      | --overwrite is false.*already has a value |

    # Check --all and remove annotations
    When I run the :annotate client command with:
      | _tool        | <tool>         |
      | resource     | pod            |
      | all          | true           |
      | keyval       | description-   |
    Then the step should succeed
    When I run the :get client command with:
      | _tool    | <tool>  |
      | resource | pod     |
      |  o       | yaml    |
    Then the step should succeed
    And the output should not contain "description:"

    Examples:
      | tool     |
      | oc       | # @case_id OCP-10671
      | kubectl  | # @case_id OCP-21056

  # @author xxia@redhat.com
  Scenario Outline: Update the annotations on one resource
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
    Then the step should succeed

    Given the pod named "hello-openshift" becomes ready
    When I run the :annotate client command with:
      | _tool        | <tool>               |
      | resource     | pod/hello-openshift  |
      | keyval       | description=pod      |
    Then the step should succeed
    When I run the :get client command with:
      | _tool    | <tool>  |
      | resource | pod     |
      |  o       | yaml    |
    Then the step should succeed
    And the output should contain "description: pod"

    When I run the :get client command with:
      | _tool        | <tool>                        |
      | resource     | pod/hello-openshift           |
      | template     | {{.metadata.resourceVersion}} |
    Then the step should succeed
    Given evaluation of `@result[:response]` is stored in the :version clipboard
    # Check --resource-version
    When I run the :annotate client command with:
      | _tool           | <tool>               |
      | resource        | pod/hello-openshift  |
      | resourceversion | <%= cb.version %>    |
      | keyval          | new=pod              |
    Then the step should succeed

    # Check --resource-version with invalid value
    When I run the :annotate client command with:
      | _tool           | <tool>               |
      | resource        | pod/hello-openshift  |
      | resourceversion | 1111111              |
      | keyval          | newer=pod            |
    Then the step should fail
    And the output should match:
      | object has been modified.*please apply your changes to the latest version and try again |

    # Remove annotation
    When I run the :annotate client command with:
      | _tool        | <tool>               |
      | resource     | pod/hello-openshift  |
      | keyval       | description-         |
    Then the step should succeed
    When I run the :get client command with:
      | _tool    | <tool>  |
      | resource | pod     |
      |  o       | yaml    |
    Then the step should succeed
    And the output should not contain "description:"

    Examples:
      | tool     |
      | oc       | # @case_id OCP-11161
      | kubectl  | # @case_id OCP-21057
