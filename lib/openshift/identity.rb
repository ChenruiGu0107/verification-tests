require 'openshift/cluster_resource'

module CucuShift
  # represents an OpenShift Identity
  class Identity < ClusterResource
    RESOURCE = 'identities'
  end
end
