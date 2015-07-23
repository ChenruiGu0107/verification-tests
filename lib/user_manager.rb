require 'set'

require 'openshift/user'

module CucuShift
  class UserManager
    attr_reader :env, :opts

    def initialize(env, **opts)
      @env = env
      @opts = opts
      @users = []
    end

    # @return [#each, #clear] a set of users that supports clear and each
    #   methods; [Array] and [Set] should do
    def users_used
      raise 'should use a subclass with #{__method__} implemented'
    end

    def clean_up
      users_used.each(&:clean_up)
      users_used.clear
    end
  end

  class StaticUserManager < UserManager
    attr_reader :users_used

    def initialize(env, **opts)
      super
      load_users
      # # @users_used = Set.new
      @users_used = []
    end

    def load_users
      # opts[:user_manager_users].split(",").each do |uspec|
      #   username, colon,  password = uspec.partition(":")
      #   @users << User.new(username, password, env, **opts)
      # end
      @user_specs = opts[:user_manager_users].split(",").map do |uspec|
        if uspec.empty?
          raise "empty user specification does not make sense"
        elsif uspec.start_with? ':'
          # this user is specified by token only
          {token: uspec[1..-1]}
        else
          username, colon,  password = uspec.partition(":")
          {name: username, password: password}
        end
      end
      Collections.deep_freeze(@user_specs)
    end

    def [](num)
      if @users_used[num]
        return @users_used[num]
      elsif @user_specs[num]
        @users_used[num] = User.new(**@user_specs[num], env: env)
        return @users_used[num]
      else
        raise "missing soecification for user index #{num}"
      end
    end
  end
end
