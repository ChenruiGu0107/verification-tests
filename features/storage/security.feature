Feature: storage security check
  # @author chaoyang@redhat.com
  # @case_id 510760
  @admin @destructive
  Scenario: secret volume security check
    Given I have a project
    Given scc policy "restricted" is restored after scenario
    When I run the :create client command with:
    |filename| https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/secret/secret.yaml|
    Then the step should succeed
    
    #create a new scc restricted 
    When I run the :delete admin command with:
    |object_type| scc|
    |object_name_or_id|restricted|
    Then the step should succeed
    Then the outputs should contain "restricted"
    Then the outputs should contain "deleted"

    When I run the :create admin command with:
    |filename|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/tc510760/secret_restricted.yaml |
    Then the step should succeed
    
    When I run the :create client command with:
    |filename|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/secret/secret-pod-test.json|
    And the pod named "secretpd" becomes ready
    When I execute on the pod:
    |id|
    Then the step should succeed
    Then the outputs should contain "groups=123456"
    When I execute on the pod:
    |ls|
    |-lZd|
    |/mnt/secret/|
    Then the step should succeed
    And the outputs should contain "123456"
    And the outputs should contain "system_u:object_r:svirt_sandbox_file_t:s0"
    When I execute on the pod:
    |touch|
    |/mnt/secret/file |
    Then the step should succeed
    When I execute on the pod:
    |ls|
    |-lZ|
    |/mnt/secret/|
    Then the step should succeed
    And the outputs should not contain "root"
    And the outputs should contain "123456"
    And the outputs should contain "system_u:object_r:svirt_sandbox_file_t:s0"
    And the outputs should contain "file"

  # @author chaoyang@redhat.com
  # @case_id 510759
  @admin @destructive
  Scenario: GitRepo volume security check
    Given I have a project
    Given scc policy "restricted" is restored after scenario

    #create a new scc restricted 
    When I run the :delete admin command with:
    |object_type| scc|
    |object_name_or_id|restricted|
    Then the step should succeed
    Then the outputs should contain "restricted"
    Then the outputs should contain "deleted"
    
    When I run the :create admin command with:
    |filename|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/tc510759/gitRepo_restricted.yaml|
    Then the step should succeed
    
    When I run the :create client command with:
    |filename|https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gitrepo/gitrepo-selinux-fsgroup-auto510759.json |
    Then the step should succeed
    And the pod named "gitrepo" becomes ready
    When I execute on the pod:
    |id|
    Then the step should succeed
    Then the outputs should contain "groups=123456"
    When I execute on the pod:
    |id|
    Then the step should succeed
    Then the outputs should contain "uid=1000130000"
    Then the outputs should contain "groups=123456"

    When I execute on the pod:
    |ls|
    |-lZd|
    |/mnt/git|
    Then the step should succeed
    And the outputs should contain "root 123456"
    And the outputs should contain "system_u:object_r:svirt_sandbox_file_t:s0"
    
    When I execute on the pod:
    |touch|
    |/mnt/git/gitrepoVolume/file1|
    Then the step should succeed
   
    When I execute on the pod:
    |ls |
    |-lZ|
    |/mnt/git/gitrepoVolume/file1|
    Then the step should succeed
    Then the outputs should contain "1000130000 123456"
    Then the outputs should contain "system_u:object_r:svirt_sandbox_file_t:s0"
    Then the outputs should contain "file1"
    
  
