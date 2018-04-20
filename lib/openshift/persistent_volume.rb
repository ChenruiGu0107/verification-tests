require 'openshift/cluster_resource'

module CucuShift
  # @note represents an OpenShift environment Persistent Volume
  class PersistentVolume < ClusterResource
    STATUSES = [:available, :bound, :pending, :released, :failed]
    RESOURCE = 'persistentvolumes'

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
      raw_resource(user: user, cached: cached, quiet: quiet).
        dig("spec", 'persistentVolumeReclaimPolicy')
    end

    def volume_mode(user: nil, cached: true, quiet: false)
      raw_resource(user: user, cached: cached, quiet: quiet).
        dig("spec", 'volumeMode')
    end

    def storage_class_name(user: nil, cached: true, quiet: false)
      raw_resource(user: user, cached: cached, quiet: quiet).
        dig("spec", 'storageClassName')
    end

    def uid(user: nil, cached: true, quiet: false)
      raw_resource(user: user, cached: cached, quiet: quiet).
        dig("metadata", "uid")
    end
  end
end
