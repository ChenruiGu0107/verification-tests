require 'openshift/cluster_resource'

module CucuShift
  # @note represents an OpenShift environment Cluster Service Plan
  class ClusterServicePlan < ClusterResource
    RESOURCE = "clusterserviceplans"
  end
end
