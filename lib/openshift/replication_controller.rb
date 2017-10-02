require 'openshift/project_resource'
require 'openshift/pod_replicator'
require 'openshift/container_spec'

module CucuShift
  # represents an OpenShift ReplicationController (rc for short) used for scaling pods
  class ReplicationController < PodReplicator
    RESOURCE = "replicationcontrollers"

    # cache some usualy immutable properties for later fast use; do not cache
    #   things that can change at any time like status and spec
    def update_from_api_object(rc_hash)
      super
      m = rc_hash["metadata"]
      s = rc_hash["spec"]
      props[:uid] = m["uid"]
      props[:labels] = m["labels"]
      props[:annotations] = m["annotations"] # may change, use with care
      props[:created] = m["creationTimestamp"] # already [Time]
      props[:spec] = s
      props[:status] = rc_hash["status"] # may change, use with care
      props[:selector] = s["selector"]

      return self # mainly to help ::from_api_object
    end

    # @param from_status [Symbol] the status we currently see
    # @param to_status [Array, Symbol] the status(es) we check whether current
    #   status can change to
    # @return [Boolean] true if it is possible to transition between the
    #   specified statuses (same -> same should return true)
    def status_reachable?(from_status, to_status)
      [to_status].flatten.include?(from_status) ||
        ![:failed, :succeeded].include?(from_status)
    end

    # @param status [Symbol, Array<Symbol>] the expected statuses as a symbol
    # @return [Boolean] if pod status is what's expected
    # def status?(user:, status:, quiet: false, cached: false)
    #   statuses = {
    #     waiting: "Waiting",
    #     running: "Running",
    #     succeeded: "Succeeded",
    #     failed: "Failed",
    #     complete: "Complete",
    #   }
    #   res = describe(user, quiet: quiet)
    #   if res[:success]
    #     pods_status = res[:parsed][:pods_status]
    #     res[:success] = (pods_status[status].to_i != 0)
    #   end
    #   return res
    # end

    def selector(user: nil, cached: true, quiet: false)
      spec = get_cached_prop(prop: :spec, user: user, cached: cached, quiet: quiet)
      return spec["selector"]
    end

    def expected_replicas(user: nil, cached: true, quiet: false)
      spec = get_cached_prop(prop: :spec, user: user, cached: cached, quiet: quiet)
      return spec["replicas"]
    end

    def current_replicas(user: nil, cached: true, quiet: false)
      status = get_cached_prop(prop: :status, user: user, cached: cached, quiet: quiet)
      return status["replicas"]
    end

    ### if we look at the output below, a rc is ready only when the READY column
    # matches the DESIRED column
    # [root@openshift-141 ~]# oc get rc  -n openshift-infra
    # NAME                   DESIRED   CURRENT   READY     AGE
    # hawkular-cassandra-1   1         1         1         4m
    # hawkular-metrics       1         1         0         4m
    # heapster               1         1         0         4m

    # pry(main)> heapster['status']
    # => {"fullyLabeledReplicas"=>1, "observedGeneration"=>1, "readyReplicas"=>1, "replicas"=>1}
    # NOTE, the readyReplicas key is not there if the READY column is 0
    # return: Integer (number of replicas that are in the ready state)
    def ready_replicas(user: nil, cached: true, quiet: false)
      replicas = 0
      user = default_user(user)
      res = raw_resource(user: user, cached: cached, quiet: quiet)
      if env.version_ge("3.4", user: user)
        # use the readyReplicas count
        replicas = res["status"]['readyReplicas'].to_i
      else
        labels = selector(user: user)
        # use cached if applies
        if cached && props[:ready_replicas]
          replicas = props[:ready_replicas]
        else
          pods = Pod.get_matching(user: user, project: project, get_opts: {l: selector_to_label_arr(*labels)}) { |p, p_hash| p.ready?(user: user, cached: true) }
          replicas = props[:ready_replicas] = pods.size
        end
      end
      return replicas
    end

    # @return [CucuShift::ResultHash] with :success depending on
    #   status['replicas'] == spec['replicas']
    # @note we also need to check that the spec.replicas is > 0
    def ready?(user:, quiet: false, cached: false)
      if cached && props[:status] && props[:annotations] && props[:spec]
        cache = {
          "status" => props[:status],
          "spec" => props[:spec],
          "metadata" => {"annotations" => props[:annotations]}
        }

        res = {
          success: true,
          instruction: "get rc #{name} cached ready status",
          response: cache.to_yaml,
          parsed: cache
        }
        current_replicas = props[:status]["replicas"]
        expected_replicas = props[:spec]["replicas"]
        deployment_phase = props[:annotations]["openshift.io/deployment.phase"]
      else
        res = get(user: user, quiet: quiet)
        return res unless res[:success]
        current_replicas = res[:parsed]["status"]["replicas"]
        expected_replicas = res[:parsed]["spec"]["replicas"]
        deployment_phase = res[:parsed].dig('metadata', 'annotations', "openshift.io/deployment.phase")
      end
      res[:success] = expected_replicas.to_i > 0 &&
                     current_replicas == ready_replicas(user: user) &&
                     (deployment_phase == 'Complete' || deployment_phase.nil?)

      return res
    end

    # @return [CucuShift::ResultHash]
    def replica_count_match?(user:, state:, replica_count:, quiet: false)
      res = describe(user, quiet: quiet)
      if res[:success]
        res[:success] = res[:parsed][:pods_status][state].to_i == replica_count
      end
      return res
    end

    # @return [CucuShift::ResultHash] with :success true if we've eventually
    #   get the number of reclicas 'running' to match the desired number
    def wait_till_replica_count_match(user:, state:, seconds:, replica_count:)
      res = nil
      iterations = 0
      start_time = monotonic_seconds

      success = wait_for(seconds) {
        res = replica_count_match?(user: user, state: state, replica_count: replica_count, quiet: true)

        logger.info res[:command] if iterations == 0
        iterations = iterations + 1

        res[:success]
      }

      duration = monotonic_seconds - start_time
      logger.info "After #{iterations} iterations and #{duration.to_i} " <<
        "seconds:\n#{res[:response]}"

      return res
    end
  end
end
