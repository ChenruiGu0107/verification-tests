require 'yaml'

module CucuShift
  module Common
    module Rules
      def self.load(*sources)
        return sources.flatten.reduce({}) { |rules, source|
          if source.kind_of? Hash
          elsif File.file? source
            source = YAML.load_file source
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
end
