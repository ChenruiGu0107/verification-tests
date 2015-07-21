require 'common'
require 'collections'

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

    def quit_cucumber
      Cucumber.wants_to_quit = true
    end

    # this is defined in Helper
    # def manager
    # end
  end
end
