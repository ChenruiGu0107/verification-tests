require 'openshift/cluster_resource'

module CucuShift
  # @note represents an OpenShift environment Persistent Volume
  class PersistentVolume < ClusterResource
    STATUSES = [:available, :bound, :pending, :released, :failed]
    RESOURCE = 'persistentvolumes'

    def update_from_api_object(pv_hash)
      m = pv_hash["metadata"]

      unless pv_hash["kind"] == "PersistentVolume"
        raise "hash not from a PV: #{pv_hash["kind"]}"
      end
      unless name == m["name"]
        raise "hash from a different PV: #{name} vs #{m["name"]}"
      end

      props[:uid] = m["uid"]
      props[:spec] = pv_hash["spec"]
      # status should be retrieved on demand but we cache it for the brave
      props[:status] = pv_hash["status"]

      return self # mainly to help ::from_api_object
    end

    # @param from_status [Symbol] the status we currently see
    # @param to_status [Array, Symbol] the status(es) we check whether current
    #   status can change to
    # @return [Boolean] true if it is possible to transition between the
    #   specified statuses (same -> same should return true)
    def status_reachable?(from_status, to_status)
      [to_status].flatten.include?(from_status) ||
        ![:failed].include?(from_status)
    end

    def reclaim_policy(user: nil, cached: true, quiet: false)
      spec = get_cached_prop(prop: :spec, user: user, cached: cached, quiet: quiet)
      return spec['persistentVolumeReclaimPolicy']
    end

    def storage_class_name(user: nil, cached: true, quiet: false)
      spec = get_cached_prop(prop: :spec, user: user, cached: cached, quiet: quiet)
      return spec['storageClassName']
    end
  end
end
