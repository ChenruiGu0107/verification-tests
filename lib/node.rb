module CucuShift
  # @note this class represents OpenShift nodes (similar to minions)
  class Node
    # @param host [CucuShift::Host] a mashine
    def initialize(host, opts={})
      @host = host
    end
  end
end
