require 'yaml'
require 'find'

require 'collections'

module CucuShift
  class RulesCommandExecutor
    # @param rules [Object] might be parsed rules, file, directory or array of any of these. All rules are merged and error is raised on duplicate rules. If directory string ends with slash `/` character, then it is loaded recursively.
    # @param host [CucuShift::Host] to execute the commands on
    # @param user [CucuShift::User] host os user to execute command as (e.g. sudo)
    def initialize(host:, user: nil, rules:)
      @host = host
      @user = user
      @rules_source = rules
    end

    def run(cmd_key, options, global_options)
      # TODO
    end

    

    private def rules
      return @rules if @rules
      return @rules = Collections.deep_freeze(self.load_rules(@rules_source))
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
