module CucuShift
  module Rest
    module Kubernetes
      extend Common::Helper

      def self.populate_common(path, base_opts, opts)
        base_path = "/api/<api_version>"
        base_opts[:url] = base_opts[:base_url] + base_path + path

        replace_angle_brackets!(base_opts[:url], opts)
        base_opts[:headers].each {|h,v| replace_angle_brackets!(v, opts)}
      end

    end
  end
end
