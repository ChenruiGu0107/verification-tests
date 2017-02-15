Feature: Get the build dependencies

  # @author wewang@redhat.com
  # @case_id OCP-11449
  Scenario: Get the build dependencies for image all tags
    Given I have a project
    Then evaluation of `project.name` is stored in the :proj_name clipboard
    When I run the :import_image client command with:
      | image_name   | ruby |
      | from         | centos/ruby-22-centos7 |
      | confirm      | true |
    Then the step should succeed
    When I get project is as JSON
    Then the output should contain "<%= cb.proj_name %>/ruby"
    When I run the :new_app client command with:
      | image_stream   | <%= cb.proj_name %>/ruby |
      | app_repo       | https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    And I create a new project
    Then evaluation of `project.name` is stored in the :proj1_name clipboard
    When I run the :new_app client command with:
      | image_stream   | <%= cb.proj_name %>/ruby |
      | app_repo       | https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    When I use the "<%= cb.proj_name %>" project
    And I run the :oadm_build_chain client command with:
      | imagestreamtag   | ruby |
      | all   | true |
    Then the step should succeed
    And the output should contain:
      | <%= cb.proj_name %> istag/ruby:latest |
      | <%= cb.proj_name %> bc/ruby-hello-world |
      | <%= cb.proj_name %> istag/ruby-hello-world:latest |
      | <%= cb.proj1_name %> bc/ruby-hello-world |
      | <%= cb.proj1_name %> istag/ruby-hello-world:latest |
    When I run the :oadm_build_chain client command with:
      | imagestreamtag   | ruby |
      | all   | true |
      | o     | dot |
    Then the step should succeed
    And the output should contain:
      | [label="BuildConfig|<%= cb.proj_name %>/ruby-hello-world"]; |
      | [label="BuildConfig|<%= cb.proj1_name %>/ruby-hello-world"];|
      | [label="ImageStreamTag|<%= cb.proj_name %>/ruby:latest"]; |
      | [label="ImageStreamTag|<%= cb.proj_name %>/ruby-hello-world:latest"]; |
      | [label="ImageStreamTag|<%= cb.proj1_name %>/ruby-hello-world:latest"]; |

  # @author shiywang@redhat.com
  # @case_id OCP-12636
  Scenario: Get the build dependencies for a image repository within one namespace
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role      | admin                                           |
      | user_name | system:serviceaccount:<%=project.name%>:default |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    When I run the :oadm_build_chain client command with:
      | imagestreamtag | origin-ruby-sample:latest |
    Then the step should succeed
    And the output should contain:
      | istag/origin-ruby-sample:latest |
    When I run the :oadm_build_chain client command with:
      | imagestreamtag | origin-ruby-sample:latest |
      | o              | dot                       |
    Then the step should succeed
    And the output should contain:
      | origin-ruby-sample:latest                                             |
      | label="ImageStreamTag\|<%= project.name %>/origin-ruby-sample:latest" |
    When I run the :oadm_build_chain client command with:
      | imagestreamtag | origin-ruby-sample:latest |
      | trigger_only   | true                      |
    Then the step should succeed
    And the output should contain:
      | istag/origin-ruby-sample:latest |