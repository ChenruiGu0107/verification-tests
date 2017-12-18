require 'openshift/cluster_resource'

module CucuShift
  # @note represents an OpenShift environment Cluster Service Broker
  class ClusterServiceBroker < ClusterResource
    RESOURCE = "clusterservicebrokers"
  end
end
