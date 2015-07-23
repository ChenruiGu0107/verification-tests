require 'http'
require 'json'
require 'yaml'

module CucuShift
  module Rest
    module OpenShift
      extend Common::Helper

      def self.populate_common(path, base_opts, opts)
        base_path = "/oapi/<oapi_version>"
        base_opts[:url] = base_opts.delete(:base_url) + base_path + path

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

      # executes rest request and yields block if given on success
      def self.perform_common(**http_opts)
        res =  Http.request(**http_opts)
        if res[:success]
          res[:props] = {}

          if res[:headers] && res[:headers]['content-type']
            content_type = res[:headers]['content-type'][0]
            case
            when content_type.include?('json')
              res[:parsed] = JSON.load(res[:response])
            when content_type.include?('yaml')
              res[:parsed] = YAML.load(res[:response])
            end
          end

          yield res if block_given?
        end
        return res
      end
      class << self
        alias perform perform_common
      end

      def self.delete_oauthaccesstoken(base_opts, opts)
        populate("/oauthaccesstokens/<token_to_delete>", base_opts, opts)
        return perform(**base_opts, method: "DELETE")
      end

      def self.list_projects(base_opts, opts)
        populate("/projects", base_opts, opts)
        return perform(**base_opts, method: "GET")
      end

      def self.delete_project(base_opts, opts)
        populate("/projects/<project_name>", base_opts, opts)
        return perform(**base_opts, method: "DELETE")
      end

      def self.get_user(base_opts, opts)
        populate("/users/<username>", base_opts, opts)
        return perform(**base_opts, method: "GET") { |res|
          res[:props][:name] = res[:parsed]["metadata"]["name"]
          res[:props][:uid] = res[:parsed]["metadata"]["uid"]
        }
      end

      # this usually creates a project in fact
      def self.create_project_request(base_opts, opts)
        base_opts[:payload] = {}
        # see https://bugzilla.redhat.com/show_bug.cgi?id=1244889 for apiVersion
        base_opts[:payload][:apiVersion] = opts[:oapi_version]
        base_opts[:payload]["displayName"] = opts[:display_name] if opts[:display_name]
        base_opts[:payload]["description"] = opts[:description] if opts[:description]
        # base_opts[:payload][:kind] = "ProjectRequest"
        base_opts[:payload][:metadata] = {name: opts[:project_name]}

        populate("/projectrequests", base_opts, opts)
        return Http.request(**base_opts, method: "POST")
      end

      # did not find out how to use this one yet
      def self.create_oauth_access_token(base_opts, opts)
        base_opts[:payload] = {}
        base_opts[:payload]["expiresIn"] = opts[:expires_in] if opts[:expires_in]
        base_opts[:payload]["userName"] = opts[:user_name] if opts[:user_name]
        base_opts[:payload][:scopes] = opts[:scopes] if opts[:scopes]


        populate("/oauthaccesstokens", base_opts, opts)
        return perform(**base_opts, method: "POST") { |res|
          # res[:props][:name] = res[:parsed]["metadata"]["name"]
          # res[:props][:uid] = res[:parsed]["metadata"]["uid"]
        }
      end
    end
  end
end
