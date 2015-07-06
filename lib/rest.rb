require 'http'
require 'result_hash'
require 'common'

module CucuShift
  module Rest
    extend Common::Helper

    # generic rule based rest request method.
    #   It merges :common and :<key> from rules and then opts to prepare the
    #   final rules for the rest request.
    #   Then it executes a request based on provided `opts`. `opts` would
    #   mostly contain :options for populating :payload with parameters. But
    #   also can contain any other key from rules. See [#opts_array_to_hash]
    #   for information how arrays of opts are parsed.
    #
    #   We artificially limit keys that can be supplied by opts to a smaller
    #   set so that rules is the primary place where these are specified. Pass
    #   in opts only what cannot be done with rules.
    # @param [Hash|Array] opts normalized Hash or raw array options;
    #   if opts is an Array, that might be modified so beware
    # @param [Symbol|String] key the REST operation key
    # @param [Hash] rules the Hash of rules to be used for the request
    # @return [CucuShift:ResultHash]
    def self.rest_request(key:, rules:, opts)
      key = str_to_sym(key)
      opts = opts_array_to_hash(opts)
      http_opts = {}

      ## make sure opts contain only allowed values
      opts.keys.each { |k|
        raise "use rest rules to set key: #{k}" unless [:options, :excluded_headers].include? k
      }

      rules = merge_rest_rules(rules[:common], rules[key], opts)

      url = rules[:base_url] + "/" + rules[:url]
      raise "unimplemented"
    end

    def merge_rest_rules(*rules)
      raise "unimplemented"
    end

    # converts an options array into a Hash for performing a REST request.
    #   This is useful for parsing out Cucumber Table parameters. Method
    #   should parse out mainly `options` to represent options from rules. But
    #   also supports behavioral options.
    #   It supports multi-line values and merging multiple :exclude_header keys
    #   into an array of :excluded_headers. Or splitting comma separated
    #   :exlude_headers key into an array. In the future we may add other
    #   special handling of options.
    #
    #   tl;dr all key/value pairs are put into :options Hash, and everything
    #   that starts with ":" is put unto it's own key of the resulting Hash
    # @param [Hash|Array] opts normalized Hash or raw array of options
    # @note this method can modify the provided opts array
    def self.opts_array_to_hash(opts)
      case opts
      when Hash
        # we assume that things are normalized when Hashed is passed in
        return opts
      when Array
        res = {:options => {}, :excluded_headers => []}
        lastval = nil
        opts.each do |key, value|
          case key.strip!
          when ""
            if lastval
              lastval << "\n" << value
            else
              raise "cannot start rest request table with and empty key"
            end
          when /^:excluded_headers$/
            res[:excluded_headers].concat(value.split(",").map(&:strip))
          when /^:excluded_header$/
            res[:excluded_headers] << value.strip
          when /^:/
            res[str_to_sym(key)] = lastval = value
          else
            res[:options][str_to_sym(key)] = lastval = value
          end
        end
      else
        raise "unknown REST options format: #{opts}"
      end
    end

    # just loads YAML files and merges them, nothing rest specific
    def self.load_rules(*sources)
      Common::Rules.load(*sources)
    end
  end
end
