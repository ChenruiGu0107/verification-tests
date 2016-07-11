require 'rest_helper'

module CucuShift
  module Rest
    module Kubernetes
      extend Helper

      def self.populate(path, base_opts, opts)
        populate_common("/api/<api_version>", path, base_opts, opts)
      end

      class << self
        alias perform perform_common
      end

      def self.access_heapster(base_opts, opts)
        populate("/proxy/namespaces/<project_name>/services/https:heapster:/api/v1/model/metrics", base_opts, opts)
        base_opts[:headers].delete("Accept") unless opts[:keep_accept]
        return perform(**base_opts, method: "GET")
      end

      def self.access_pod_network_metrics(base_opts, opts)
        populate("/proxy/namespaces/<project_name>/services/https:heapster:/api/v1/model/namespaces/<project_name>/pods/<pod_name>/metrics/network/<type>", base_opts, opts)
        base_opts[:headers].delete("Accept") unless opts[:accept]
        return perform(**base_opts, method: "GET")
      end

      def self.delete_subresources_api(base_opts, opts)
        populate("/namespaces/<project_name>/<resource_type>/<resource_name>/status", base_opts, opts)
        return perform(**base_opts, method: "DELETE")
      end

      def self.get_subresources_status(base_opts, opts)
        populate("/namespaces/<project_name>/<resource_type>/<resource_name>/status", base_opts, opts)
        return perform(**base_opts, method: "GET")
      end
 
      def self.get_project_status(base_opts, opts)
        populate("/namespaces/<project_name>/status", base_opts, opts)
        return perform(**base_opts, method: "GET")
      end

      def self.replace_pod_status(base_opts, opts)
        base_opts[:payload] = File.read(opts[:payload_file])
        populate("/namespaces/<project_name>/pods/<pod_name>/status", base_opts, opts)
        return Http.request(**base_opts, method: "PUT")
      end

    end
  end
end
