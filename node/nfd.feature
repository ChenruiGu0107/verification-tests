Feature: NFD related scenarios
  # @author pruan@redhat.com
  # @case_id OCP-25335
  @admin
  @destructive
  Scenario: Deploy Node Feature Discovery (NFD) operator from OperatorHub
    Given the nfd-operator is installed using OLM GUI

  # @author pruan@redhat.com
  # @case_id OCP-40907
  @admin
  @destructive
  Scenario: Deploy Node Feature Discovery (NFD) operator from OperatorHub using YAML files
    Given the nfd-operator is installed using OLM CLI
