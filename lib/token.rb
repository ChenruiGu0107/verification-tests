require 'cgi'
require 'uri'

require 'http'

module CucuShift
  # represents an OpenShift token
  class Token
    include Common::Helper

    attr_reader :user, :token, :valid_until

    # @param [CucuShift::User] user the user owning the token
    # @param [String] token the actual token string
    # @param [Time] valid the time until token is valid
    def initialize(user:, token:, valid:)
      @user = user
      @token = token.freeze
      @valid_until = valid
    end

    # it token still valid? 10 seconds given to avoid misleading result due to
    #   network delays
    def valid?(grace_period: 10)
      valid_until > Time.now + grace_period
    end

    def delete
      res = user.rest_request(:delete_oauthaccesstoken, token_to_delete: token)
      if res[:success] || @what
        user.cached_tokens.delete(t)
      end
      return res
    end

    # @param [CucuShift::User] user the user we want token for
    # @return [CucuShift::Token]
    def self.new_oauth_bearer_token(user)
      res = oauth_bearer_token_challenge(
        server_url: user.env.api_endpoint_url,
        user: user.name,
        password: user.password
      )

      unless res[:success]
        msg = "Error getting bearer token, see log"
        if res[:error]
          raise res[:error] rescue raise msg rescue e=$!
        else
          raise msg rescue e=$!
        end
        Http.logger.error(e) # default error printing exclude cause
        raise e
      end

      t = Token.new(user: user, token: res[:token], valid: res[:valid_until])
      user.cached_tokens << t
      return t
    end


    # @param [String] server_url e.g. "https://master.cluster.local:8443"
    # @param [String] user the username to get a token for
    # @password [String] password
    # @return [CucuShift::ResultHash]
    def self.oauth_bearer_token_challenge(server_url:, user:, password:)
      # :headers => {'X-CSRF-Token' => 'xx'} seems not needed
      opts = {:user=> user,
              :password=> password,
              :max_redirects=>0,
              :url=>"#{server_url}/oauth/authorize",
              :params=> {"client_id"=>"openshift-challenging-client", "response_type"=>"token"},
              :method=>"GET"
      }
      res = Http.request(**opts)

      if res[:exitstatus] == 302 && res[:headers]["location"]
        begin
          uri = URI.parse(res[:headers]["location"][0])
          params = CGI::parse(uri.fragment)
          res[:token] = params["access_token"][0]
          res[:expires_in] = params["expires_in"][0]
          res[:valid_until] = Time.new + Integer(res[:expires_in])
          res[:success] = true
        rescue => e
          res[:error] = e
        end
      end

      return res
    end
  end
end
