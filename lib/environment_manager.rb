module CucuShift
  # this will manage available environments during a test run
  class EnvironmentManager
    include Common::Helper

    def self.get
      @em ||= EnvironmentManager.new
    end

    def initialize()
      @environments = {}
    end

    def [](env_key)
      @environments[env_key] ||= add(env_key)
    end

    private def load(key)
      # get any configuration and ENV variables related to environment key
      env_opts = conf[:environments, key] || {}
      env_prefix = "OPENSHIFT_ENV_#{key.to_s.upcase}_"
      ENV.each do |var, value|
        if var.start_with? env_prefix
          env_opt = varvar[env_prefix.length..-1].downcase.to_sym
          # TODO: should we process any values specially?
          env_opts[env_opt, value]
        end
      end
      env_class = env_opts[:type]
      # TODO: we may implement some shortname to full classname conversion here

      raise "no '#{key}' environment configuration found" if ! env_class || env_class.empty?

      env_opts[:key] = key # lets have it for a reference
      return Object.const_get(env_class).new(env_opts)
    end

    def clean_up
      @environments.each do |key, env|
        env.clean_up
      end
    end
  end
end
