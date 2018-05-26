module CucuShift
  module Platform
    # handles the fact node config is synced with a config map in 3.10
    class NodeConfigMapSyncConfig
      attr_reader :simple_config, :service
      private :simple_config

      def initialize(service)
        @service = service
        @simple_config = SimpleServiceYAMLConfig.new(
          service,
          "/etc/origin/node/node-config.yaml"
        )
        sync_running = true
      end

      def merge!(yaml)
        sync_stop!
        simple_config.merge!(yaml)
      end

      def restore
        simple_config.restore
        ret = apply
        sync_start!
        return ret
      end

      def apply
        simple_config.apply
      end

      def as_hash
        simple_config.as_hash
      end

      private def sync_daemon_set
        @sync_daemon_set ||= DaemonSet.new(
          name: "sync",
          project: Project.new(name: "openshift-node", env: service.env)
        )
      end

      # @param labels [Hash<String, String>]
      private def patch_daemon_set(labels)
        patch = [{
          "op" => "add",
          "path" => "/spec/template/spec/nodeSelector",
          "value" => labels,
        }]
        res = service.env.admin.cli_exec(
          :patch,
          resource: sync_daemon_set.class::RESOURCE,
          resource_name: sync_daemon_set.name,
          n: sync_daemon_set.project.name,
          type: "json",
          p: patch.to_json
        )
        unless res[:success]
          raise "cound not patch daemonset node selector, see log"
        end
        # delete pods to enforce the change
        # countrary to docs, pods seem to be removed by patch alone
        #pods = sync_daemon_set.pods(user: service.env.admin, cached: false)
        #unless pods.empty?
        #  res = service.env.admin.cli_exec(
        #    :delete,
        #    object_type: Pod::RESOURCE,
        #    object_name_or_id: pods.map(&:name)
        #  )
        #  unless res[:success]
        #    raise "cound not delete daemonset pods, see log"
        #  end
        #end
      end

      private def sync_running?
        @sync_running
      end

      private def sync_start!
        return if sync_running?
        patch_daemon_set(@node_selector_orig)
        @sync_running = true
      end

      private def sync_stop!
        @node_selector_orig ||= sync_daemon_set.node_selector(
          user: service.env.admin,
          cached: false
        )
        patch_daemon_set({"disabled" => "for-testing"})
        @sync_running = false
      end
    end
  end
end
