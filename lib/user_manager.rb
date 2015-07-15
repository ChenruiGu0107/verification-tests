require 'set'

require 'user'

module CucuShift
  class UserManager
    attr_reader :env, :opts

    def initialize(env, **opts)
      @env = env
      @opts = opts
      @users = []
    end

    def users_used
      raise 'should use a subclass with #{__method__} implemented'
    end

    def clean_up
      users_used.each(&:clean_up)
    end
  end

  class StaticUserManager < UserManager
    attr_reader :users_used

    def initialize(env, **opts)
      super
      load_users
      @users_used = Set.new
    end

    def load_users
      opts[:user_manager_users].split(",").each do |uspec|
        username, colon,  password = uspec.partition(":")
        @users << User.new(username, password, env, **opts)
      end
    end

    def [](num)
      @users_used << @users[num]
      return @users[num]
    end
  end
end
