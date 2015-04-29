
module CucuShift
  # @note this would extend default cucumber World
  class DefaultWorld
    include Common::Helper
    # attr_accessor :test

    def initialize
      # we want to keep a reference to current World in the manager
      # hopefully cucumber does not instantiate us too early
      manager.world = self
    end

    def logger
      # TODO: return logger
    end

    # this is defined in Helper
    # def manager
    # end
  end
end
