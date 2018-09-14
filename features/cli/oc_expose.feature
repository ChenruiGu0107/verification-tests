Feature: oc_expose.feature

  # @author cryan@redhat.com
  # @case_id OCP-11898
  Scenario: Expose the second sevice from service
    Given I have a project
    When I run the :new_app client command with:
      | code        | https://github.com/sclorg/s2i-perl-container |
      | l           | app=test-perl                         |
      | context_dir | 5.20/test/sample-test-app/            |
      | name        | myapp                                 |
    Then the step should succeed
    And the "myapp-1" build completed
    When I run the :expose client command with:
      | resource      | service    |
      | resource_name | myapp      |
      | port          | 80         |
      | target_port   | 8080       |
      | name          | myservice  |
      | generator     | service/v1 |
    Then the step should succeed
    When I run the :get client command with:
      | resource | service |
    Then the output should contain "myservice"
    And the output should contain "80/TCP"
    Given I wait for the "myservice" service to become ready up to 300 seconds
    And I get the service pods
    And I wait up to 900 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -s | <%= service.url %> |
    Then the step should succeed
    """
    And the output should contain "Everything is OK"

  # @author akostadi@redhat.com
  # @case_id OCP-11480
  Scenario: Expose services from deploymentconfig
    Given I have a project
    When I run the :new_app client command with:
      | app repo          | <%= product_docker_repo %>openshift3/perl-516-rhel7 |
      | code              | https://github.com/sclorg/s2i-perl-container               |
      | l                 | app=test-perl                                       |
      | context dir       | 5.16/test/sample-test-app/                          |
      | name              | myapp                                               |
      | insecure_registry | true                                                |
    Then the step should succeed
    When I run the :expose client command with:
      | resource      | deploymentconfig |
      | resource name | myapp            |
      | target port   | 8080             |
      | generator     | service/v1       |
      | name          | myservice        |
    Given I wait for the "myservice" service to become ready up to 300 seconds
    And I get the service pods
    When I execute on the pod:
      | curl | -k | <%= service.url %> |
    Then the step should succeed
    And the output should contain "Everything is fine."

  # @author xiuwang@redhat.com
  # @case_id OCP-11121
  Scenario: Expose services from pod
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/perl:5.16                   |
      | code         | https://github.com/sclorg/s2i-perl-container |
      | l            | app=test-perl                         |
      | context dir  | 5.16/test/sample-test-app/            |
      | name         | myapp                                 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deploymentconfig=myapp |
    When I run the :expose client command with:
      | resource      | pod             |
      | resource name | <%= pod.name %> |
      | target port   | 8080            |
      | generator     | service/v1      |
      | name          | myservice       |
    Given I wait for the "myservice" service to become ready up to 300 seconds
    And I get the service pods
    When I execute on the pod:
      | curl | -k | <%= service.url %> |
    Then the step should succeed
    And the output should contain "Everything is fine."

  # @author yadu@redhat.com
  # @case_id OCP-11548
  Scenario: Use service port name as route port.targetPort after 'oc expose service'
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cases/515695/svc_with_name.yaml |
    Then the step should succeed
    When I run the :expose client command with:
      | resource      | svc      |
      | resource name | frontend |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | route                       |
      | resource_name | frontend                    |
      | template      | "{{.spec.port.targetPort}}" |
    Then the step should succeed
    And the output should contain "web"
    When I run the :delete client command with:
      | object_type       | service  |
      | object_name_or_id | frontend |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | route    |
      | object_name_or_id | frontend |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cases/515695/svc_without_name.yaml |
    Then the step should succeed
    When I run the :expose client command with:
      | resource      | svc      |
      | resource name | frontend |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | route                       |
      | resource_name | frontend                    |
      | template      | "{{.spec.port.targetPort}}" |
    Then the step should succeed
    And the output should not contain "web"

  # @author xiuwang@redhat.com
  # @case_id OCP-11721
  Scenario: Expose sevice from replicationcontrollers
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/perl                        |
      | code         | https://github.com/sclorg/s2i-perl-container |
      | context_dir  | 5.20/test/sample-test-app/            |
      | l            | app=test-perl                         |
      | name         | myapp                                 |
    Then the step should succeed
    And the "myapp-1" build completed
    Given I wait for the "myapp" service to become ready up to 300 seconds
    When I run the :expose client command with:
      | resource      | rc         |
      | resource_name | myapp-1    |
      | port          | 80         |
      | target_port   | 8080       |
      | name          | myservice  |
      | generator     | service/v1 |
    Then the step should succeed
    When I run the :get client command with:
      | resource | service |
    Then the output should contain:
      | myservice |
      | 80/TCP    |
    Given I wait for the "myservice" service to become ready up to 300 seconds
    And I get the service pods
    And I wait up to 900 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -s | <%= service.url %> |
    Then the step should succeed
    """
    And the output should contain "Everything is OK"

  # @author pruan@redhat.com
  # @case_id OCP-10873
  Scenario: Access app througth secure service and regenerate service serving certs if it about to expire
    Given the master version >= "3.3"
    Given I have a project
    Given a "caddyfile.conf" file is created with the following lines:
    """
    :8443 {
      tls /etc/serving-cert/tls.crt /etc/serving-cert/tls.key
      root /srv/publics
      browse /test
    }
    :8080 {
      root /srv/public
      browse /test
    }
    """
    When I run the :create_service client command with:
      | createservice_type  | clusterip |
      | name                | hello     |
      | tcp                 | 443:8443  |
    Then the step should succeed
    And I run the :annotate client command with:
      | resource     | svc                                                         |
      | resourcename | hello                                                       |
      | keyval       | service.alpha.openshift.io/serving-cert-secret-name=ssl-key |
    Then the step should succeed
    And I wait for the "ssl-key" secret to appear
    And evaluation of `Time.now` is stored in the :t1 clipboard
    And I run the :create_configmap client command with:
      | name      | default-conf   |
      | from_file | caddyfile.conf |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-10873/dc.yaml |
    Then the step should succeed
    And I wait until the status of deployment "hello" becomes :complete
    Given I have a pod-for-ping in the project
    When I execute on the "hello-pod" pod:
      | curl | --cacert | /var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt | https://hello.<%= project.name %>.svc:443 |
    Then the step should succeed
    And the output should contain:
      | Hello-OpenShift-1 https-8443 |

    # Below checkpoint is in later version
    Given the master version >= "3.5"
    When I run the :extract client command with:
      | resource | secret/ssl-key   |
    Then the step should succeed
    Given evaluation of `File.read("tls.crt")` is stored in the :crt clipboard
    And evaluation of `secret('ssl-key').created` is stored in the :birth clipboard
    And evaluation of `Time.now` is stored in the :t2 clipboard
    And evaluation of `(cb.birth + (cb.t2 - cb.t1) + 3600 + 60).utc.strftime "%Y-%m-%dT%H:%M:%SZ"` is stored in the :newexpiry clipboard
    When I run the :annotate client command with:
      | resource     | secret/ssl-key                                          |
      | keyval       | service.alpha.openshift.io/expiry=<%= cb.newexpiry %>   |
      | overwrite    | true                                                    |
    Then the step should succeed
    Given 30 seconds have passed
    When I run the :extract client command with:
      | resource | secret/ssl-key   |
      | confirm  | true             |
    Then the step should succeed
    # When the expiry time has more than 3600s left, the cert will not regenerate
    And the expression should be true> File.read("tls.crt") == cb.crt
    # When the expiry time has less than 3600s, we could wait the cert to regenerate
    Given I wait up to 1800 seconds for the steps to pass:
    """
    Given 60 seconds have passed
    When I run the :extract client command with:
      | resource | secret/ssl-key   |
      | confirm  | true             |
    Then the step should succeed
    And the expression should be true> File.read("tls.crt") != cb.crt
    """
    When I execute on the "hello-pod" pod:
      | curl | --cacert | /var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt | https://hello.<%= project.name %>.svc:443 |
    Then the step should succeed
    And the output should contain:
      | Hello-OpenShift-1 https-8443 |




