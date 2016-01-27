Feature: Testing haproxy router

  # @author zzhao@redhat.com
  # @case_id 512275 
  @admin
  Scenario: HTTP response header should return for default haproxy 503
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    And I execute on the pod:
      | /usr/bin/curl | -v  | 127.0.0.1:80 |
    Then the output should contain "HTTP/1.0 503 Service Unavailable"

  # @author zzhao@redhat.com
  # @case_id 510357
  @admin
  Scenario: Should expose the status monitoring endpoint for haproxy router
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    And I execute on the pod:
      | /usr/bin/curl |  127.0.0.1:1936/healthz |
    Then the output should contain "Service ready"
  
