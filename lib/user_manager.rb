module CucuShift
  class UserManager
    attr_reader :env, :opts

    def initialize(env, **opts)
      @env = env
      @opts = opts
      @users = []
    end

    def clean_up
    end
  end

  class StaticUserManager < UserManager
    def initialize(env, **opts)
      super
      load_users
    end

    def load_users
      @users << opts[:user_manager_users].split(",").map do |uspec|
        username, colon,  password = uspec.partition(":")
        User.new(username, password, env, **opts)
      end
    end

    def [](num)
      return @users[num]
    end
  end
end
