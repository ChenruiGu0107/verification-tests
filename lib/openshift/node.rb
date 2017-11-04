require 'openshift/cluster_resource'
require 'openshift/node_taint'

module CucuShift
  # @note this class represents OpenShift environment Node API pbject and this
  #   is different from a CucuShift::Host. Underlying a Node, there always is a
  #   Host but not all Hosts are Nodes. Not sure if we can always have a
  #   mapping between Nodes and Hosts. Depends on access we have to the env
  #   under testing and proper configuration.
  class Node < ClusterResource
    RESOURCE = "nodes"

    def update_from_api_object(node_hash)
      super

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
      return @host if @host

      # try to figure this out from host specification
      potential = env.hosts.select { |h| h.hostname.start_with? self.name }
      if potential.size == 1
        @host = potential.first
        return @host
      end

      # check whether we detect node hostname as local to any hosts
      @host = env.hosts.find do |h|
        h.local_ip?(labels["kubernetes.io/hostname"] || name)
      end
      return @host if @host

      raise("no host mapping for #{self.name}")
    end

    def taints(user: nil, cached: true, quiet: true)
      param = get_cached_prop(prop: :spec, user: user, cached: cached, quiet: quiet)
      return param["taints"]&.map {|t| NodeTaint.new(self, t)} || []
    end

    def service
      @service ||= CucuShift::Platform::NodeService.new(host)
    end

    def schedulable?(user: nil, cached: true, quiet: false)
      spec = get_cached_prop(prop: :spec, user: user, cached: cached, quiet: quiet)
      return !spec['unschedulable']
    end
    # @return [Integer} capacity cpu in 'm'
    def capacity_cpu(user: nil, cached: true, quiet: false)
      obj = get_cached_prop(prop: :raw, user: user, cached: cached, quiet: quiet)
      cpu = obj.dig("status", "capacity", "cpu")
      return unless cpu
      parsed = cpu.match(/\A(\d+)([a-zA-Z]*)\z/)
      number = Integer(parsed[1])
      unit = parsed[2]
      case unit
      when ""
        return number * 1000
      when "m"
        return number
      else
        raise "unknown cpu unit '#{unit}'"
      end
    end

    def capacity_pods(user: nil, cached: true, quiet: false)
      obj = get_cached_prop(prop: :raw, user: user, cached: cached, quiet: quiet)
      return obj.dig("status", "capacity", "pods")&.to_i
    end

    # @return [Integer] memory in bytes
    def capacity_memory(user: nil, cached: true, quiet: false)
      obj = get_cached_prop(prop: :raw, user: user, cached: cached, quiet: quiet)
      mem = obj.dig("status", "capacity", "memory")
      return unless mem
      return convert_to_bytes(mem)
    end

    # @return [Integer} capacity cpu in 'm'
    def allocatable_cpu(user: nil, cached: true, quiet: false)
      obj = get_cached_prop(prop: :raw, user: user, cached: cached, quiet: quiet)
      cpu = obj.dig("status", "allocatable", "cpu")
      return unless cpu
      return convert_cpu(cpu)
    end

    def allocatable_pods(user: nil, cached: true, quiet: false)
      obj = get_cached_prop(prop: :raw, user: user, cached: cached, quiet: quiet)
      return obj.dig("status", "allocatable", "pods")&.to_i
    end

    # @return [Integer] memory in bytes
    def allocatable_memory(user: nil, cached: true, quiet: false)
      obj = get_cached_prop(prop: :raw, user: user, cached: cached, quiet: quiet)
      mem = obj.dig("status", "allocatable", "memory")
      return unless mem
      return convert_to_bytes(mem)
    end
  end
end
