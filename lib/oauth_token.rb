module CucuShift
  # represent an OpenShift OAuth Token
  class OAuthToken
    attr_reader :token, :user

    # @param [CucuShift::User] user the owner user of the token
    def initialize(user, token, valid_until = nil)
      @user = user
      @token = token.freeze
      @valid_until = valid_until
    end

    def valid_until
      return @valid_until if @valid_until

      # TODO: get token expity time here
      raise "getting token expiry time not implemented"
    end
  end
end
