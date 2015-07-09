require 'set'

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
      used_opts = Set.new

      ## make sure opts contain only allowed values
      opts.keys.each { |k|
        raise "use rest rules to set key: #{k}" unless [:options, :excluded_headers, :included_headers].include? k
      }

      ## lowest priority are common rules and highest - the user provided opts
      rules = merge_rest_rules(rules[:common], rules[key], opts)

      http_opts[:url] = rules[:base_url] + "/" + rules[:url]
      http_opts[:headers] = rules[:headers].select{|h,v| rules[:included_headers].include? h}.delete_if{|h| rules[:excluded_headers].include? h}
      http_opts[:payload] = rules[:payload] if rules[:payload]

      ## replace options within values again without modifying any rules
      http_opts.keys.each do |key|
        case http_opts[key]
        when Hash
        when String

        else
          raise "opt replace in #{http_opts[key].class} not implemented"
        end
      end

      http_opts[:method] = rules[:method]
    end

    def self.get_oauth_token(server_url:, user:, password:)
      # TODO
      # :headers => {'X-CSRF-Token' => 'xxx'} seems not needed
      opts = {:user=>"joe",
              :password=>"redhat",
              :max_redirects=>0,
              :url=>"https://master.cluster.local:8443/oauth/authorize",
              :params=> {"client_id"=>"openshift-challenging-client", "response_type"=>"token"},
              :method=>"GET"
             }
      res = CucuShift::Http.http_request(**opts)
    end

    # replace <something> strings inside strings given option hash with symbol
    #   keys
    # @param [String] str string to replace
    # @param [Hash] opts hash options to use for replacement
    # @param [Set] used_opts put oprions used for replacement in that array
    private def self.replace_str(str, opts, used_opts)
      str.gsub!(/<(.+?)>/) { |m|
        opt_key = m[1..-2].to_sym
        if options[opt_key]
          used_opts << opt_key
          options[opt_key]
        else
          raise("need to provide '#{opt_key}' REST option")
        end
      }
    end

    # try to safety merge rules in order given without modifying them
    private def self.merge_rest_rules(*rules)
      res = rules.shift.dup
      rules.each do |hash|
        res.merge!(hash) do |key, old, new|
          case
          when key == :payload
            # merging payload is a bad idea as payload type of different
            #   requests may not match; each request is better independent
            raise "do not try merging rest request :payload"
          when Array === old && Array === new
            old & new
          when Hash === old && Hash === new
            old.merge(new)
          else
            new
          end
        end
      end

      return res
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
        res = {:options => {}, :excluded_headers => [], :included_headers => []}
        lastval = nil
        opts.each do |key, value|
          case key.strip!
          when ""
            if lastval
              lastval << "\n" << value
            else
              raise "cannot start rest request table with and empty key"
            end
          when /^:excluded_headers?$/
            res[:excluded_headers].concat(value.split(",").map(&:strip))
          when /^:included_headers?$/
            res[:included_headers].concat(value.split(",").map(&:strip))
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
