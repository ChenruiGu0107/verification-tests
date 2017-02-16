Feature: oc tag related scenarios

  # @author xxia@redhat.com
  # @case_id OCP-11142 OCP-11907 OCP-11733 OCP-12038
  Scenario Outline: Tag an image into image stream
    Given I have a project
    When I run the :tag client command with:
      | source_type  | docker                     |
      | source       | docker.io/library/busybox:latest   |
      | dest         | mystream:latest            |
    Then the step should succeed
    # Cucumber runs steps fast. Need wait for the istag so that it really can be referenced by following steps
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | istag             |
      | resource_name | mystream:latest   |
    Then the step should succeed
    """

    When I run the :get client command with:
      | resource      | istag             |
      | resource_name | mystream:latest   |
      | template      | {{.image.metadata.name}}   |
    Then the step should succeed
    And evaluation of `"mystream@" + @result[:response]` is stored in the :src clipboard

    When I run the :tag client command with:
      | source_type  | <source_type>              |
      | source       | <source>                   |
      | dest         | <deststream>:tag           |
      | alias        | true                       |
    Then the step should succeed

    # Same reason as above. Need wait, instead of one-time check
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | istag             |
      | resource_name | <deststream>:tag  |
    Then the step should succeed
    """
    When I run the :get client command with:
      | resource      | is                |
      | resource_name | <deststream>      |
      | o             | yaml              |
    Then the step should succeed
    And the output should contain:
      | from:                             |
      |   kind: <kind>                    |
      |   name: <source>                  |

    # Add case_id to easily find the row for each case
    Examples: Tag into imagestream that does not exist
      | case_id | source_type | source          | deststream | kind             |
      | 492275  | isimage     | <%= cb.src %>   | newstream  | ImageStreamImage |
      | 492278  | istag       | mystream:latest | newstream  | ImageStreamTag   |

    Examples: Tag into imagestream that exists
      | case_id | source_type | source          | deststream | kind             |
      | 492277  | istag       | mystream:latest | mystream   | ImageStreamTag   |
      | 492279  | docker      | docker.io/library/busybox:latest  | mystream   | DockerImage      |

  # @author xxia@redhat.com
  # @case_id OCP-11496
  Scenario: Tag an image into mutliple image streams
    Given I have a project
    When I run the :tag client command with:
      | source_type  | docker                     |
      | source       | docker.io/library/busybox:latest   |
      | dest         | mystream:latest            |
    Then the step should succeed
    # Cucumber runs steps fast. Need wait for the istag so that it really can be referenced by following steps
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | istag             |
      | resource_name | mystream:latest   |
    Then the step should succeed
    """

    When I run the :tag client command with:
      | source_type  | docker                     |
      | source       | docker.io/library/busybox:latest   |
      | dest         | mystream:tag               |
    Then the step should succeed
    # Same reason as above case. Need wait, instead of one-time check
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | is                |
    Then the step should succeed
    And the output should match "mystream.+tag,latest"
    """

    When I create a new project
    Then the step should succeed
    And I create a new project
    Then the step should succeed
    When I run the :tag client command with:
      | source_type  | istag                                 |
      | source       | <%= @projects[0].name %>/mystream:latest |
      | dest         | <%= @projects[0].name %>/mystream:tag1   |
      | dest         | <%= @projects[1].name %>/stream1:tag1  |
      | dest         | <%= @projects[2].name %>/stream2:tag2  |
    Then the step should succeed

    When I run the :get client command with:
      | resource      | is                      |
      | namespace     | <%= @projects[0].name %> |
    Then the step should succeed
    And the output should match "mystream.+tag1,tag,latest"
    When I run the :get client command with:
      | resource      | is                      |
      | namespace     | <%= @projects[2].name %> |
    Then the step should succeed
    And the output should match "stream2.+tag2"

  # @author cryan@redhat.com
  # @case_id OCP-9864
  # @bug_id 1304109
  Scenario: oc tag gets istag pointing to image of latest revision from the source istag
    Given I have a project
    And evaluation of `project.name` is stored in the :stage clipboard
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    Given the "ruby-sample-build-1" build completes
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given the "ruby-sample-build-2" build completes
    When I run the :get client command with:
      | resource | istag |
      | resource_name | origin-ruby-sample:latest |
      | template | {{.image.metadata.name}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :img2 clipboard
    When I create a new project
    Then the step should succeed
    And evaluation of `project.name` is stored in the :prod clipboard
    When I run the :tag client command with:
      | source       | <%= cb.stage %>/origin-ruby-sample:latest |
      | dest         | <%= cb.prod %>/myis:tag1 |
    Then the step should succeed
    Then the output should match "set to.*<%= cb.img2[0..15] %>"

  # @author yanpzhan@redhat.com
  # @case_id OCP-10862
  Scenario: Delete spec tags
    Given I have a project
    When I run the :tag client command with:
      | source_type  | docker                     |
      | source       | docker.io/library/busybox:latest |
      | dest         | mystream:v1     |
      | dest         | mystream:latest |
    Then the step should succeed

    # Cucumber runs steps fast. Need wait for the istag so that it really can be referenced by following steps
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | istag       |
      | resource_name | mystream:v1 |
      | resource_name | mystream:latest |
    Then the step should succeed
    """

    When I run the :get client command with:
      | resource      | is   |
      | resource_name | mystream |
      | template      | "{{range .spec.tags}} name: {{.name}} {{end}};{{range .status.tags}} tag: {{.tag}} {{end}}" |
    Then the step should succeed
    And the output should contain "name: latest  name: v1 ; tag: latest  tag: v1"

    When I run the :tag client command with:
      | source | mystream:v1 |
      | dest   | mystream:latest |
      | d      | true      |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | is   |
      | resource_name | mystream |
      | template      | "{{.spec}};{{range .status.tags}} tag: {{.tag}} {{end}}" |
    Then the step should succeed
    And the output should contain "map[];"

    When I run the :tag client command with:
      | source | mystream:nonexist |
      | d      | true      |
    Then the step should fail
    And the output should contain:
      | not found |

  # @author mcurlej@redhat.com
  # @case_id OCP-12154
  Scenario: Tag should correctly add muptiple imagestreamtags to one imagestream
    Given I have a project
    When I run the :tag client command with:
      | source_type  | docker                  |
      | source       | openshift/origin:latest |
      | dest         | ruby:tip                |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | is   |
      | name     | ruby |
    Then the step should succeed
    And the output should match:
      | tip\s.*openshift\/origin:latest |
    When I run the :get client command with:
      | resource      | istag    |
      | resource_name | ruby:tip |
      | output        | yaml     |
    Then the step should succeed
    And the expression should be true> @result[:parsed].dig("image", "dockerImageLayers", 0, "size")
    When I run the :tag client command with:
      | source_type  | docker                  |
      | source       | openshift/origin:v1.2.0 |
      | dest         | ruby:another            |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | is   |
      | name     | ruby |
    Then the step should succeed
    And the output should match:
      | tip\s.*openshift\/origin:latest       |
      | another\s.*openshift\/origin:v1\.2\.0 |
    When I run the :get client command with:
      | resource      | istag        |
      | resource_name | ruby:another |
      | output        | yaml         |
    Then the step should succeed
    And the expression should be true> @result[:parsed].dig("image", "dockerImageLayers", 0, "size")
    When I run the :tag client command with:
      | source_type  | docker                |
      | source       | openshift/origin:fail |
      | dest         | ruby:fail             |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | is   |
      | name     | ruby |
    Then the step should succeed
    And the output should match:
      | tip\s.*openshift\/origin:latest    |
      | another\s.*openshift/origin:v1.2.0 |
      | fail\s.*openshift\/origin:fail     |
      | [Ii]mport failed                   |
    When I run the :get client command with:
      | resource      | istag     |
      | resource_name | ruby:fail |
      | output        | yaml      |
    Then the step should fail
    And the output should match:
      | Error from server |
      | ruby:fail         |
      | not found         |

  # @author pruan@redhat.com
  # @case_id OCP-10171
  Scenario: New-app using tagged imagestreamtag across projects without cross-namespace permission
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    Then I run the :new_build client command with:
      | app_repo | centos/ruby-22-centos7~https://github.com/openshift/ruby-ex.git |
      | name     | origin-ruby-sample                                              |
    Then the step should succeed
    Given the "origin-ruby-sample-1" build was created
    And the "origin-ruby-sample-1" build completed
    And I create a new project
    Then the step should succeed
    And I run the :tag client command with:
      | source | <%= cb.proj1 %>/origin-ruby-sample:latest |
      | dest   | <%= project.name %>/deadbeef533103:tag1         |
    Then the step should succeed
    Then I run the :get client command with:
      | resource      | is             |
      | resource_name | deadbeef533103 |
      | o             | yaml           |
    Then the expression should be true> @result[:parsed]['status']['tags'][0]['items'][0]['dockerImageReference'].include? project.name
    When I run the :new_app client command with:
      | app_repo | deadbeef533103:tag1 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=deadbeef533103 |

  # @author yinzhou@redhat.com
  # @case_id OCP-12212
  @admin
  Scenario: The image import controller should only import the necessary tag for specific docker image
    Given I have a project
    When I run the :tag client command with:
      | source_type  | docker                            |
      | source       | aosqe/ssh-git-server:git-20150525 |
      | dest         | ssh-git-server:git-20150525       |
      | insecure     | true                              |
    Then the step should succeed
    Given I use the "<%= env.master_hosts.first.hostname %>" node
    When I run commands on the host:
      | journalctl -l -u atomic-openshift-master --since "1 min ago" \| grep partial=true |
    Then the step should succeed
    And the output should contain:
      | Importing stream <%= project.name %>/ssh-git-server partial=true |
    When I get project is named "ssh-git-server" as YAML
    And the expression should be true> @result[:parsed]['spec']['tags'].size == 1

