require 'base_helper'

module CucuShift

  # this class should help with parsing container specifications
  class ContainerSpec
    include Common::Helper

    attr_reader :struct
    private :struct

    def initialize(struct)
      @struct = struct
    end

    module ExportMethods
      def env
        return struct['env']
      end

      def image
        return struct['image']
      end

      def image_pull_policy
        return struct['imagePullPolicy']
      end

      def name
        return struct['name']
      end

      def readiness_probe
        return struct['readinessProbe']
      end

      def ports
        return struct['ports']
      end

      def resources
        return struct['resources']
      end

      # return @Hash representation of scc  for example: {"fsGroup"=>1000400000, "runAsUser"=>1000400000, "seLinuxOptions"=>{"level"=>"s0:c20,c10"}}
      def scc
        return struct['securityContext']
      end

      def termination_message_path
        return struct['terminationMessagePath']
      end

      def termination_message_policy
        return struct['terminationMessagePolicy']
      end

      def volume_mounts
        return struct['volumeMounts']
      end

      def memory_limit_raw
        mem_str = self.resources.dig('limits', 'memory')
        raise 'No memory limits defined in the template' if mem_str.nil?
        return mem_str
      end

      def cpu_limit_raw
        cpu_str = self.resources.dig('limits', 'cpu')
        raise 'No cpu limits defined in the template' if cpu_str.nil?
        return cpu_str
      end

      def cpu_request_raw
        cpu_str = self.resources.dig('requests', 'cpu')
        raise 'No cpu requests defined in the template' if cpu_str.nil?
        return cpu_str
      end

      def memory_request_raw
        mem_str = self.resources.dig('requests', 'memory')
        raise 'No memory requests defined in the template' if mem_str.nil?
        return mem_str
      end

      # returns numeric representation of memrory limit in bytes
      def memory_limit
        return convert_to_bytes(self.memory_limit_raw)
      end

      def memory_request
        return convert_to_bytes(self.memory_request_raw)
      end
      def cpu_limit
        return convert_cpu(self.cpu_limit_raw)
      end

      def cpu_request
        return convert_cpu(self.cpu_request_raw)
      end

      # helper methods
      def env_var(name, cached: true, quiet: false)
        env_var = env.find { |e| e["name"] == name }
        return env_var && env_var["value"]
      end
    end

    include ExportMethods

  end
end
