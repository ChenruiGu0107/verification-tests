Feature: Testing kube-controller-manager-operator

  # @author yinzhou@redhat.com
  # @case_id OCP-28001
  @admin
  @destructive
  Scenario: KCM should recover when its temporary secrets are deleted
    Given I switch to cluster admin pseudo user
    Then I run the :delete admin command with:
      | object_type       | secrets                                 |
      | object_name_or_id | csr-signer                              |
      | object_name_or_id | kube-controller-manager-client-cert-key |
      | object_name_or_id | service-account-private-key             |
      | object_name_or_id | serving-cert                            |
      | n                 | openshift-kube-controller-manager       |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :get admin command with:
      | resource      | secrets                                 |
      | resource_name | csr-signer                              |
      | resource_name | kube-controller-manager-client-cert-key |
      | resource_name | service-account-private-key             |
      | resource_name | serving-cert                            |
      | n             | openshift-kube-controller-manager       |
    Then the step should succeed
    """
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-controller-manager").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-controller-manager").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("kube-controller-manager").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-controller-manager").condition(type: 'Available')['status'] == "True"
    """

  # @author yinzhou@redhat.com
  # @case_id OCP-40180
  @admin
  @destructive
  Scenario: Wire cipher config as parameter for kube-controller-manager	
    Given I switch to cluster admin pseudo user
    Given the CR "apiserver" named "cluster" is restored after scenario
    When I run the :describe admin command with:
      | resource      | pods                               |
      | l             | app=kube-controller-manager        |
      | n             | openshift-kube-controller-manager  |
    Then the step should succeed
    Then the output should match 3 times:
      | --tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256 --tls-min-version=VersionTLS12 |
    When I run the :patch admin command with:
      | resource      | apiserver          |
      | resource_name | cluster            |
      | p             | [{"op": "add", "path": "/spec/tlsSecurityProfile", "value":{"custom":{"ciphers":["ECDHE-ECDSA-CHACHA20-POLY1305","ECDHE-RSA-CHACHA20-POLY1305","ECDHE-RSA-AES128-GCM-SHA256","ECDHE-ECDSA-AES128-GCM-SHA256"],"minTLSVersion":"VersionTLS11"},"type":"Custom"}}] |
      | type          | json               |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-controller-manager").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-controller-manager").condition(cached: false, type: 'Progressing')['status'] == "False"
    And  the expression should be true> cluster_operator("kube-controller-manager").condition(type: 'Degraded')['status'] == "False"
    And  the expression should be true> cluster_operator("kube-controller-manager").condition(type: 'Available')['status'] == "True"
    """
    When I run the :describe admin command with:
      | resource      | pods                               |
      | l             | app=kube-controller-manager        |
      | n             | openshift-kube-controller-manager  |
    Then the step should succeed
    Then the output should match 3 times:
      | --tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256 --tls-min-version=VersionTLS11  |
    When I run the :patch admin command with:
      | resource      | apiserver            |
      | resource_name | cluster              |
      | p             | [{"op": "replace", "path": "/spec/tlsSecurityProfile", "value":{"old":{},"type":"Old"}}] |
      | type          | json                 |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-controller-manager").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-controller-manager").condition(cached: false, type: 'Progressing')['status'] == "False"
    And  the expression should be true> cluster_operator("kube-controller-manager").condition(type: 'Degraded')['status'] == "False"
    And  the expression should be true> cluster_operator("kube-controller-manager").condition(type: 'Available')['status'] == "True"
    """
    When I run the :describe admin command with:
      | resource      | pods                               |
      | l             | app=kube-controller-manager        |
      | n             | openshift-kube-controller-manager  |
    Then the step should succeed
    Then the output should match 3 times:
      | --tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,TLS_RSA_WITH_AES_128_GCM_SHA256,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_CBC_SHA256,TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_256_CBC_SHA,TLS_RSA_WITH_3DES_EDE_CBC_SHA --tls-min-version=VersionTLS10  |
