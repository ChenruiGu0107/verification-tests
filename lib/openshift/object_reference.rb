require 'base_helper'

module CucuShift
  # pls reference to kubernetes doc for more details
  # https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.9/#objectreference-v1-core
  # targetRef is a sub-component of a endpoint address
  # => {
  #          "ip" => "10.128.0.10",
  #    "nodeName" => "host-8-242-168.host.centralci.eng.rdu2.redhat.com",
  #   "targetRef" => {
  #                "kind" => "Pod",
  #                "name" => "test-rc-khm70",
  #           "namespace" => "47rxx",
  #     "resourceVersion" => "42845",
  #                 "uid" => "88c2eaec-11de-11e8-adf4-fa163e184fd4"
  #   }
  class ObjectReference
    include Common::Helper

    attr_reader :struct
    private :struct

    def initialize(struct)
      @struct = struct
    end

    module ExportMethods
      def api_verison
        return struct['apiVersion']
      end

      def field_path
        return struct['fieldPath']
      end

      def kind
        return struct['kind']
      end

      def name
        return struct['name']
      end

      def namespace
        return struct['namespace']
      end

      def resource_version
        return struct['resourceVersion']
      end

      def uid
        return struct['uid']
      end

    end

    include ExportMethods
  end
end
