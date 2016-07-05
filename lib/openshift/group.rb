require 'openshift/cluster_resource'

module CucuShift
  # @note represents an OpenShift environment Group
  class Group < ClusterResource
    RESOURCE = 'groups'

    def update_from_api_object(group_hash)
      # m = pv_hash["metadata"]

      # unless pv_hash["kind"] == "PersistentVolume"
      #   raise "hash not from a PV: #{pv_hash["kind"]}"
      # end
      # unless name == m["name"]
      #   raise "hash from a different PV: #{name} vs #{m["name"]}"
      # end

      # props[:uid] = m["uid"]
      # props[:spec] = pv_hash["spec"]
      # status should be retrieved on demand but we cache it for the brave
      # props[:status] = pv_hash["status"]

      return self # mainly to help ::from_api_object
    end
  end
end
