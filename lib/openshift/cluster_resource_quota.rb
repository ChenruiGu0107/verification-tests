require 'openshift/cluster_resource'

module CucuShift
  # @note represents an OpenShift cluster resource quota
  class ClusterResourceQuota < ClusterResource
    RESOURCE = 'clusterresourcequotas'
  end
end
