require 'ostruct'
require 'common'
require 'collections'

require 'openshift/project'
require 'openshift/service'
require 'openshift/route'
require 'openshift/pod'

module CucuShift
  # @note this is our default cucumber World extension implementation
  class DefaultWorld
    include CollectionsIncl
    include Common::Helper

    attr_accessor :scenario

    def initialize
      # we want to keep a reference to current World in the manager
      # hopefully cucumber does not instantiate us too early
      manager.world = self

      @clipboard = OpenStruct.new
      # some arrays to store cached objects
      @projects = []
      @services = []
      @routes = []
      @pods = []

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
      end
    end

    # @note call like `user(0)` or simply `user` for current user
    def user(num=nil)
      return @user if num.nil? && @user
      num = 0 unless num
      return @user = env.users[num]
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

    # @return project from cached projects for this scenario
    #   note that you need to have default `#env` set already;
    #   if no name is spefified, returns the last requested project;
    #   otherwise a CucuShift::Project object is created (but not created in
    #   the actual OpenShift environment)
    def project(name = nil, env = nil)
      env ||= self.env

      if name
        p = @projects.find {|p| p.name == name && p.env == env}
        if p && @projects.last.equal?(p)
          return p
        elsif p
          # put requested project at top of the stack
          @projects << @projects.delete(p)
          return p
        else
          #raise "no project named '#{name}' in cache for env '#{env.key}'"
          @projects << Project.new(name: name, env: env)
          return @projects.last
        end
      elsif @projects.empty?
        #raise "no projects in cache"
        @projects << Project.new(name: rand_str(5, :dns), env: env)
        return @projects.last
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

    # @return pod by name from scenario cache; with no params given,
    #   returns last requested pod; otherwise creates a [Pod] object
    # @note you need the project already created
    def pod(name = nil, project = nil)
      project ||= self.project

      if name
        s = @pods.find {|p| p.name == name && p.project == project}
        if p && @pods.last == p
          return p
        elsif p
          @pods << @pods.delete(p)
          return p
        else
          # create new CucuShift::Pod object with specified name
          @pods << Pod.new(name: name, project: project)
          return @pods.last
        end
      elsif @pods.empty?
        # we do not create a random pod like with projects because that
        #   would rarely make sense
        raise "what pod are you talking about?"
      else
        return @pods.last
      end
    end

    # add pods to list avoiding duplicates
    def pods_add(*new_pods)
      new_pods.each {|p| @pods.delete(p); @pods << p}
    end

    # @param proc_obj [Proc] a proc or lambda to add to teardown
    # @yield [] a block that will be added to teardown
    # @note teardowns should ever raise only if issue can break further
    #   scenario execution. When a teardown raises, that causes cucumber to
    #   skip executing any further scenarios.
    def teardown_add(proc_obj=nil, &block)
      if block
        @teardown << block
      else
        @teardown << proc_obj
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
  end
end
