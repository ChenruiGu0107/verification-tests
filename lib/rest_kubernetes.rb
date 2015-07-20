require 'http'
require 'json'

module CucuShift
  module Rest
    module Kubernetes
      extend Common::Helper

      def self.populate_common(path, base_opts, opts)
        base_path = "/api/<api_version>"
        base_opts[:url] = base_opts[:base_url] + base_path + path

        replace_angle_brackets!(base_opts[:url], opts)
        base_opts[:headers].each {|h,v| replace_angle_brackets!(v, opts)}

        if base_opts[:headers]["Content-Type"].include?("json") &&
            ( base_opts[:payload].kind_of?(Hash) ||
              base_opts[:payload].kind_of?(Array) )
          # YAML was a bad idea https://github.com/tenderlove/psych/issues/243
          #base_opts[:payload] = YAML.to_json(base_opts[:payload])
          base_opts[:payload] = base_opts[:payload].to_json
          #base_opts[:payload] = JSON.pretty_generate(base_opts[:payload])
        end
      end
      class << self
        alias populate populate_common
      end

    end
  end
end
