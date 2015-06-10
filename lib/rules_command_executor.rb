require 'yaml'
require 'find'
# require 'shellwords'

require 'collections'

module CucuShift
  class RulesCommandExecutor
    # @param [Object] rules might be parsed rules, file, directory or array of any of these. All rules are merged and error is raised on duplicate rules. If directory string ends with slash `/` character, then it is loaded recursively.
    # @param [CucuShift::Host] host host to execute the commands on
    # @param [CucuShift::User] user host os user to execute command as (e.g. sudo)
    def initialize(host:, user: nil, rules:)
      @host = host
      @user = user
      @rules_source = rules
    end

    # @see #build_command_line
    # @see #build_expected
    # @see #parse_output
    def run(cmd_key, options)
      cmd = build_command_line(cmd_key, options)
# TODO

    end

    # @param [Hash] raw_rules the rules for building the command line
    # @param [Symbol] cmd_key the command key to invoke
    # @param [Hash, Array] options the options for building the command line
    #       If it is array, expected is to have each element to be a 2 element
    #       {Array} itself where first element is option key and second is
    #       option value. If {Hash}, then option key is the hash key. When
    #       multiple arguments with same key are desired, then use an array of
    #       values or in case you provie and array - multiple lements with same
    #       option key.
    # @return [String] the built command
    # @note all commands are read from the rules. There is a special command
    #       :global_options that provides base rules for any other command.
    #       There are three special option values - :false, `:literal thing`
    #       and `:noescape thing`.
    #       :false means to avoid setting this option and `:literal :false`
    #       would translate to `:false` for the remote chance one needs to set
    #       literal `:false` as a string value. Basically everything after
    #       `:literal` will be threated like a literal string. `:noescape thing`
    #       will avoid shell escaping `thing`, but usage is discouraged.
    #       Multiple arguments from the same type are supported.
    #       Placeholders for options and global command options can be specified
    #       in :cmd with `<options>` and `<global_options>`.
    def build_command_line(cmd_key, options)
      global_option_rules = rules[:global_options] || {}
      option_rules = rules[cmd_key][:options]

      ## build command parameters based on cmd options
      #  if rules are missing for a user provided option, we raise
      parameters = ""
      global_parameters = ""
      options.each { |key, values|
        [values].flatten.each { |value|
          # false might be valid option so we don't ignore option on it
          next if value == ":false" || value == :false || value.nil?

          case
          when option_rules[key]
            parameters << " " << option_rules[key].gsub('<value>', normalize(value))
          when global_option_rules[key]
            global_parameters << global_option_rules[key].gsub('<value>', normalize(value))
          else
            raise "no rules found for option: #{key}"
          end
        }
      }

      ## build final command
      #  we raise when mandatory options in :cmd are missing
      cmd = rules[cmd_key][:cmd].dup
      opts_added = globals_added = false
      cmd.gsub(/<(.+?)>/) { |m|
        opt_key = $1.to_sym
        case opt_key
        when :options
          opts_added = true
          parameters
        when :global_options
          globals_added = true
          global_parameters
        else
          raise "need to provide '#{opt_key}' option" unless options[opt_key]
          options[opt_key]
        end
      }
      cmd << parameters unless opts_added
      cmd << global_parameters unless globals_added
      return cmd
    end

    # convert value to normalized string
    # @param [#to_s] value value to normalize
    # @return [String] normalize value
    # @note imaplement {self#build_command_line} described handling of values
    def normalize(value)
      value = value.to_s
      noescape = false
      catch(:redo) do
        case value
        when /\Aliteral: (.*)\z/
          value = $1
        when /\Anoescape: (.*)\z/
          value = $1
          noescape = true
          redo
        end
      end
      value = @host.shell_escape value unless noescape
      return value
    end

    private def rules
      return @rules if @rules
      return @rules = Collections.deep_freeze(self.class.load_rules(@rules_source))
    end

    def self.load_rules(*sources)
      return sources.flatten.reduce({}) { |rules, source|
        if source.kind_of? Hash
        elsif File.file? source
          source = YAML.load source
        elsif File.directory? source
          files = []
          if source.end_with? "/"
            # we should be recursive
            Find.find(source) { |path|
              if File.file?(path) && path.end_with?(".yaml",".yml")
                files << path
              end
            }
          else
            # we should only load .yaml files in current dir
            files << Dir.entries(source).select {|d| File.file?(d) && d.end_with?(".yaml",".yml")}
          end

          source = load_rules(files)
        else
          raise "unknown rules source '#{source.class}': #{source}"
        end

        rules.merge!(source) { |key, v1, v2|
          raise "duplicate key '#{key}' in rules: #{sources}"
        }
      }
    end
  end
end
