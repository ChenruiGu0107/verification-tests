Feature: test container related support
  Scenario: container support
    Given I have a project
    And I have a pod-for-ping in the project
    And evaluation of `rand project.uid_range(user:user)` is stored in the :scc_uid clipboard
    And evaluation of `project.uid_range(user:user).begin` is stored in the :proj_scc_uid clipboard
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/tc511602/pod1.json
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :running
    And evaluation of `pod.containers(user: user, cached: true)` is stored in the :containers clipboard
    And evaluation of `pod('hello-openshift').container(user: user, name: 'hello-openshift', cached: true).scc` is stored in the :c1 clipboard
    And evaluation of `pod('hello-openshift').container(user: user, name: 'hello-openshift', cached: true).id` is stored in the :c1_id clipboard
    And evaluation of `pod('hello-openshift').container(user: user, name: 'hello-openshift', cached: true).resources` is stored in the :c2 clipboard
    And evaluation of `pod('hello-openshift').container(user: user, name: 'hello-openshift', cached: true).ports` is stored in the :c3 clipboard
    And evaluation of `pod('hello-openshift').container(user: user, name: 'hello-openshift', cached: true).image_pull_policy` is stored in the :c4 clipboard

    And evaluation of `pod('hello-pod').container(user: user, name: 'hello-pod', cached: true).scc` is stored in the :c5 clipboard
