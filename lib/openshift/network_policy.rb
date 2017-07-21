require 'openshift/cluster_resource'

module CucuShift
  # @note represents an OpenShift environment Network Policy
  class NetworkPolicy < ClusterResource
    RESOURCE = 'networkpolicies'
  end
end
