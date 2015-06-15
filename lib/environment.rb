module CucuShift
  # @note this class represents an OpenShift test environment and allows setting it up and in some cases creating and destroying it
  class Environment
    attr_reader :opts

    # @param name [String] just a human readable identifier
    def initialize(**opts)
      @opts = opts
      @masters = []
      @nodes = []
    end

    def user_manager
      @user_manager ||= Object.const_get(opts[:user_manager]).new(self, **opts)
    end
    alias users user_manager

    def clean_up
      @user_manager.clean_up if @user_manager
    end
  end

  # a quickly made up environment class for the PoC
  class StaticEnvironment < Environment
    def initialize(**opts)
      super

      # these two shuld not be kept private
      @masters_hostnames = opts[:masters].split(",")
      @nodes_hostnames = opts[:nodes].split(",")

      if @nodes_hostnames.empty? or @masters_hostnames.empty?
        raise "specify at least one master and one node; might be the same host"
      end
    end

    private def masters_hostnames
      @masters_hostnames
    end

    private def nodes_hostnames
      @nodes_hostnames
    end

    def masters
      if @masters.empty?
        @masters << masters_hostnames.map do |host|
          # TODO: might do convenience type to class conversion
          # TODO: we might also consider to support setting type per host
          @nodess.find {|h| h.hostname == host} ||
            Object.const_get(opts[:hosts_type]).new(hostname, **opts)
        end
      end
      return @masters
    end

    def nodes
      if @nodes.empty?
        @nodes << nodes_hostnames.map do |host|
          # TODO: might do convenience type to class conversion
          # TODO: we might also consider to support setting type per host
          @masters.find {|h| h.hostname == host} ||
            Object.const_get(opts[:hosts_type]).new(hostname, **opts)
        end
      end
      return @nodes
    end
  end
end
