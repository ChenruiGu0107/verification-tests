require 'ostruct'
require 'common'
require 'collections'

require 'openshift/project'
require 'openshift/group'
require 'openshift/job'
require 'openshift/image_stream'
require 'openshift/imagestreamtag'
require 'openshift/service'
require 'openshift/service_account'
require 'openshift/route'
require 'openshift/build'
require 'openshift/pod'
require 'openshift/persistent_volume'
require 'openshift/persistent_volume_claim'
require 'openshift/replication_controller'
require 'openshift/deployment_config'
require 'openshift/replicaset'
require 'openshift/deployment'
require 'openshift/cluster_role'
require 'openshift/cluster_role_binding'
require 'openshift/storage_class'
require 'openshift/host_subnet'
require 'openshift/cluster_resource_quota'
module CucuShift
  # @note this is our default cucumber World extension implementation
  class DefaultWorld
    include CollectionsIncl
    include Common::Helper
    include Common::Hacks

    attr_accessor :scenario

    def initialize
      # we want to keep a reference to current World in the manager
      # hopefully cucumber does not instantiate us too early
      manager.world = self

      @clipboard = OpenStruct.new
      @browsers = []
      @bg_processes = []
      @bg_rulesresults = []
      # some arrays to store cached objects
      @projects = []
      @services = []
      @service_accounts = []
      @routes = []
      @builds = []
      @pods = []
      @hostsubnets = []
      @clusterresourcequotas = []
      @storageclasses = []
      @pvs = []
      @pvcs = []
      @rcs = []
      @dcs = []
      @deployments = []
      @image_streams = []
      @image_stream_tags = []
      @rss = []  # replicasets
      # used to store host the user wants to run commands on
      @host = nil
      # used to store nodes in the cluster
      @nodes = []
      # procs and lambdas to call on clean-up
      @teardown = []
    end

    # shorthand accessor for @clipboard
    def cb
      return @clipboard
    end

    def setup_logger
      CucuShift::Logger.runtime = @__cucumber_runtime
    end

    def debug_in_after_hook?
      scenario.failed? && conf[:debug_in_after_hook] || conf[:debug_in_after_hook_always]
    end

    def debug_in_after_hook
      if debug_in_after_hook?
        require 'pry'
        binding.pry
        fix_require_lock # see method in Common::Hacks
      end
    end

    def scenario_tags
      scenario.source_tag_names
    end

    def tagged_admin?
      scenario_tags.include? '@admin'
    end

    def tagged_destructive?
      scenario_tags.include? '@destructive'
    end

    def ensure_admin_tagged
      raise 'tag scenario @admin as you use admin access' unless tagged_admin?
    end

    def ensure_destructive_tagged
      raise 'tag scenario @admin and @destructive as you use admin access and failure to restore can have adverse effects to following scenarios' unless tagged_admin? && tagged_destructive?
    end

    # prepares environments' user managers based on @users tag
    # @return [Object] undefined
    # @note tags might not be present for each env thus #prepare might not be
    #   called on each user manager; this is ok because `#prepare(nil)` over
    #   a *clean* user manager should not affect its (in)ability to work
    def prepare_scenario_users
      scenario_tags.select{|t| t.start_with? "@users"}.each do |userstag|
        tagname, tagvalue = userstag.split("=", 2)
        unless tagvalue && !tagvalue.empty?
          raise "users tag value should not be nil or empty"
        end

        garbage, env_name = tagname.split(":", 2)
        env_name ||= conf[:default_environment]
        manager.environments[env_name].user_manager.prepare(tagvalue)
      end
    end

    # @note call like `user(0)` or simply `user` for current user
    def user(num=nil, switch: true)
      return @user if num.nil? && @user
      num = 0 unless num
      @user = env.users[num] if switch
      return env.users[num]
    end

    def service_account(name=nil, project: nil, project_name: nil, switch: true)
      return @service_accounts.last if name.nil? && !@service_accounts.empty?

      if project && project_name && project.name != project_name
        raise "project names inconsistent: #{project.name} vs #{project_name}"
      end
      project ||= self.project(project_name, generate: false)

      if name.nil?
        raise "requesting service account for the first time with no name"
      end

      sa = @service_accounts.find { |s|
        [ s.name, s.shortname ].include?(name) &&
        s.project == project
      }
      unless sa
        sa = ServiceAccount.new(name: name, project: project)
        @service_accounts << sa
      end
      @service_accounts << @service_accounts.delete(sa) if switch
      return sa
    end

    # @note call like `env(:key)` or simply `env` for current environment
    def env(key=nil)
      return @env if key.nil? && @env
      key ||= conf[:default_environment]
      raise "please specify default environment key in config or CUCUSHIFT_DEFAULT_ENVIRONMENT env variable" unless key
      return @env = manager.environments[key]
    end

    def admin
      env.admin
    end

    def host
      return @host
    end

    # @return project from cached projects for this scenario
    #   note that you need to have default `#env` set already;
    #   if no name is spefified, returns the last requested project;
    #   otherwise a CucuShift::Project object is created (but not created in
    #   the actual OpenShift environment)
    def project(name = nil, env: nil, generate: true, switch: true)
      env ||= self.env
      if name.kind_of? Integer
        p = @projects[name]
        raise "no project cached with index #{name}" unless p
        @projects << @projects.delete(p) if switch
        return p
      elsif name
        p = @projects.find {|p| p.name == name && p.env == env}
        if p && @projects.last.equal?(p)
          return p
        elsif p
          # put requested project at top of the stack
          @projects << @projects.delete(p) if switch
          return p
        else
          @projects << Project.new(name: name, env: env)
          return @projects.last
        end
      elsif @projects.empty?
        if generate
          @projects << Project.new(name: rand_str(5, :dns), env: env)
          return @projects.last
        else
          raise "no projects in cache"
        end
      else
        return @projects.last
      end
    end

    # @return service by name from scenario cache; with no params given,
    #   returns last requested service; otherwise creates a service object
    # @note you need the project already created
    def service(name = nil, project = nil)
      project ||= self.project

      if name
        s = @services.find {|s| s.name == name && s.project == project}
        if s && @services.last == s
          return s
        elsif s
          @services << @services.delete(s)
          return s
        else
          # create new CucuShift::Service object with specified name
          @services << Service.new(name: name, project: project)
          return @services.last
        end
      elsif @services.empty?
        # we do not create a random service like with projects because that
        #   would rarely make sense
        raise "what service are you talking about?"
      else
        return @services.last
      end
    end

    # @return PV by name from scenario cache; with no params given,
    #   returns last requested PV; otherwise creates a PV object
    def pv(name = nil, env = nil, switch: true)
      env ||= self.env

      if name
        pv = @pvs.find {|pv| pv.name == name && pv.env == env}
        if pv && @pvs.last == pv
          return pv
        elsif pv
          @pvs << @pvs.delete(pv) if switch
          return pv
        else
          # create new CucuShift::PV object with specified name
          @pvs << PersistentVolume.new(name: name, env: env)
          return @pvs.last
        end
      elsif @pvs.empty?
        # we do not create a random PV like with projects because that
        #   would rarely make sense
        raise "what PersistentVolume are you talking about?"
      else
        return @pvs.last
      end
    end

    def route(name = nil, service = nil)
      service ||= self.service

      if name
        r = @routes.find {|r| r.name == name && r.service == service}
        if r && @routes.last == r
          return r
        elsif r
          @routes << @routes.delete(r)
          return r
        else
          # create new CucuShift::Route object with specified name
          @routes << CucuShift::Route.new(name: name, service: service)
          return @routes.last
        end
      elsif @routes.empty?
        # we do not create a random route like with projects because that
        #   would rarely make sense
        raise "what route are you talking about?"
      else
        return @routes.last
      end
    end

    # @return build by name from scenario cache; with no params given,
    #   returns last requested build; otherwise creates a [Build] object
    # @note you need the project already created
    def build(name = nil, project = nil)
      project ||= self.project(generate: false)

      if name
        b = @builds.find {|b| b.name == name && b.project == project}
        if b && @builds.last == b
          return b
        elsif b
          @builds << @builds.delete(b)
          return b
        else
          # create new CucuShift::Build object with specified name
          @builds << Build.new(name: name, project: project)
          return @builds.last
        end
      elsif @builds.empty?
        # we do not create a random build like with projects because that
        #   would rarely make sense
        raise "what build are you talking about?"
      else
        return @builds.last
      end
    end

    # @return rc (ReplicationController) by name from scenario cache;
    #   with no params given, returns last requested rc;
    #   otherwise creates a [ReplicationController] object
    # @note you need the project already created
    def rc(name = nil, project = nil)
      project ||= self.project(generate: false)

      if name
        r = @rcs.find {|r| r.name == name && r.project == project}
        if r && @rcs.last == r
          return r
        elsif r
          @rcs << @rcs.delete(r)
          return r
        else
          # create new CucuShift::ReplicationControler object with specified name
          @rcs << ReplicationController.new(name: name, project: project)
          return @rcs.last
        end
      elsif @rcs.empty?
        # we do not create a random build like with projects because that
        #   would rarely make sense
        raise "what rc are you talking about?"
      else
        return @rcs.last
      end
    end

    # @return rs (ReplicaSets) by name from scenario cache;
    #   with no params given, returns last requested rs;
    #   otherwise creates a [ReplicaSet] object
    # @note you need the project already created
    def rs(name = nil, project = nil)
      project_resource(ReplicaSet, name, project)
    end

    # @return dc (DeploymentConfig) by name from scenario cache;
    #   with no params given, returns last requested dc;
    #   otherwise creates a [DeploymentConfig] object
    # @note you need the project already created
    def dc(name = nil, project = nil)
      project_resource(DeploymentConfig, name, project)
    end

    # @return Deployment by name from scenario cache;
    #   with no params given, returns last requested deployment;
    #   otherwise creates a [Deployment] object
    # @note you need the project already created
    def deployment(name = nil, project = nil)
      project_resource(Deployment, name, project)
    end

    # @return [ImageStream] is by name from scenario cache; with no params given,
    #   returns last requested is; otherwise creates an [ImageStream] object
    # @note you need the project already created
    def image_stream(name = nil, project = nil)
      project ||= self.project(generate: false)

      if name
        is = @image_streams.find {|s| s.name == name && s.project == project}
        if is && @image_streams.last == is
          return is
        elsif is
          @image_streams << @image_streams.delete(is)
          return is
        else
          # create new CucuShift::ImageStream object with specified name
          @image_streams << ImageStream.new(name: name, project: project)
          return @image_streams.last
        end
      elsif @image_streams.empty?
        # we do not create a random is like with projects because that
        #   would rarely make sense
        raise "what is are you talking about?"
      else
        return @image_streams.last
      end
    end

    def image_stream_tag(name = nil, project = nil)
      project_resource(ImageStreamTag, name, project)
    end

    # @return [PersistentVolumeClaim] last used PVC from scenario cache;
    #   with no params given, returns last requested is;
    #   otherwise creates an [PersistentVolumeClaim] object with the given name
    # @note you need the project already created
    def pvc(name = nil, project = nil)
      project ||= self.project(generate: false)

      if name
        pvc = @pvcs.find {|s| s.name == name && s.project == project}
        if pvc && @pvcs.last == pvc
          return pvc
        elsif pvc
          @pvcs << @pvcs.delete(pvc)
          return pvc
        else
          # create new object with specified name
          @pvcs << PersistentVolumeClaim.new(name: name, project: project)
          return @pvcs.last
        end
      elsif @pvcs.empty?
        # we do not create a random pvc like with projects because that
        #   would rarely make sense
        raise "what PVC are you talking about?"
      else
        return @pvcs.last
      end
    end

    # @return web4cucumber object from scenario cache
    def browser(num = -1)
      num = Integer(num) rescue word_to_num(num)

      raise "no web browsers cached in World" if @browsers.empty?

      case
      when num > @browsers.size + 1 || num < -@browsers.size
        raise "web browsers index not found: #{num} for size #{@browsers.size}"
      else
        cache_browser(@browsers[num]) unless num == -1
        return @browsers.last
      end
    end

    # put the specified browser at top of our cache avoiding duplicates
    def cache_browser(browser)
      @browsers.delete(browser)
      @browsers << browser
    end

    def pod(name = nil, project = nil)
      project_resource(Pod, name, project)
    end

    def job(name = nil, project = nil)
      project_resource(Job, name, project)
    end

    # @param clazz [Class] class of project resource
    # @param name [String, Integer] string name or integer index in cache
    # @return [ProjectResource] by name from scenario cache or creates a new
    #   object with the given name; with no params given, returns last
    #   requested project resource of the clazz type; otherwise raises
    # @note you need the project already created
    def project_resource(clazz, name = nil, project = nil)
      project ||= self.project

      varname = "@#{clazz::RESOURCE}"
      clazzname = clazz.shortclass
      var = instance_variable_get(varname) ||
              instance_variable_set(varname, [])

      if Integer === name
        # using integer index does not trigger reorder of list
        return var[name] || raise("no #{clazzname} with index #{name}")
      elsif name
        # using a string name, moves found resource to top of the list
        r = var.find {|r| r.name == name && r.project == project}
        if r && var.last == r
          return r
        elsif r
          var << var.delete(r)
          return r
        else
          # create new CucuShift::ProjectResource object with specified name
          var << clazz.new(name: name, project: project)
          return var.last
        end
      elsif var.empty?
        # do not create random project resource like with projects because that
        #   would rarely make sense
        raise "what #{clazzname} are you talking about?"
      else
        return var.last
      end
    end

    # @param clazz [Class] class of cluster resource
    # @param name [String, Integer] string name or integer index in cache
    # @return [ClusterResource] by name from scenario cache or creates a new
    #   object with the given name; with no params given, returns last
    #   requested cluster resource of the clazz type; otherwise raises
    def cluster_resource(clazz, name = nil, env = nil, switch: nil)
      env ||= self.env

      varname = "@#{clazz::RESOURCE}"
      clazzname = clazz.shortclass
      var = instance_variable_get(varname) ||
              instance_variable_set(varname, [])

      if Integer === name
        # using integer index does not trigger reorder of list
        return var[name] || raise("no #{clazzname} with index #{name}")
      elsif name
        switch = true if switch.nil?
        r = var.find {|r| r.name == name && r.env == env}
        if r
          var << var.delete(r) if switch
          return r
        else
          # create new CucuShift::ClusterResource object with specified name
          var << clazz.new(name: name, env: env)
          return var.last
        end
      elsif var.empty?
        # we do not create a random PV like with projects because that
        #   would rarely make sense
        raise "what #{clazzname} are you talking about?"
      else
        return var.last
      end
    end

    def cluster_role(name = nil, env = nil)
      cluster_resource(ClusterRole, name, env)
    end

    def cluster_role_binding(name = nil, env = nil)
      cluster_resource(ClusterRoleBinding, name, env)
    end

    def host_subnet(name = nil, env = nil)
      cluster_resource(HostSubnet, name, env)
    end

    def cluster_resource_quota(name = nil, env = nil)
      cluster_resource(ClusterResourceQuota, name, env)
    end

    def storage_class(name = nil, env = nil)
      cluster_resource(StorageClass, name, env)
    end

    # add pods to list avoiding duplicates
    def cache_pods(*new_pods)
      new_pods.each {|p| @pods.delete(p); @pods << p}
    end

    # @return node by name
    def node(name = nil)
      if Integer === name
        return @nodes[name] || raise("no node with index #{name}")
      elsif name
        n = @nodes.find {|n| n.name == name }
        if n && @nodes.last == n
          return n
        elsif n
          @nodes << @nodes.delete(n)
          return n
        else
          # create new CucuShift::Node object with specified name
          @nodes << Node.new(name: name, env: env)
          return @nodes.last
        end
      elsif @nodes.empty?
        # we do not create a random node like with projects because that
        #   would rarely make sense
        raise "what node are you talking about?"
      else
        return @nodes.last
      end
    end

    # tries to create resource off string name and type as used in REST API
    # e.g. resource("hello-openshift", "pod")
    def resource(name, type, project_name: nil)
      shorthands = {
        is: "imagestreams",
        dc: "deploymentconfigs",
        rc: "replicationcontrollers",
        pv: "persistentvolumes",
        svc: "service",
        pvc: "persistentvolumeclaims",
        cluster_role: "clusterroles",
        cluster_role_binding: "clusterrolebindings",
        host_subnet: "hostsubnets",
        cluster_resource_quota: "clusterresourcequotas",
        storage_class: "storageclasses"
      }
      type = shorthands[type.to_sym] if shorthands[type.to_sym]

      classes = ObjectSpace.each_object(CucuShift::Resource.singleton_class)
      clazz = classes.find do |c|
        defined?(c::RESOURCE) && [type, type + "s"].include?(c::RESOURCE)
      end
      raise "cannot find class for type #{type}" unless clazz

      subclass_of = proc {|parent, child| parent >= child}
      return case clazz
      when subclass_of.curry[ProjectResource]
        clazz.new(name: name, project: project(project_name))
      when subclass_of.curry[ClusterResource]
        clazz.new(name: name, env: env)
      else
        raise "unhandled class #{clazz}"
      end
    end

    # @param procs [Proc] a proc or lambda to add to teardown
    # @yield [] a block that will be added to teardown
    # @note teardowns should ever raise only if issue can break further
    #   scenario execution. When a teardown raises, that causes cucumber to
    #   skip executing any further scenarios.
    def teardown_add(*procs, &block)
      @teardown.concat procs
      if block
        @teardown << block
      end
    end

    def quit_cucumber
      Cucumber.wants_to_quit = true
    end

    def after_scenario
      # call all teardown lambdas and procs; see [#teardown_add]
      # run last registered teardown routines first
      @teardown.reverse_each { |f| f.call }
    end

    def hook_error!(err)
      if err
        quit_cucumber
        raise err
      end
    end

    # @return the desired base docker image tag prefix based on
    #   PRODUCT_DOCKER_REPO env variable
    def product_docker_repo(environment = env)
      if ENV["PRODUCT_DOCKER_REPO"] &&
          !ENV["PRODUCT_DOCKER_REPO"].empty?
        ENV["PRODUCT_DOCKER_REPO"]
      elsif conf[:product_docker_repo]
        conf[:product_docker_repo]
      else
        environment.system_docker_repo
      end
    end

    def project_docker_repo
      conf[:project_docker_repo]
    end

    # Embedded table delimiter is '!' if '|' not used
    # Gherkin more recent than 3.1.2 does support escaping new lines by `\n`.
    #   Also these two escapes are supported: `\|` amd `\\`. This means two
    #   things. First it is now possible to escape `|` in tables. And second is
    #   that clean-up steps with `\n` will most likely fail if written inside
    #   a table. To support `\n` in clean-up steps, I believe the table syntax
    #   should be used and table should be generated as `table(Array)`
    #   instead of table(String)
    # @param step_spec [#lines, #raw] steps string lines should be obtained
    #   by calling #lines method over spec or calling #raw.flatten; that is
    #   usually a multiline string or Cucumber::MultilineArgument::DataTable
    def to_step_procs(steps_spec)
      if steps_spec.respond_to? :lines
        # multi-line string
        data = steps_spec.lines
      else
        # Cucumber Table
        data = steps_spec.raw.flatten
      end
      data.reject! {|l| l.empty? || l =~ /^.s*#/}

      step_list = []
      step_name = ''
      params = []
      data.each_with_index do |line, index|
        if line.strip.start_with?('!')
          params << [line.gsub('!','|')]
        elsif line.strip.start_with?('|')
          # with multiline string we can use '|'
          params << line
        else
          step_name = line.gsub(/^\s*(?:Given|When|Then|And) /,"")
        end
        next_is_not_param = data[index+1].nil? ||
                            !data[index+1].strip.start_with?('!','|')
        if next_is_not_param
          raise "step not specified" if step_name.strip.empty?

          # then we should add the step to tierdown
          # But do it within a proc to have separately scoped variable for each step
          #   otherwise we end up with all lambdas using the same `step_name` and
          #   `params` variables. That means all lambdas defined within this step
          #   invocation, because lambdas and procs inherit binding context.
          #
          proc {
            _step_name = step_name
            if params.empty?
              step_list.unshift proc {
                logger.info("Step: " << _step_name)
                step _step_name
              }
            else
              _params = params.join("\n")
              step_list.unshift proc {
                logger.info("Step: #{_step_name}\n#{_params}")
                step _step_name, table(_params)
              }
            end
          }.call
          params = []
          step_name = ''
        end
      end

      return step_list
    end
  end
end
