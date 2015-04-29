module CucuShift
  # @note this class represents an OpenShift test environment and allows setting it up and in some cases creating and destroying it
  class Environment
    # @param name [String] just a human readable identifier
    def initialize(name)
      @masters = []
      @nodes = []
    end
  end
end
