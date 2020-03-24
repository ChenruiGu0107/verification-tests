Feature: Prometheus test for Storage
  # @author piqin@redhat.com
  # @case_id OCP-19351
  @admin
  @destructive
  Scenario: Check cinder volume prometheus metric
    Given the master version >= "3.7"

    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :project clipboard
    And metrics service is installed with ansible using:
      | inventory | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/default_inventory_prometheus |

    Given I use the "<%= cb.project %>" project
    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | prometheus-pvc-<%= cb.project %> |
    Then the step should succeed
    And the "prometheus-pvc-<%= cb.project %>" PVC becomes :bound

    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | <%= pvc.name %> |
      | ["metadata"]["name"]                                         | mypod           |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/prometheus |
    Then the step should succeed
    And the pod named "mypod" becomes ready
    When I execute on the pod:
      | touch | /mnt/prometheus/testfile |
    Then the step should succeed

    Given 60 seconds have passed
    And I get the "<%= pod.node_name %>" node's prometheus metrics

    # if we get these metrics, then it was a cinder volume
    When I execute on the "mypod" pod:
      | sh                                                |
      | -c                                                |
      | df -B 1 /mnt/prometheus\|sed 1d\|awk '{print $2}' |
    Then the step should succeed
    And the output should equal "<%= cb.node_metrics.get_one(name: "kubelet_volume_stats_capacity_bytes", labels: "namespace:#{cb.project},persistentvolumeclaim:#{pvc.name}").to_f.to_i %>"

    When I execute on the "mypod" pod:
      | sh                                                |
      | -c                                                |
      | df -B 1 /mnt/prometheus\|sed 1d\|awk '{print $3}' |
    Then the step should succeed
    And the output should equal "<%= cb.node_metrics.get_one(name: "kubelet_volume_stats_used_bytes", labels: "namespace:#{cb.project},persistentvolumeclaim:#{pvc.name}").to_f.to_i %>"

    When I execute on the "mypod" pod:
      | sh                                                |
      | -c                                                |
      | df -B 1 /mnt/prometheus\|sed 1d\|awk '{print $4}' |
    Then the step should succeed
    And the output should equal "<%= cb.node_metrics.get_one(name: "kubelet_volume_stats_available_bytes", labels: "namespace:#{cb.project},persistentvolumeclaim:#{pvc.name}").to_f.to_i %>"

    When I execute on the pod:
      | sh                                              |
      | -c                                              |
      | df -i /mnt/prometheus\|sed 1d\|awk '{print $2}' |
    Then the step should succeed
    And the output should equal "<%= cb.node_metrics.get_one(name: "kubelet_volume_stats_inodes", labels: "namespace:#{cb.project},persistentvolumeclaim:#{pvc.name}").to_i %>"

    When I execute on the pod:
      | sh                                              |
      | -c                                              |
      | df -i /mnt/prometheus\|sed 1d\|awk '{print $3}' |
    Then the step should succeed
    And the output should equal "<%= cb.node_metrics.get_one(name: "kubelet_volume_stats_inodes_used", labels: "namespace:#{cb.project},persistentvolumeclaim:#{pvc.name}").to_i %>"

    When I execute on the pod:
      | sh                                              |
      | -c                                              |
      | df -i /mnt/prometheus\|sed 1d\|awk '{print $4}' |
    Then the step should succeed
    And the output should equal "<%= cb.node_metrics.get_one(name: "kubelet_volume_stats_inodes_free", labels: "namespace:#{cb.project},persistentvolumeclaim:#{pvc.name}").to_i %>"
