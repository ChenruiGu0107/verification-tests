Feature: limit range related scenarios:
  # @author pruan@redhat.com
  # @case_id OCP-10697, OCP-11175, OCP-11519
  @admin
  Scenario Outline: Limit range default request tests
    Given I have a project
    Given the first user is cluster-admin
    Then the step should succeed
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/<path>/limit.yaml
    Then the step should succeed
    And I run the :describe client command with:
      |resource | namespace |
      | name    | <%= project.name %>     |
    And the output should match:
      | <expr1> |
      | <expr2> |
    And I run the :delete client command with:
      | object_type | LimitRange |
      | object_name_or_id | limits |
    Then the step should succeed

    Examples:
      | path | expr1 | expr2 |
      | tc508038 | Container\\s+cpu\\s+\-\\s+\-\\s+200m\\s+200m\\s+\- | Container\\s+memory\\s+\-\\s+\-\\s+1Gi\\s+1Gi\\s+\- |
      | tc508039 | Container\\s+cpu\\s+200m\\s+\-\\s+200m\\s+\-\\s+\- | Container\\s+memory\\s+1Gi\\s+\-\\s+1Gi\\s+\-\\s+\- |
      | tc508040 | Container\\s+cpu\\s+\-\\s+200m\\s+200m\\s+200m\\s+\-  | Container\\s+memory\\s+\-\\s+1Gi\\s+1Gi\\s+1Gi\\s+\- |

  # @author pruan@redhat.com
  # @case_id OCP-11745, OCP-12200
  @admin
  Scenario Outline: Limit range invalid values tests
    Given I have a project
    Given the first user is cluster-admin
    Then the step should succeed
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/<path>/limit.yaml
    And the step should fail
    And the output should match:
      | LimitRange "limits" is invalid |
      | defaultRequest\[cpu\].* <expr2> value <expr3> is greater than <expr4> value <expr5> |
      | default\[cpu\].*<expr7> value <expr8> is greater than <expr9> value <expr10>       |
      | defaultRequest\[memory\].*<expr12> value <expr13> is greater than <expr14> value <expr15> |
      | default\[memory\].*<expr17> value <expr18> is greater than <expr19> value <expr20>         |

    Examples:
      | path | expr1 | expr2 | expr3 | expr4 | expr5 | expr6 | expr7 | expr8 | expr9 | expr10 | expr11 |expr12 | expr13| expr14 | expr15 | expr16 | expr17 | expr18 | expr19| expr20 |
      | tc508041 | 400m | default request | 400m | max | 200m | 200m | default | 400m | max | 200m | 2Gi | default request | 2Gi | max | 1Gi | 1Gi | default | 2Gi  | max   | 1Gi    |
      | tc508045 | 200m | min | 400m | default request | 200m | 400m | min | 400m | default | 200m | 1Gi | min | 2Gi | default request | 1Gi | 2Gi | min | 2Gi  | default   | 1Gi    |

  # @author pruan@redhat.com
  # @case_id OCP-12286
  @admin
  Scenario Outline: Limit range incorrect values
    Given I have a project
    Given the first user is cluster-admin
    Then the step should succeed
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/<path>/limit.yaml
    And the step should fail
    And the output should match:
      | min\[memory\].*<expr2> value <expr3> is greater than <expr4> value <expr5> |
      | min\[cpu\].*<expr7> value <expr8> is greater than <expr9> value <expr10>   |

    Examples:
      | path | expr1 | expr2 | expr3 | expr4 | expr5 | expr6 | expr7 | expr8 | expr9 | expr10 |
      | tc508047 | 2Gi | min | 2Gi | max | 1Gi | 400m | min | 400m | max | 200m |

  # @author pruan@redhat.com
  # @case_id OCP-12250
  @admin
  Scenario: Limit range does not allow min > defaultRequest
    Given I have a project
    Given the first user is cluster-admin
    Then the step should succeed
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/tc508046/limit.yaml
    Then the step should fail
    And the output should match:
      | cpu.*min value 400m is greater than default request value 200m    |
      | memory.*min value 2Gi is greater than default request value 1Gi   |

  # @author gpei@redhat.com
  # @case_id OCP-11918
  @admin
  Scenario: Limit range does not allow defaultRequest > default
    Given I have a project
    Given the first user is cluster-admin
    Then the step should succeed
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/tc508042/limit.yaml
    Then the step should fail
    And the output should match:
      | cpu.*default request value 400m is greater than default limit value 200m       |
      | memory.*default request value 2Gi is greater than default limit value 1Gi      |

  # @author gpei@redhat.com
  # @case_id OCP-12043
  @admin
  Scenario: Limit range does not allow defaultRequest > max
    Given I have a project
    Given the first user is cluster-admin
    Then the step should succeed
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/tc508043/limit.yaml
    Then the step should fail
    And the output should match:
      | cpu.*default request value 400m is greater than max value 200m      |
      | memory.*default request value 2Gi is greater than max value 1Gi     |

  # @author gpei@redhat.com
  # @case_id OCP-12139
  @admin
  Scenario: Limit range does not allow maxLimitRequestRatio > Limit/Request
    Given I have a project
    Given the first user is cluster-admin
    Then the step should succeed
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/tc508044/limit.yaml
    Then the step should succeed
    And I run the :describe client command with:
      |resource | namespace            |
      | name    | <%= project.name %>  |
    Then the output should match:
      | Container\\s+cpu\\s+\-\\s+\-\\s+\-\\s+\-\\s+4    |
      | Container\\s+memory\\s+\-\\s+\-\\s+\-\\s+\-\\s+4 |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/tc508044/pod.yaml |
    Then the step should fail
    And the output should contain:
      | cpu max limit to request ratio per Container is 4, but provided ratio is 15.000000              |

  # @author gpei@redhat.com
  # @case_id OCP-12315
  @admin
  Scenario: Limit range with all values set with proper values
    Given I have a project
    When I run oc create as admin over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/tc508048/limit.yaml
    Then the step should succeed
    And I run the :describe client command with:
      |resource | namespace            |
      | name    | <%= project.name %>  |
    Then the output should match:
      | Pod\\s+cpu\\s+20m\\s+960m\\s+\-\\s+\-\\s+\-                |
      | Pod\\s+memory\\s+10Mi\\s+1Gi\\s+\-\\s+\-\\s+\-             |
      | Container\\s+cpu\\s+10m\\s+480m\\s+180m\\s+240m\\s+4       |
      | Container\\s+memory\\s+5Mi\\s+512Mi\\s+128Mi\\s+256Mi\\s+4 |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/tc508048/pod.yaml |
      | n | <%= project.name %>  |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | pod    |
      | resource_name | mypod  |
      | o             | yaml   |
    Then the output should match:
      | \\s+limits:\n\\s+cpu: 300m\n\\s+memory: 300Mi\n   |
      | \\s+requests:\n\\s+cpu: 100m\n\\s+memory: 100Mi\n |
    """
  # @author xiaocwan@redhat.com
  # @case_id OCP-12339
  @admin
  Scenario: The number of created persistent volume claims can not exceed the limitation
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/kubernetes/kubernetes/master/test/fixtures/doc-yaml/admin/resourcequota/quota.yaml"
    And I replace lines in "quota.yaml":
      | persistentvolumeclaims: "10" | persistentvolumeclaims: "1"        |
    When I run the :create admin command with:
      | f |  quota.yaml         |
      | n | <%= project.name %> |
    Then the step should succeed
    And the output should match:
      | [Rr]esourcequota.*quota.*created |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/kubernetes/kubernetes/master/test/fixtures/doc-yaml/user-guide/persistent-volumes/claims/claim-01.yaml |
    Then the step should succeed
    And the output should match:
      | [Pp]ersistentvolumeclaim.*myclaim-1.*created |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/kubernetes/kubernetes/master/test/fixtures/doc-yaml/user-guide/persistent-volumes/claims/claim-01.yaml |
    Then the step should fail
    And the output should match:
      | [Ee]rror.*when creat.*myclaim-1.*forbidden.*[Ee]xceeded quota |


  # @author yinzhou@redhat.com
  # @case_id OCP-11289
  @admin
  Scenario: Check the openshift.io/imagestreams of quota in the project after build image
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/openshift-object-counts.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | quota |
      | resource_name | openshift-object-counts |
      | template      | {{.status.used}} |
      | n             | <%= project.name %> |
    Then the output should match "openshift.io/imagestreams:0"
    """
    When I run the :new_build client command with:
      | app_repo | centos/ruby-22-centos7~https://github.com/openshift/ruby-ex.git |
    Then the step should succeed
    And the "ruby-ex-1" build was created
    Then the "ruby-ex-1" build completes
    When I run the :get client command with:
      | resource      | quota |
      | resource_name | openshift-object-counts |
      | template      | {{.status.used}} |
      | n             | <%= project.name %> |
    Then the output should match "openshift.io/imagestreams:2"
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    Then the "ruby-ex-2" build completes
    When I run the :get client command with:
      | resource      | quota |
      | resource_name | openshift-object-counts |
      | template      | {{.status.used}} |
      | n             | <%= project.name %> |
    Then the output should match "openshift.io/imagestreams:2"


  # @author yinzhou@redhat.com
  # @case_id OCP-11594
  @admin
  Scenario: Check the quota after import-image with --all option
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/openshift-object-counts.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | quota |
      | resource_name | openshift-object-counts |
      | template      | {{.status.used}} |
      | n             | <%= project.name %> |
    Then the output should match "openshift.io/imagestreams:0"
    """
    When I run the :import_image client command with:
      | image_name | centos           |
      | from       | docker.io/centos |
      | confirm    | true             |
      | all        | true             |
    Then the step should succeed
    When I run the :tag client command with:
      | source_type  | docker                           |
      | source       | docker.io/library/busybox:latest |
      | dest         | mystream:latest                  |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | quota |
      | resource_name | openshift-object-counts |
      | template      | {{.status.used}} |
      | n             | <%= project.name %> |
    Then the output should match "openshift.io/imagestreams:2"
    """


  # @author yinzhou@redhat.com
  # @case_id OCP-12214
  @admin
  Scenario: When exceed openshift.io/image-tags will ban to create new image references in the project
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/image-limit-range.yaml"
    And I replace lines in "image-limit-range.yaml":
      | openshift.io/image-tags: 20 | openshift.io/image-tags: 1 |
    Then the step should succeed
    When I run the :create admin command with:
      | f | image-limit-range.yaml |
      | n | <%= project.name %>    |
    Then the step should succeed
    When I run the :tag client command with:
      | source_type  | docker                           |
      | source       | docker.io/library/busybox:latest |
      | dest         | mystream:v1                      |
    Then the step should succeed
    When I run the :tag client command with:
      | source_type  | docker                    |
      | source       | openshift/hello-openshift |
      | dest         | mystream:v2               |
    Then the step should fail
    And the output should contain:
      | forbidden |


  # @author yinzhou@redhat.com
  # @case_id OCP-12263
  @admin
  Scenario: When exceed openshift.io/images will ban to create image reference or push image to project
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role            | registry-admin   |
      | user name       | system:anonymous |
    Then the step should succeed
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/image-limit-range.yaml"
    And I replace lines in "image-limit-range.yaml":
      | openshift.io/images: 30 | openshift.io/images: 1 |
    Then the step should succeed
    When I run the :create admin command with:
      | f | image-limit-range.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :tag client command with:
      | source_type  | docker                           |
      | source       | docker.io/library/busybox:latest |
      | dest         | mystream:v1                      |
    Then the step should succeed
    When I run the :tag client command with:
      | source_type  | docker                    |
      | source       | openshift/hello-openshift |
      | dest         | mystream:v2               |
    And I run the :describe client command with:
      |resource | imagestream |
      | name    | mystream    |
    And the output should contain:
      | Import failed |
    Given default registry service ip is stored in the :integrated_reg_ip clipboard
    And I select a random node's host
    When I run commands on the host:
      | docker pull docker.io/openshift/deployment-example |
      | docker tag docker.io/openshift/deployment-example <%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:v3 |
    Then the step should succeed
    When I run commands on the host:
      | docker push <%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:v3 |
    Then the step should fail
    And the output should contain:
      | denied |
