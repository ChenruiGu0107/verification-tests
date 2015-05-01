require 'common'

module CucuShift
  # @note this is our default cucumber World extension implementation
  class DefaultWorld
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

    def logger
      manager.logger
    end

    def debug_in_after_hook?
      scenario.failed? && conf[:debug_in_after_hook] || conf[:debug_in_after_hook_always]
    end

    # this is defined in Helper
    # def manager
    # end
  end
end
