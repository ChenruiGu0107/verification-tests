require 'openshift/cluster_resource'

module CucuShift
  # @note this class represents OpenShift environment Node API pbject and this
  #   is different from a CucuShift::Host. Underlying a Node, there always is a
  #   Host but not all Hosts are Nodes. Not sure if we can always have a
  #   mapping between Nodes and Hosts. Depends on access we have to the env
  #   under testing and proper configuration.
  class Node < ClusterResource
    RESOURCE = "nodes"

    def update_from_api_object(node_hash)
      h = node_hash["metadata"]
      props[:uid] = h["uid"]
      props[:labels] = h["labels"]
      props[:spec] = node_hash["spec"]
      props[:status] = node_hash["status"]
      return self
    end

    # @note assuming admin here should be safe as working with nodes
    #   usually means that we work with admin
    def labels(user: :admin)
      return props[:labels] if props[:labels]
      reload(user: user)
      props[:labels]
    end

    # @return [CucuShift:Host] underlying this node
    # @note may raise depending on proper OPENSHIFT_ENV_<NAME>_HOSTS
    # @note will return acorrding to:
    # 1. if the node name matches hosts, then use host
    # 2. if  any env pre-defined hosts woned node name ip, then use it.
    def host
      host = env.hosts.find { |h| h.hostname == self.name }
      return host if host
      env.hosts.each do | h|
        hname = h.exec("hostname")[:response].gsub("\n","")
        return h if hname == self.name
      end
      raise("no host mapping for #{self.name}")
    end

    def service
      @service ||= CucuShift::Platform::NodeService.new(host)
    end

    def schedulable?(user: nil, cached: true, quiet: false)
      spec = get_cached_prop(prop: :spec, user: user, cached: cached, quiet: quiet)
      return !spec['unschedulable']
    end
  end
end
