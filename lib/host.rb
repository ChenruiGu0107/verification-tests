module CucuShift
  # @note a generic machine that we have access to
  class Host
    # @param hostname [String] that test machine can access the machine with
    def initialize(hostname, opts={})
      @hostname = hostname
    end
  end
end
