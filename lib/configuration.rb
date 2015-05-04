require 'yaml'

require 'cucushift'
require 'collections'
# should not require 'common'

module CucuShift
  # @note cucushift configuration logic
  class Configuration

    def initialize(opts = {})
      @opts = opts
      unless opts[:files]
        opts[:files] = []
        opts[:files] << File.expand_path("#{HOME}/config/config.yaml")
        priv_config = File.expand_path(CucuShift::PRIVATE_DIR + "/config.yaml")
        opts[:files] << priv_config if File.exist?(priv_config)
      end
    end

    def load_file(config_file)
      config = YAML.load_file(config_file)
    end

    ## return full raw configuration
    def raw
      return @raw_config if @raw_config

      raw_configs = []
      @opts[:files].each { |f| raw_configs << load_file(f) }
      @raw_config = raw_configs.shift
      raw_configs.each { |c| Collections.deep_merge!(@raw_config, c) }

      Collections.deep_map_hash!(@raw_config) { |k, v| [k.to_sym, v] }

      env_overrides(@raw_config)

      # make sure config is not accidentally broken
      Collections.deep_freeze(@raw_config)

      return @raw_config
    end

    # logic to overrige configuration from environment variables
    def env_overrides(conf)
      global_overrides = {
        debug_in_after_hook: "CUCUSHIFT_DEBUG_AFTER_FAIL",
        debug_in_after_hook_always: "CUCUSHIFT_DEBUG_AFTER_HOOK",
        debug_failed_steps: "CUCUSHIFT_DEBUG_FAILSTEP",
      }

      # if envvariable is set, then override the value where "false" is false
      global_overrides.each { |o, var|
        if ENV.key? var
          conf[:global][o] = ENV[key] == "false" ? false : ENV[key]
        end
      }
    end

    # @return value of configuration options
    # @note if opt isn't one of recognized root options, then :global is used
    def [](opt)
      opt = opt.to_sym
      root_options = [:global, :private]
      if root_options.include? opt
        return raw[opt]
      else
        return raw[:global][opt]
      end
    end
  end
end
