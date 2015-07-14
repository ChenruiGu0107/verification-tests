require 'http'
require 'yaml'

module CucuShift
  module Rest
    module OpenShift
      extend Common::Helper

      def self.populate_common(path, base_opts, opts)
        base_path = "/oapi/<oapi_version>"
        base_opts[:url] = base_opts[:base_url] + base_path + path

        replace_angle_brackets!(base_opts[:url], opts)
        base_opts[:headers].each {|h,v| replace_angle_brackets!(v, opts)}

        if base_opts[:headers]["Content-Type"].include?("json") &&
            ( base_opts[:payload].kind_of?(Hash) ||
              base_opts[:payload].kind_of?(Array) )
          base_opts[:payload] = YAML.to_json(base_opts[:payload])
        end
      end
      class << self
        alias populate populate_common
      end

      def self.delete_oauthaccesstoken(base_opts, opts)
        base_opts = populate("/delete/<token_to_delete>", base_opts, opts)
        base_opts[:method] = "DELETE"
        return Http.request(**base_opts)
      end

      def self.list_projects(base_opts, opts)
        base_opts = populate("/projects", base_opts, opts)
        base_opts[:method] = "GET"
        return Http.request(**base_opts)
      end

      def self.create_project_request(base_opts, opts)
        base_opts[:payload] = {}
        base_opts[:payload]["displayName"] = opts[:displayName] if opts[:displayName]
        base_opts[:payload]["description"] = opts[:description] if opts[:description]
        base_opts = populate("/projectrequests", base_opts, opts)
        base_opts[:method] = "POST"
        return Http.request(**base_opts)
      end
    end
  end
end
