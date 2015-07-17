require 'token'

module CucuShift
  # @note represents an OpenShift environment user account
  class User
    attr_reader :name, :env, :rest_preferences

    def initialize(name: nil, password: nil, token: nil, env:)
      @name = name.freeze if name
      @env = env
      @password = password.freeze if password
      @rest_preferences = {}
      @tokens = []

      # we just guess token validity of one day, it should be persisting
      #   long enough to conduct testing anyway; I don't see reason to do the
      #   extra step getting validity from API
      @tokens << Token.new(user: self, token: token, valid: Time.now + 24 * 60 * 60).protect if token

      if @tokens.empty? && (@name.nil? || @password.nil?)
        raise "to initialize user we need a token or username and password"
      end
    end

    def name
      return @name if @name

      ## obtain username by the token
      unless cached_tokens[0]
        raise "somehow user has no name and no token defined"
      end

      res = env.rest_request_executor.exec(user: self, auth: :bearer_token,
                                           req: :get_user,
                                           opts: {username: '~'})

      if res[:success] && res[:props] && res[:props][:name]
        @name = res[:props][:name]
        return @name
      else
        raise "could not obtain username with token #{cached_tokens[0]}: #{res[:response]}"
      end
    end

    # @return true if we know user's password
    def password?
      return !! @password
    end

    def password
      if @password
        return @password
      else
        # most likely we initialized user with token only so we don't know pswd
        raise "user #{name} initialized without a password"
      end
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

    # will return user known oauth tokens
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
        cached_tokens.last.delete(uncache: true)
      end
    end
  end
end
