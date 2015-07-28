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

      # some arrays to store cached objects
      @projects = []
      @services = []
      @routes = []
      @pods = []
    end

    def setup_logger
      CucuShift::Logger.runtime = @__cucumber_runtime
    end

    def debug_in_after_hook?
      scenario.failed? && conf[:debug_in_after_hook] || conf[:debug_in_after_hook_always]
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
        # we do not create a random service like with projects because that
        #   would rarely make sense
        raise "what route are you talking about?"
      else
        return @routes.last
      end
    end

    def pod
      raise "getting pod not implemented"
    end

    def quit_cucumber
      Cucumber.wants_to_quit = true
    end

    # this is defined in Helper
    # def manager
    # end
  end
end
