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
        opts[:files] << File.expand_path("#{HOME}/../../config/config.yaml")
        priv_config = File.expand_path(CucuShift::PRIVATE_DIR + "/config.yaml")
        opts[:files] << priv_config if File.exist?(priv_config)
      end
    end

    def load_file(config_file)
      config = YAML.load_file(config_file)


    ## return full raw configuration
    def raw
      return @raw_config if @raw_config

      raw_configs = []
      @opts[:files].each { |f| raw_configs << load_file(f) }
      @raw_config = raw_configs[0]

      if raw_configs.size > 1
        Collections.monkey_patch_deep_merge(@raw_config)
        raw_configs.shift
        raw_configs.each {|c| @raw_config.deep_merge(c)}
      end

      Collections.deep_sym_keys(@raw_config)

      env_overrides(@raw_config)

      # make sure config is not accidentally broken
      Collections.deep_freeze(@raw_config)

      return @raw_config
    end

    def env_overrides(conf)
      # conf[:global][:whatever] = ENV["ASD"] if ENV["ASD"]"
    end

    # @return value of configuration options
    # @note if opt isn't one of recognized root options, then :global is used
    def self.[](opt)
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
