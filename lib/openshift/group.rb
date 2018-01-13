require 'openshift/cluster_resource'

module CucuShift
  # @note represents an OpenShift environment Group
  class Group < ClusterResource
    RESOURCE = 'groups'
  end
end
