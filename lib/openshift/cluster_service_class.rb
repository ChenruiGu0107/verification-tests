require 'openshift/cluster_resource'

module CucuShift
  # @note represents an OpenShift environment Cluster Service Class
  class ClusterServiceClass < ClusterResource
    RESOURCE = "clusterserviceclasses"
  end
end
