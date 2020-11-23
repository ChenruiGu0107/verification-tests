Feature: reports related scenarios
  # @author pruan@redhat.com
  # @case_id OCP-20900
  @admin
  @destructive
  Scenario: view metering report with supported formats
    Given metering service has been installed successfully
    And I use the "<%= cb.metering_namespace.name %>" project
    Given I get the "cluster-cpu-capacity" report and store it in the :res_json clipboard using:
      | query_type          | cluster-cpu-capacity |
    Then the step should succeed
    Given I get the "cluster-cpu-capacity" report and store it in the :res_csv clipboard using:
      | query_type          | cluster-cpu-capacity |
      | use_existing_report | true                 |
      | format              | csv                  |
    Then the step should succeed
    Given I get the "cluster-cpu-capacity" report and store it in the :res_tabular clipboard using:
      | query_type          | cluster-cpu-capacity |
      | use_existing_report | true                 |
      | format              | tabular              |
    Then the step should succeed
    # save the last element of the timestamp which should appear in all three formats
    And evaluation of `cb.res_json['results'].last['values'].first['value']` is stored in the :timestamp clipboard
    And the expression should be true> cb.res_tabular.include? cb.timestamp
    And the expression should be true> cb.res_csv.include? cb.timestamp

  # @author pruan@redhat.com
  # @case_id OCP-20951
  @admin
  @destructive
  Scenario: verify PV ReportGenerationQuery are supported and be able to generate a report
    Given metering service has been installed successfully
    And I use the "<%= cb.metering_namespace.name %>" project
    Given I get the "persistentvolumeclaim-usage" report and store it in the :res_json clipboard using:
      | query_type | persistentvolumeclaim-usage |
    Then the step should succeed
    And the expression should be true> (report_query('persistentvolumeclaim-usage').column_names - cb.res_json['results'].first['values'].map {|e| e['name']}).empty?


  # @author pruan@redhat.com
  # @case_id OCP-24821
  @admin
  @destructive
  Scenario: Verify 'columns' in results.values have consistent ordering
    Given metering service has been installed successfully
    And I use the "<%= cb.metering_namespace.name %>" project
    Given I select a random node's host
    Given I get the "cluster-cpu-capacity" report and store it in the :res_json clipboard using:
      | query_type | cluster-cpu-capacity |
    # save the expected names into an array
    And evaluation of `cb.res_json['results'].first['values'].map { |h| h['name'] }` is stored in the :golden_list clipboard
    # compare element by element between the two arrays and return those that don't match (should be 0)
    Then the expression should be true> cb.res_json['results'].all? { |r| r['values'].map{ |h| h['name'] } == cb.golden_list }

  # @author pruan@redhat.com
  # @case_id OCP-24001
  @admin
  @destructive
  Scenario: test each valid reportdatasource can produce a report
    Given metering service has been installed successfully
    And I use the "<%= cb.metering_namespace.name %>" project
    Given all reports can be generated via reportquery

  @admin
  @destructive
  # @author pruan@redhat.com
  # @case_id OCP-24176
  Scenario: S3 storage is the default for AWS environments
    # cluster and storage has to be the same vendor
    Given the expression should be true> infrastructure('cluster').platform == "AWS"
    Given I switch to cluster admin pseudo user
    Given admin obtains the cloudcredentials from cluster and store them to the clipboard
    Given I remove metering service from the "openshift-metering" project
    And I setup a metering project
    And I use the "openshift-metering" project
    And I run oc create as admin over ERB test file: metering/secrets/s3.yaml
    Given I install metering service using:
      | meteringconfig | metering/configs/meteringconfig_s3_storage.yaml |

  @admin
  @destructive
  # @author pruan@redhat.com
  # @case_id OCP-35941
  Scenario: verify expiration field for Metering Report
    Given metering service has been installed successfully
    Given I use the "openshift-metering" project
    Then I generate a metering report with:
      | metadata_name | report-ocp-35941         |
      | query_type    | namespace-memory-request |
      | expiration    | 2m                       |
    # wait for the expiration time to pass
    And 120 seconds have passed
    # check the report is still there
    And the expression should be true> report('report-ocp-35941').exists? and (report('report-ocp-35941').age > 120)
    # report does not get purge immediately, keep looping until timeout
    And I wait for the resource "report" named "report-ocp-35941" to disappear within 600 seconds

  @admin
  @destructive
  # @author pruan@redhat.com
  # @case_id OCP-20948
  Scenario: querying for report using external access to Metering HTTP API
    Given metering service has been installed successfully
    And I use the "openshift-metering" project
    Given I get the "cluster-cpu-capacity" report and store it in the :res_json clipboard using:
      | query_type | cluster-cpu-capacity |
    # if we get something back, then that means the external route is working.
    Then the expression should be true> !cb.res_json.nil?

