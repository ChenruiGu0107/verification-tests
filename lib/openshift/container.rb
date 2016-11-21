module CucuShift
  class Container
    attr_reader :default_user

    def initialize(name:, pod:, default_user:)
      @name = name
      @default_user = default_user
      if pod.kind_of? Pod
        @pod = pod
      else
        raise "#{pod} needs to be of type Pod"
      end
    end

    # return @Hash information of container mmeatching the @name variable
    def status(user: nil, cached: true, quiet: false)
      user ||= default_user
      container_statuses = @pod.get_cached_prop(prop: :status, user: user, cached: cached, quiet: quiet)['containerStatuses']
      stat = {}
      container_statuses.each do | cs |
        stat = cs if cs['name'] == @name
      end
      return stat
    end

    # return @Hash information of container spec matching the @name variable
    def spec(user: nil, cached: true, quiet: false)
      user ||= default_user
      container_spec = @pod.get_cached_prop(prop: :containers, user: user, cached: cached, quiet: quiet)
      spec = {}
      container_spec.each do | cs |
        spec = cs if cs['name'] == @name
      end
      return spec
    end

    ## status related information for the container @name
    def id(user: nil, cached: true, quiet: false)
      user ||= default_user
      res = status(user: user, cached: cached, quiet: quiet)
      return res['containerID'].split("docker://").last
    end

    def image(user: nil, cached: true, quiet: false)
      user ||= default_user
      res = status(user: user, cached: cached, quiet: quiet)
      return res['image'].split('@sha256:')[0]
    end

    def image_id(user: nil, cached: true, quiet: false)
      user ||= default_user
      res = status(user: user, cached: cached, quiet: quiet)
      return res['imageID'].split('sha256:').last
    end

    def name(user: nil, cached: true, quiet: false)
      user ||= default_user
      res = status(user: user, cached: cached, quiet: quiet)
      return res['name']
    end

    # returns @Boolean representation of the container state
    def ready?(user: nil, cached: true, quiet: false)
      user ||= default_user
      res = status(user: user, cached: cached, quiet: quiet)
      return res['ready']  # return @status['ready']
    end

    ### TODO: these two methods need to be dynamic, will need to address them later
    # def restart_count
    #   return @api_struct['restartCount']
    # end

    # def state
    #   return @api_struct['state']
    # end

    ## spec related information for the container
    def image_pull_policy(user: nil, cached: true, quiet: false)
      user ||= default_user
      res = spec(user: user, cached: cached, quiet: quiet)
      return res['imagePullPolicy']
    end

    def ports(user: nil, cached: true, quiet: false)
      user ||= default_user
      res = spec(user: user, cached: cached, quiet: quiet)
      return res['ports']
    end

    def resources(user: nil, cached: true, quiet: false)
      user ||= default_user
      res = spec(user: user, cached: cached, quiet: quiet)
      return res['resources']
    end

    # return @Hash representation of scc  for example: {"fsGroup"=>1000400000, "runAsUser"=>1000400000, "seLinuxOptions"=>{"level"=>"s0:c20,c10"}}
    def scc(user: nil, cached: true, quiet: false)
      user ||= default_user
      res = spec(user: user, cached: cached, quiet: quiet)
      return res['securityContext']
    end
  end
end
