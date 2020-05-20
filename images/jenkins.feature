Feature: jenkins.feature
  # @author cryan@redhat.com
  Scenario Outline: Pipeline build, started before Jenkins is deployed, shouldn't get deleted
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    Given I get project builds
    Then the output should contain:
      | sample-pipeline-1 |
      | New               |
    Given I have a jenkins v2 application
    #Ensure the pre-existing build is still present after jenkins creation
    Given I get project builds
    Then the output should contain "sample-pipeline-1"
    And I wait up to 600 seconds for the steps to pass:
    """
    Given I get project builds
    Then the output should match:
      | sample-pipeline-1\s+JenkinsPipeline\s+Running |
    """

    Examples:
      | jenkins_version |
      | 2               | # @case_id OCP-11374

  # @author xiuwang@redhat.com
  # @case_id OCP-10975
  Scenario Outline: Use Jenkins as S2I builder with plugins
    Given I have a project
    Given I have a jenkins v<ver> application from "<%= BushSlicer::HOME %>/features/tierN/testdata/build/tc515317_536388/jenkins-with-plugins.json"
    And the "jenkins-master-1" build was created
    And the "jenkins-master-1" build completed
    When I run the :build_logs client command with:
      | build_name | jenkins-master-1 |
    Then the output should contain:
      | credentials     |
      | analysis-core   |
      | ansicolor       |
      | plugins         |
    Examples:
      | ver |
      | 2   |

  # @author xiuwang@redhat.com
  # @case_id OCP-13109
  Scenario Outline: Add/override env vars to pipeline buildconfigs when start-build pipeline build with -e
    Given I have a project
    And I have a jenkins v<version> application
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/OCP-13259/samplepipeline.yaml |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    When I perform the :jenkins_check_build_string_parameter web action with:
      | namespace| <%= project.name %>                 |
      | job_name | <%= project.name %>-sample-pipeline |
      | env_name | VAR1                                |
      | env_value| value1                              |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
      | env         | VAR1=newvalue   |
    Then the step should succeed
    When I perform the :jenkins_check_build_string_parameter web action with:
      | namespace| <%= project.name %>                 |
      | job_name | <%= project.name %>-sample-pipeline |
      | env_name | VAR1                                |
      | env_value| value1                              |
    Then the step should succeed
    And the "sample-pipeline-1" build completes
    When I perform the :goto_jenkins_buildlog_page web action with:
      | namespace| <%= project.name %>                |
      | job_name| <%= project.name %>-sample-pipeline |
      | job_num | 1                                   |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should contain:
      | VAR1 = newvalue|
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
      | env         | VAR2=value2     |
      | env         | VAR3=value3     |
    Then the step should succeed
    When I perform the :jenkins_check_build_string_parameter web action with:
      | namespace| <%= project.name %>                 |
      | job_name | <%= project.name %>-sample-pipeline |
      | env_name | VAR2                                |
      | env_value|                                     |
    Then the step should succeed
    When I perform the :jenkins_check_build_string_parameter web action with:
      | namespace| <%= project.name %>                 |
      | job_name | <%= project.name %>-sample-pipeline |
      | env_name | VAR3                                |
      | env_value|                                     |
    Then the step should succeed
    And the "sample-pipeline-2" build completes
    When I perform the :goto_jenkins_buildlog_page web action with:
      | namespace| <%= project.name %>                |
      | job_name| <%= project.name %>-sample-pipeline |
      | job_num | 2                                   |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should contain:
      | VAR1 = value1|
      | VAR2 = value2|
      | VAR3 = value3|

    Examples:
      | version |
      | 1       |
      | 2       |

  # @author xiuwang@redhat.com
  Scenario Outline: Using nodejs slave when do jenkinspipeline strategy
    Given I have a project
    Given I have a jenkins v<version> application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | jenkins/nodejs=true |
    Given the "sample-pipeline-1" build completes

    Examples:
      | version |
      | 2       | # @case_id OCP-11373

  # @author wewang@redhat.com
  # @case_id OCP-11372
  Scenario: Sync builds from jenkins to openshift
    Given I have a project
    And I have a jenkins v2 application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    Given I update "maven" slave image for jenkins 2 server
    Given I update "nodejs" slave image for jenkins 2 server
    And I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    When the "sample-pipeline-1" build becomes :running
    And the "nodejs-mongodb-example-1" build becomes :running
    Then the "nodejs-mongodb-example-1" build completed
    Then the "sample-pipeline-1" build completed
    And I run the steps 2 times:
    """
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    """
    Given I get project builds
    Then the output should contain 3 times:
      | sample-pipeline |
    When the "sample-pipeline-3" build becomes :running
    And I perform the :jenkins_verify_job_text web action with:
      | namespace  | <%= project.name %>                    |
      | job_name   | <%= project.name %>-sample-pipeline    |
      | checktext  | <%= project.name %>/sample-pipeline-3  |
      | job_num    | 3                                      |
      | time_out   | 300                                    |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type           | buildconfig     |
      | object_name_or_id     | sample-pipeline |
    Then the step should succeed
    When I perform the :jenkins_verify_project_job web action with:
      | namespace  | <%= project.name %>                 |
      | job_name   | <%= project.name %>-sample-pipeline |
      | time_out   | 300                                 |
    Then the step should fail

  # @author xiuwang@redhat.com
  # @case_id OCP-15196
  @admin
  Scenario: Using jenkins slave nodejs image to do pipeline build with limited resource
    And I have a project
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/OCP-15196/limitrange.json |
      | n | <%= project.name %>                                                                                    |
    Then the step should succeed
    Given I have a jenkins v2 application
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml |
    Then the step should succeed
    Given I have a jenkins browser
    And I log in to jenkins
    Given I update "nodejs" slave image for jenkins 2 server
    And I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    When the "sample-pipeline-1" build becomes :running
    And the "nodejs-mongodb-example-1" build becomes :running
    Then the "nodejs-mongodb-example-1" build completed
    Then the "sample-pipeline-1" build completed
    And a pod becomes ready with labels:
      | name=nodejs-mongodb-example |

  # @case_id OCP-18220
  Scenario: Jenkins API authentication should success until the first web access
    When I have a project
    And I have a persistent jenkins v2 application
    When I perform the HTTP request:
    """
    :url: https://<%= route("jenkins", service("jenkins")).dns(by: user) %>/login
    :method: :get
    :headers:
      :Authorization: Bearer <%= cb.user_token %>
    """
    Then the step should succeed
    And the output should contain:
      | <title>Jenkins</title> |
    And I ensure "<%= cb.jenkins_pod %>" pod is deleted
    And I wait for the "jenkins" service to become ready up to 300 seconds
    #Non-browser access to jenkins API with a Bearer
    When I perform the HTTP request:
    """
    :url: https://<%= route("jenkins", service("jenkins")).dns(by: user) %>/login
    :method: :get
    :headers:
      :Authorization: Bearer <%= cb.user_token %>
    """
    Then the step should succeed
    And the output should contain:
      | <title>Jenkins</title> |
    #Browser access to jenkins
    Given I have a jenkins browser
    Then I log in to jenkins
    #Non-browser access to jenkins API with a Bearer
    When I perform the HTTP request:
    """
    :url: https://<%= route("jenkins", service("jenkins")).dns(by: user) %>/login
    :method: :get
    :headers:
      :Authorization: Bearer <%= cb.user_token %>
    """
    Then the step should succeed
    And the output should contain:
      | <title>Jenkins</title> |

  # @author xiuwang@redhat.com
  # @case_id OCP-12784
  Scenario: Programmatic access to jenkins with openshift oauth
    Given I have a project
    And I have a jenkins v2 application
    And I find a bearer token of the system:serviceaccount:<%= project.name %>:jenkins service account
    And evaluation of `service_account.cached_tokens.first` is stored in the :token1 clipboard
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml |
    Then the step should succeed
    And I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    Given the "sample-pipeline-1" build becomes :running
    When I perform the HTTP request:
    """
      :method: get
      :url: https://<%= cb.jenkins_dns %>/job/<%= project.name %>/job/<%= project.name %>-sample-pipeline/1/consoleText
      :headers:
        Authorization: Bearer <%= cb.token1 %>
    """
    Then the step should succeed
    And the output should contain:
      | OpenShift Build <%= project.name %>/sample-pipeline-1 |
    When I perform the HTTP request:
    """
      :method: get
      :url: https://<%= cb.jenkins_dns %>/job/<%= project.name %>/job/<%= project.name %>-sample-pipeline/1/consoleText
      :headers:
        Authorization: Bearer invaildtoken
    """
    Then the step should fail
    And the expression should be true> @result[:exitstatus] == 401
