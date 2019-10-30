Feature: console-operator related

  # @author hasha@redhat.com
  # @case_id OCP-22343
  @admin
  Scenario: console operator and console deployment have resource limits	
    Given the master version >= "4.1"
    Given the first user is cluster-admin
    Given I use the "openshift-console" project
    Given 2 pods become ready with labels:
      | app=console  |
      | component=ui |
    Then the expression should be true> pod.containers.first.spec.cpu_request_raw == '10m' and pod.containers.first.spec.memory_request_raw == '100Mi'
    Given 2 pods become ready with labels:
      | app=console         |
      | component=downloads |
    Then the expression should be true> pod.containers.first.spec.cpu_request_raw == '10m' and pod.containers.first.spec.memory_request_raw == '50Mi'
    Given I use the "openshift-console-operator" project
    Given a pod becomes ready with labels:
      | name=console-operator |
    Then the expression should be true> pod.containers.first.spec.cpu_request_raw == '10m' and pod.containers.first.spec.memory_request_raw == '100Mi'
 
