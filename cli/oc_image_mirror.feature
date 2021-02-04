Feature: oc image mirror related scenarios

  # @author yinzhou@redhat.com
  @admin
  Scenario Outline: Check `oc image mirror` with multi-arch images
    And evaluation of `image_stream("cli", project("openshift")).tags.first.from.name` is stored in the :oc_cli clipboard
    Given I have a project
    Given I have a registry in my project
    Given I obtain test data file "cli/OCP-37363/<file_name>"
    When I run oc create over "<file_name>" replacing paths:
      | ["spec"]["containers"][0]["image"]   | <%= cb.oc_cli %>              |
      | ["spec"]["containers"][0]["args"][3] | <%= cb.reg_svc_url %>/busybox |
    Then the step should succeed
    Given the pod named "mirrorfilter" status becomes :succeeded
    Given I obtain test data file "cli/OCP-37363/check-image.yaml"
    When I run oc create over "check-image.yaml" replacing paths:
      | ["spec"]["containers"][0]["image"]   | <%= cb.oc_cli %>              |
      | ["spec"]["containers"][0]["args"][2] | <%= cb.reg_svc_url %>/busybox |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name    | pod/imageinfo |
    Then the step should succeed
    And the output should match "the image is a manifest list and contains multiple images"
    """

    Examples:
      | file_name                 |
      | mirror-filter-37363.yaml  | # @case_id OCP-37363
      | mirror-filter-38859.yaml  | # @case_id OCP-38859


  # @author yinzhou@redhat.com
  # @case_id OCP-38660
  @admin
  Scenario: Check `oc image mirror` with multi-arch images --filter-by-os=not/wildcard
    And evaluation of `image_stream("cli", project("openshift")).tags.first.from.name` is stored in the :oc_cli clipboard
    Given I have a project
    Given I have a registry in my project
    Given I obtain test data file "cli/OCP-37363/mirror-filter.yaml"
    When I run oc create over "mirror-filter.yaml" replacing paths:
      | ["spec"]["containers"][0]["image"]   | <%= cb.oc_cli %>              |
      | ["spec"]["containers"][0]["args"][3] | <%= cb.reg_svc_url %>/busybox |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name    | pod/mirrorfilter |
    Then the step should succeed
    And the output should contain "--keep-manifest-list=true cannot be passed with --filter-by-os, unless --filter-by-os=.*"
    """
    When I run oc create over "mirror-filter.yaml" replacing paths:
      | ["metadata"]["name"]                 | "mirrorfilter2"                   |
      | ["metadata"]["labels"]["name"]       | "mirrorfilter2"                   |
      | ["spec"]["containers"][0]["image"]   | <%= cb.oc_cli %>                  |
      | ["spec"]["containers"][0]["args"][3] | <%= cb.reg_svc_url %>/busybox:386 |
      | ["spec"]["containers"][0]["args"][5] | ""                                |
    Then the step should succeed
    Given the pod named "mirrorfilter2" status becomes :succeeded
    Given I obtain test data file "cli/OCP-37363/check-image.yaml"
    When I run oc create over "check-image.yaml" replacing paths:
      | ["spec"]["containers"][0]["image"]   | <%= cb.oc_cli %>                  |
      | ["spec"]["containers"][0]["args"][2] | <%= cb.reg_svc_url %>/busybox:386 |
    Then the step should succeed
    Given the pod named "imageinfo" status becomes :succeeded
    Given I wait for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name    | pod/imageinfo |
    Then the step should succeed
    And the output should match "Arch:.*386"
    """
    When I run oc create over "mirror-filter.yaml" replacing paths:
      | ["metadata"]["name"]                 | "mirrorfilter3"                       |
      | ["metadata"]["labels"]["name"]       | "mirrorfilter3"                       |
      | ["spec"]["containers"][0]["image"]   | <%= cb.oc_cli %>                      |
      | ["spec"]["containers"][0]["args"][3] | <%= cb.reg_svc_url %>/busybox:default |
      | ["spec"]["containers"][0]["args"][5] | ""                                    |
      | ["spec"]["containers"][0]["args"][6] | ""                                    |
    Then the step should succeed
    Given the pod named "mirrorfilter3" status becomes :succeeded
    When I run oc create over "check-image.yaml" replacing paths:
      | ["metadata"]["name"]                 | "imageinfo2"                          |
      | ["metadata"]["labels"]["name"]       | "imageinfo2"                          |
      | ["spec"]["containers"][0]["image"]   | <%= cb.oc_cli %>                      |
      | ["spec"]["containers"][0]["args"][2] | <%= cb.reg_svc_url %>/busybox:default |
    Then the step should succeed
    Given the pod named "imageinfo2" status becomes :succeeded
    Given I wait for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name    | pod/imageinfo2 |
    Then the step should succeed
    And the output should match "Arch:.*amd64"
    """
