require 'common'
require 'rest_openshift'
require 'rest_kubernetes'

module CucuShift
  module Rest
    class RequestExecutor
      extend Common::Helper

      # def initialize(env)
      #  # @env = env
      # end

      # @note you need to supply one and only one of `user` and `base_opts`
      def self.exec(user: nil, req:, opts: {}, auth: nil, base_opts: nil)
        unless ! user ^ ! base_opts
          raise "you need to supply only one of: user or base_opts parameter"
        end

        unless base_opts
          base_opts = get_base_opts(user: user, auth: auth)
        end

        logger.info("REST #{req} for user '#{user}', base_opts: #{base_opts}, opts: #{opts}")
        return delegate_rest_request(req, base_opts, opts)
      end

      def self.get_base_opts(user:, auth: nil)
        opts = {}

        opts[:options] = {}
        opts[:options][:oapi_version] = user.rest_preferences[:oapi_version] ||
                                          user.env.api_version
        opts[:options][:api_version] = user.rest_preferences[:api_version] ||
                                          user.env.api_version
        opts[:options][:accept] = "application/json"
        opts[:options][:content_type] = "application/json"

        opts[:base_url] = user.env.api_endpoint_url
        opts[:headers] = {}
        opts[:headers]["Accept"] = "<accept>"
        opts[:headers]["Content-Type"] = "<content_type>"

        auth ||= user.rest_preferences[:auth] || Http.conf[:rest_default_auth] || :bearer_token
        case auth
        when :bearer_token
          opts[:options][:oauth_token] = user.get_bearer_token.token
          opts[:headers]["Authorization"] = "Bearer <oauth_token>"
        else
          raise "#{auth.upcase} auth not implemented yet"
        end

        return opts
      end

      # Delegats REST request to relevant REST method
      # @param [Symbol] req the request method to be delegated to, e.g.
      #   :delete_token
      # @param [Hash] base_opts the base HTTP options relevant to server,
      #   authentication, and other things common between requests; these opts
      #   represent options in the format accepted but the
      #   [CucuShift::Http#http_request] method; but should not contain :params
      #   and :payload
      # @param [Hash] req_opts the request options as understood by the
      #   specific `req` method to enrich base_opts for the actual API call
      #   to be performed; In most cases those will be simple key/value pairs
      def self.delegate_rest_request(req, base_opts, req_opts)
        ## use special hash like class to track usage of supplied options
        tracked_opts = UsageTrackingHash.new(base_opts.delete(:options).merge(req_opts))
        tracked_opts[:oapi_version] # make sure this is marked accessed
        tracked_opts[:api_version] # make sure this is marked accessed

        case
        when OpenShift.respond_to?(req)
          res = OpenShift.send(req, base_opts, tracked_opts)
        when Kubernetes.respond_to?(req)
          res = Kubernetes.send(req, base_opts, tracked_opts)
        else
          raise "Neither OpenShift nor Kubernetes APIs have #{req} request defined"
        end

        unless tracked_opts.not_accessed_keys.empty?
          raise "unused options while performing REST request: " +
            tracked_opts.not_accessed_keys.to_s
        end

        return res
      end

      #def clean_up
      #end
    end
  end
end
