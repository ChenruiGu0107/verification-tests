Feature: customize console related

  # @author yanpzhan@redhat.com
  # @case_id OCP-19811
  @destructive
  @admin
  Scenario: Customize console logout url
    Given the master version >= "3.11"
    And system verification steps are used:
    """
    I switch to cluster admin pseudo user
    I use the "openshift-console" project
    Given a pod becomes ready with labels:
      | app=openshift-console |
    When admin executes on the pod:
      | cat | /var/console-config/console-config.yaml |
    Then the step should succeed
    And the output should not contain "https://www.example.com"
    """

    And I register clean-up steps:
    """
    I run the :delete admin command with:
      | object_type | pod                   |
      | l           | app=openshift-console |
    the step should succeed
    """
    And the "console-config" configmap is recreated by admin in the "openshift-console" project after scenario

    When value of "console-config.yaml" in configmap "console-config" as YAML is merged with:
    """
    auth:
      logoutRedirect: 'https://www.example.com'
    """
    And I run the :delete admin command with:
      | object_type | pod                   |
      | l           | app=openshift-console |
    Then the step should succeed

    Given a pod becomes ready with labels:
      | app=openshift-console |
    When admin executes on the pod:
      | cat | /var/console-config/console-config.yaml |
    Then the step should succeed
    And the output should contain "https://www.example.com"

    Given I switch to the first user
    Given I open admin console in a browser
    When I run the :goto_projects_list_page web action
    Then the step should succeed

    When I run the :click_logout web action
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    Given the expression should be true> browser.url.match("https://www.example.com/")
    """

  # @author yanpzhan@redhat.com
  # @case_id OCP-22330
  @destructive
  @admin
  Scenario: console customization
    Given the master version >= "4.1"
    Given I register clean-up steps:
    """
    When I run the :patch admin command with:
      | resource | console.operator/cluster         |
      | type     | merge                            |
      | p        | {"spec":{"customization": null}} |
    Then the step should succeed
    When I run the :patch admin command with:
      | resource | console.config/cluster            |
      | type     | merge                             |
      | p        | {"spec":{"authentication": null}} |
    Then the step should succeed
    """

    When I run the :get admin command with:
      | resource      | deployment        |
      | resource_name | console           |
      | o             | yaml              |
      | namespace     | openshift-console |
    Then the step should succeed
    And evaluation of `@result[:parsed]["metadata"]["annotations"]["deployment.kubernetes.io/revision"].to_i` is stored in the :version_before_deploy clipboard

    When I run the :patch admin command with:
      | resource | console.operator/cluster |
      | type     | merge                    |
      | p        | {"spec":{"customization": {"brand":"okd","documentationBaseURL":"https://docs.okd.io/latest/"}}} |
    Then the step should succeed

    When I run the :patch admin command with:
      | resource | console.config/cluster |
      | type     | merge                  |
      | p        | {"spec":{"authentication": {"logoutRedirect":"https://www.openshift.com"}}} |
    Then the step should succeed

    Given I wait for the steps to pass:
    """
    When I run the :get admin command with:
      | resource      | deployment        |
      | resource_name | console           |
      | o             | yaml              |
      | namespace     | openshift-console |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["metadata"]["annotations"]["deployment.kubernetes.io/revision"].to_i > <%= cb.version_before_deploy %>+1
    """

    Given I switch to cluster admin pseudo user
    And I use the "openshift-console" project
    Given number of replicas of the current replica set for the "console" deployment becomes:
      | desired  | 2 |
      | current  | 2 |
      | ready    | 2 |

    Given I switch to the first user
    And I open admin console in a browser
    When I perform the :check_header_brand web action with:
      | logo_source  | okd-logo |
      | product_name | OKD      |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | documentation               |
      | link_url | https://docs.okd.io/latest/ |
    Then the step should succeed

    When I run the :click_logout web action
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    Given the expression should be true> browser.url.match("https://www.openshift.com")
    """

    When I run the :patch admin command with:
      | resource | console.config/cluster |
      | type     | merge                  |
      | p        | {"spec":{"authentication": {"logoutRedirect":"http://www.ocptest.com"}}} |
    Then the step should fail

    When I run the :patch admin command with:
      | resource | console.config/cluster |
      | type     | merge                  |
      | p        | {"spec":{"authentication": {"logoutRedirect":"www.ocptest.com"}}} |
    Then the step should fail

  # @author yapei@redhat.com
  # @case_id OCP-22640
  @admin
  @destructive
  Scenario: Add HTPasswd IDP
    Given the master version >= "4.1"

    # restore oauth/cluster after scenarios
    Given the "cluster" oauth CRD is restored after scenario

    Given a "htpasswd" file is created with the following lines:
    """
    uiauto1:$apr1$WN1kdHU6$mnkMN9e5CSVnx8w6bpMTB1
    """
    Given I open admin console in a browser
    Given the first user is cluster-admin
    When I run the :goto_cluster_oauth_configuration_page web action
    Then the step should succeed
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I perform the :check_page_contains web action with:
      | content | Identity Providers |
    Then the step should succeed
    """
    When I perform the :add_htpasswd_idp_upload_files web action with:
      | idp_name  | ui-auto-htpasswd               |
      | file_path | <%= expand_path("htpasswd") %> |
    Then the step should succeed
    Given the secret for "ui-auto-htpasswd" htpasswd is stored in the :htpasswd_secret_name clipboard
    Given I register clean-up steps:
    """
    When I run the :delete admin command with:
      | object_type       | secret                                                 |
      | object_name_or_id | <%= o_auth('cluster').htpasswds['ui-auto-htpasswd'] %> |
      | n                 | openshift-config                                       |
    Then the step should succeed
    """

    # make sure authentication pods are recreated with new changes
    Given I wait up to 300 seconds for the steps to pass:
    """
    When I run the :get admin command with:
      | resource      | oauth   |
      | resource_name | cluster |
      | o             | yaml    |
    Then the step should succeed
    And the output should contain "ui-auto-htpasswd"
    Given I use the "openshift-authentication" project
    And 1 pods become ready with labels:
      | app=oauth-openshift |
    Then the expression should be true> cluster_operator("authentication").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("authentication").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("authentication").condition(type: 'Available')['status'] == "True"
    """

    # logout and re-login using specified IDP
    When I run the :click_logout web action
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
    """
    When I open web server via the "<%= browser.base_url %>" url
    When I perform the :login_with_specified_idp web action with:
      | idp_name | ui-auto-htpasswd  |
      | username | uiauto1           |
      | password | redhat            |
    Then the step should succeed
    """
    When I run the :verify_logged_in_admin_console web action
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-24287
  @admin
  Scenario: Let users customize CLI downloads
    Given the master version >= "4.2"

    Given I open admin console in a browser
    When I run the :browse_to_cli_tools_page web action
    Then the step should succeed
    # check_default_oc_download_links is covered by OCP-25802
    When I run the :check_default_odo_download_links web action
    Then the step should succeed

    Given admin ensures "clidownloadtest" console_cli_download_console_openshift_io is deleted after scenario
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/customresource/clidownload.yaml |
    Then the step should succeed
    When I run the :goto_cli_tools_page web action
    Then the step should succeed
    When I run the :check_customized_oc_download_links web action

  # @author xiaocwan@redhat.com
  # @case_id OCP-24316
  @admin
  Scenario: check ConsoleNotification extension CRD
    Given the master version >= "4.2"
    Given I open admin console in a browser
    Given the first user is cluster-admin
    Given admin ensures "notification3" console_notifications_console_openshift_io is deleted after scenario
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/customresource/console-notification.yaml |
    Then the step should succeed

    When I perform the :check_console_notification web action with:
      | name              | notification3   |
      | location          | BannerTopBottom |
      | notification_text | Subscribe       |
      | background        | yellow          |
      | color             | blue            |
      | link_text         | Youtube         |
      | link_url          | https://www.youtube.com |
    Then the step should succeed

    Given I run the :patch admin command with:
      | resource      | consolenotifications |
      | resource_name | notification3        |
      | type          | json                 |
      | p | [{"op": "replace", "path": "/spec/backgroundColor","value":"orange"},{"op": "replace", "path": "/spec/color","value":"navy"},{"op": "replace", "path": "/spec/location","value":"BannerTop"}]|
    Then the step should succeed
    When I perform the :check_console_notification web action with:
      | name              | notification3           |
      | location          | BannerTop               |
      | notification_text | Subscribe               |
      | background        | orange                  |
      | color             | navy                    |
      | link_text         | Youtube                 |
      | link_url          | https://www.youtube.com |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-24016
  @destructive
  @admin
  Scenario: Add custom branding to config map
    Given the master version >= "4.2"
    Given admin ensures "myconfig" configmap is deleted from the "openshift-config" project after scenario
    Given I register clean-up steps:
    """
    When I run the :patch admin command with:
      | resource | console.operator/cluster         |
      | type     | merge                            |
      | p        | {"spec":{"customization": null}} |
    Then the step should succeed
    """
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/customresource/mypic.jpg"
    Then the step should succeed
    When I run the :create_configmap admin command with:
      | name      | myconfig         |
      | from_file | mypic.jpg        |
      | namespace | openshift-config |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "openshift-console" project
    Given evaluation of `deployment("console").annotation("deployment.kubernetes.io/revision", user: admin).to_i` is stored in the :version_before_deploy clipboard
    When I run the :patch admin command with:
      | resource | console.operator/cluster |
      | type     | merge                    |
      | p        | {"spec":{"customization": {"customProductName":"my-custom-name","customLogoFile":{"name":"myconfig","key":"mypic.jpg"}}}} |
    Then the step should succeed

    Given I wait up to 60 seconds for the steps to pass:
    """
    Then the expression should be true> deployment("console").annotation("deployment.kubernetes.io/revision", user: admin, cached: false).to_i > <%= cb.version_before_deploy %>
    """
    Given number of replicas of the current replica set for the "console" deployment becomes:
      | desired  | 2 |
      | current  | 2 |
      | ready    | 2 |

    Given I switch to the first user
    And I open admin console in a browser
    When I perform the :check_header_brand web action with:
      | logo_source  | custom-logo    |
      | product_name | my-custom-name |
    Then the step should succeed

    When I run the :patch admin command with:
      | resource | console.operator/cluster |
      | type     | merge                    |
      | p        | {"spec":{"customization": {"brand":"test"}}} |
    Then the step should fail
    When I run the :patch admin command with:
      | resource | console.operator/cluster |
      | type     | merge                    |
      | p        | {"spec":{"customization": {"customLogoFile":{"name":"myconfig","key":"nonexist.jpg"}}}} |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And current replica set name of "console" deployment stored into :console_rs clipboard
    Given evaluation of `replica_set("<%= cb.console_rs %>").labels(user: admin)["pod-template-hash"]` is stored in the :pod_label clipboard
    Given status becomes :running of 1 pods labeled:
      | pod-template-hash=<%= cb.pod_label %> |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name | pod/<%= pod.name %> |
    Then the step should succeed
    And the output should contain:
      | could not read logo file  |
      | no such file or directory |
    """

  # @author yapei@redhat.com
  # @case_id OCP-25791
  @admin
  Scenario: Project scoped ConsoleLink
    Given the master version >= "4.3"
    Given admin ensures "link-for-some-ns" console_links_console_openshift_io is deleted after scenario
    Given admin ensures "link-for-all-ns" console_links_console_openshift_io is deleted after scenario
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/customresource/namespace-consolelink-1.yaml |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/customresource/namespace-consolelink-2.yaml |
    Then the step should succeed

    Given I open admin console in a browser
    Given the first user is cluster-admin

    # make sure ConsoleLink not targeting any space are shown correctly
    When I perform the :goto_one_project_page web action with:
      | project_name | default |
    Then the step should succeed
    When I perform the :check_external_link web action with:
      | link_text | This appears in all namespaces |
    Then the step should succeed
    When I perform the :check_external_link web action with:
      | link_text | This only appear in some projects |
    Then the step should fail

    # make sure ConsoleLink targetting specific project are shown correctly
    When I perform the :goto_one_project_page web action with:
      | project_name | openshift-console |
    Then the step should succeed
    When I perform the :check_external_link web action with:
      | link_text | This appears in all namespaces |
    Then the step should succeed
    When I perform the :check_external_link web action with:
      | link_text | This only appear in some projects |
    Then the step should succeed

    # make sure namespace overview also have Launcher section
    When I perform the :goto_one_namespace_page web action with:
      | namespace_name | openshift-console |
    Then the step should succeed
    When I perform the :check_external_link web action with:
      | link_text | This appears in all namespaces |
    Then the step should succeed
    When I perform the :check_external_link web action with:
      | link_text | This only appear in some projects |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-25840
  @admin
  Scenario: Add label selector to namespace-scoped ConsoleLink
    Given the master version >= "4.3"
    When I run the :new_project client command with:
      | project_name | uiautotest1 |
    Then the step should succeed
    When I run the :new_project client command with:
      | project_name | uiautotest2 |
    Then the step should succeed
    When I run the :new_project client command with:
      | project_name | uiautotest3 |
    Then the step should succeed

    # create ConsoleLink and clean up steps
    Given admin ensures "exampleone" console_links_console_openshift_io is deleted after scenario
    Given admin ensures "exampletwo" console_links_console_openshift_io is deleted after scenario
    Given admin ensures "examplethree" console_links_console_openshift_io is deleted after scenario
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/customresource/namespace-label-consolelink-1.yaml |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/customresource/namespace-label-consolelink-2.yaml |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/customresource/namespace-label-consolelink-3.yaml |
    Then the step should succeed

    # add label to some projects
    When I run the :label admin command with:
      | resource | namespace   |
      | name     | uiautotest1 |
      | key_val  | test=one    |
    Then the step should succeed
    When I run the :label admin command with:
      | resource | namespace   |
      | name     | uiautotest2 |
      | key_val  | test=two    |
    Then the step should succeed
    When I run the :label admin command with:
      | resource | namespace   |
      | name     | uiautotest2 |
      | key_val  | newtest=two |
    Then the step should succeed

    And I open admin console in a browser

    # matchExpressions and matchLabels
    When I perform the :goto_one_project_page web action with:
      | project_name | uiautotest1 |
    Then the step should succeed
    When I perform the :check_external_link web action with:
      | link_text | Special link one |
    Then the step should succeed
    When I perform the :check_external_link web action with:
      | link_text | Special link two |
    Then the step should succeed
    When I perform the :check_external_link web action with:
      | link_text | Special link three |
    Then the step should fail

    # matchLabels and matchExpressions
    When I perform the :goto_one_project_page web action with:
      | project_name | uiautotest2 |
    Then the step should succeed
    When I perform the :check_external_link web action with:
      | link_text | Special link two |
    Then the step should succeed
    When I perform the :check_external_link web action with:
      | link_text | Special link three |
    Then the step should succeed
    When I perform the :check_external_link web action with:
      | link_text | Special link one |
    Then the step should fail

    # namespaces
    When I perform the :goto_one_project_page web action with:
      | project_name | uiautotest3 |
    Then the step should succeed
    When I perform the :check_external_link web action with:
      | link_text | Special link one |
    Then the step should succeed
    When I perform the :check_external_link web action with:
      | link_text | Special link two |
    Then the step should fail
    When I perform the :check_external_link web action with:
      | link_text | Special link three |
    Then the step should fail

  # @author hasha@redhat.com
  # @case_id OCP-24416
  @admin
  Scenario: Add back pod log link extension
    Given the master version >= "4.2"
    Given I have a project
    Given the first user is cluster-admin
    Given admin ensures "consolelog1" console_external_log_link_console_openshift_io is deleted after scenario
    Given admin ensures "consolelog2" console_external_log_link_console_openshift_io is deleted after scenario
    Given admin ensures "consolelog3" console_external_log_link_console_openshift_io is deleted after scenario
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/customresource/consoleExternalLogLink.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod.json |
      | n | <%= project.name %> |
    Then the step should succeed
    Given I open admin console in a browser
    When I perform the :goto_one_pod_log_page web action with:
      | project_name | <%= project.name %> |
      | pod_name     | hello-openshift     |
    Then the step should succeed
    When I perform the :check_external_log_link web action with:
      | text     | externalloglink1 |
      | link_url | stackoverflow    |
    Then the step should succeed
    When I perform the :check_external_log_link web action with:
      | text     | Example Logs  |
      | link_url | resourceName=hello-openshift&containerName=hello-openshift&resourceNamespace=<%= project.name %>&podLabels={"name":"hello-openshift"} |
    Then the step should succeed
    When I perform the :check_external_log_link web action with:
      | text     | userprojectLogLink3 |
      | link_url | stackoverflow       |
    Then the step should succeed
    When I perform the :goto_one_pod_log_page web action with:
      | project_name | openshift-monitoring |
      | pod_name     | alertmanager-main-0  |
    Then the step should succeed
    When I perform the :check_external_log_link web action with:
      | text     | userprojectLogLink3 |
      | link_url | stackoverflow       |
    Then the step should fail

  # @author hasha@redhat.com
  # @case_id OCP-24286
  @admin
  Scenario: Check ConsoleLink extension CRD	
    Given the master version >= "4.2"
    Given admin ensures "applicationmenu1" console_links_console_openshift_io is deleted after scenario
    Given admin ensures "helpmenu1" console_links_console_openshift_io is deleted after scenario
    Given admin ensures "usermenu1" console_links_console_openshift_io is deleted after scenario
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/customresource/console-link.yaml |
    Then the step should succeed
    Given I open admin console in a browser
    When I perform the :check_consolelink web action with:
      | location | User menu    |
      | text     | usermenutest |
    Then the step should succeed
    When I perform the :check_consolelink web action with:
      | location  | Application launcher      |
      | text      | stackoverflow             |
      | link_url  | https://stackoverflow.com |
      | image_src | stackoverflow/company/img/logos/so/so-logo.svg |
    Then the step should succeed
    When I perform the :check_consolelink web action with:
      | location | Help menu |
      | text     | Baidu     |
    Then the step should succeed
    When I run the :delete admin command with:
      | object_type       | consolelink |
      | object_name_or_id | usermenu1   |
    Then the step should succeed
    When I run the :goto_projects_list_page web action
    Then the step should succeed
    When I perform the :check_consolelink web action with:
      | location | User menu    |
      | text     | usermenutest |
    Then the step should fail

  # @author xiaocwan@redhat.com
  # @case_id OCP-25868
  @admin
  Scenario: Check projectUID in external logging link on pod log tab
    Given the master version >= "4.3"
    Given admin ensures "example" console_external_log_link_console_openshift_io is deleted after scenario
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/customresource/console-external-log-link.yaml |
    Then the step should succeed

    # Given I open admin console in a browser
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/pod_with_two_containers.json |
    Then the step should succeed
    Given I open admin console in a browser
    When I perform the :goto_one_pod_log_page web action with:
      | project_name  | <%= project.name %> |
      | pod_name      | doublecontainers    |
    Then the step should succeed

    # check the first container  
    When I perform the :check_link_and_text web action with:
      | text     | Example Logs                  |
      | link_url | resourceName=doublecontainers |
    Then the step should succeed 
    When I perform the :check_link_and_text web action with:
      | text     | Example Logs                  |
      | link_url | containerName=hello-openshift |
    Then the step should succeed 
    When I perform the :check_link_and_text web action with:
      | text     | Example Logs                  |
      | link_url | resourceNamespace=<%= project.name %> |
    Then the step should succeed  
    When I perform the :check_link_and_text web action with:
      | text     | Example Logs                            |
      | link_url | resourceNamespaceUID=<%= project.uid %> |
    Then the step should succeed 

    # check the second container
    When I perform the :switch_to_other_container web action with:
      | dropdown_item     | hello-openshift-fedora |
    Then the step should succeed 
    When I perform the :check_text_not_a_link web action with:
      | text | hello-openshift-fedora |
    Then the step should succeed    
    When I perform the :check_link_and_text web action with:
      | text     | Example Logs                          |
      | link_url | resourceName=doublecontainers         |
    Then the step should succeed 
    When I perform the :check_link_and_text web action with:
      | text     | Example Logs                          |
      | link_url | containerName=hello-openshift-fedora  |
    Then the step should succeed 
    When I perform the :check_link_and_text web action with:
      | text     | Example Logs                          |
      | link_url | resourceNamespace=<%= project.name %> |
    Then the step should succeed 
    When I perform the :check_link_and_text web action with:
      | text     | Example Logs                            |
      | link_url | resourceNamespaceUID=<%= project.uid %> |
    Then the step should succeed 
    
  # @author yapei@redhat.com
  # @case_id OCP-25817
  @admin
  Scenario: Add support for ConsoleYAMLSample CRD
    Given the master version >= "4.3"

    # create ConsoleYAMLSample instance
    Given admin ensures "example" console_yaml_samples_console_openshift_io is deleted after scenario
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/customresource/console-yaml-sample.yaml |
    Then the step should succeed

    Given the first user is cluster-admin
    And I open admin console in a browser
    
    # check YAML sample when create Jobs
    When I perform the :goto_jobs_page web action with:
      | project_name | default |
    Then the step should succeed
    When I perform the :click_button_text web action with:
      | button_text | Create Job |
    Then the step should succeed
    When I run the :wait_until_no_loading web action
    Then the step should succeed

    # check Schema sidebar
    When I perform the :click_button_text web action with:
      | button_text | Schema |
    Then the step should succeed
    When I perform the :check_sidebar_item web action with:
      | sidebar_item | kind |
    Then the step should succeed
    When I perform the :check_sidebar_item web action with:
      | sidebar_item | metadata |
    Then the step should succeed

    # check Samples sidebar
    When I perform the :click_button_text web action with:
      | button_text | Samples |
    Then the step should succeed
    When I perform the :check_sidebar_item web action with:
      | sidebar_item | example Job YAML sample |
    Then the step should succeed

    # click try it will auto fill the yaml editor
    Given admin ensures "countdown" jobs is deleted from the "default" project after scenario
    When I perform the :click_button_text web action with:
      | button_text | Try it |
    Then the step should succeed
    When I perform the :click_button_text web action with:
      | button_text | Create |
    Then the step should succeed
    And the expression should be true> job('countdown').exists?

    # snippet: true will show Snippets tab
    When I run the :patch admin command with:
      | resource | consoleyamlsample/example    |
      | type     | merge                        |
      | p        | {"spec":{"snippet":true}}    |
    Then the step should succeed
    When I perform the :goto_jobs_page web action with:
      | project_name | default |
    Then the step should succeed
    When I perform the :click_button_text web action with:
      | button_text | Create Job |
    Then the step should succeed
    When I run the :wait_until_no_loading web action
    Then the step should succeed
    When I perform the :click_button_text web action with:
      | button_text | Snippets |
    Then the step should succeed

    # Click 'Show YAML' will display YAML snippet
    When I perform the :click_button_text web action with:
      | button_text | Show YAML |
    Then the step should succeed
    When I perform the :check_content_in_yaml_editor web action with:
      | yaml_content | countdown |
    Then the step should succeed
    When I perform the :click_button_text web action with:
      | button_text | Hide YAML |
    Then the step should succeed
    When I perform the :check_content_in_yaml_editor web action with:
      | yaml_content | countdown |
    Then the step should fail

    # Click 'Insert snippet' will insert code snippet into YAML editor
    When I perform the :click_button_text web action with:
      | button_text | Insert Snippet |
    Then the step should succeed
    When I perform the :check_content_in_yaml_editor web action with:
      | yaml_content | countdown |
    Then the step should succeed
