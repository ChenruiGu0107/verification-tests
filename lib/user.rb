require 'token'

module CucuShift
  # @note represents an OpenShift environment user account
  class User
    attr_reader :name, :password, :env, :config, :rest_preferences
    def initialize(name, password, env, **config)
      @name = name.freeze
      @env = env
      @password = password.freeze
      @config = config
      @rest_preferences = {}
      @tokens = []
    end

    def cli_executor
      env.cli_executor
    end

    def cli_exec(key, opts={})
      cli_executor.exec(self, key, opts)
    end

    # execute a rest request as this user
    # @param [Symbol] req the request to be executed
    # @param [Hash] opts the options needed for particular request
    # @note to set auth type, add :rest_default_auth to @rest_preferences
    def rest_request(req, **opts)
      env.rest_request_executor.exec(user: self, req: req, opts: opts)
    end

    def rest_request_executor
      env.rest_request_executor
    end

    # will return user known tokens
    # @note we do not encourage caching everything into this test framework,
    #   rather prefer discovering online state. Token is different though as
    #   without a token, one is unlikely to be able to perform any other
    #   operation. So we need to have at least limited token caching.
    def cached_tokens
      return @tokens
    end

    def get_bearer_token(**opts)
      return cached_tokens.first if cached_tokens.size > 0
      return Token.new_oauth_bearer_token(self) # this should add token to cache
    end

    def clean_up
      # clean_up any tokens
      until cached_tokens.empty?
        cached_tokens.last.delete
      end
    end
  end
end
