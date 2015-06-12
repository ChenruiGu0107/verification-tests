module CucuShift
  # @note this class represents OpenShift nodes (aka minions)
  class Node
    # @param host [CucuShift::Host] a mashine
    def initialize(host, opts={})
      @host = host
    end
  end
end
