module CucuShift
  # @note this class represents an OpenShift master server
  class Master
    # @param host [CucuShift::Host] a mashine
    def initialize(host, opts={})
      @host = host
    end
  end
end
