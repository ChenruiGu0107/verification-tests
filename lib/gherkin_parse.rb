# frozen_string_literal: true

require 'find'
require 'gherkin/parser'
require 'gherkin/pickles/compiler'
require 'pathname'

require 'cucushift'

module CucuShift
  # @note Used to help parse out feature files using Gherkin 3
  class GherkinParse
    # @param [String] feature the path to a feature file
    # @return [Hash] a gherkin parsed feature
    def parse_feature(feature)
      open(feature) {|io| Gherkin::Parser.new.parse io}
    end

    # @note further parse a feature to compile it into pickles
    # @param [Hash] parsed_feature a previously gherkin parsed object
    # @param [String] feature_path the path to the feature
    # @return [Hash] parsed pickles
    def parse_pickles(feature_path, parsed_feature = nil)
      parsed_feature ||= parse_feature(feature_path)
      Gherkin::Pickles::Compiler.new.compile(parsed_feature, feature_path)
    end

    # @param feature [String, Hash] file path or a parsed feature
    # @return [Array<???>]
    def scenarios_raw(feature)
      case feature
      when String
        feature = parse_feature feature
      when Hash
      else
        raise "unknown feature specification: #{feature.inspect}"
      end

      if feature.has_key? :feature
        # for gherkin 4.0 or greater
        return feature[:feature][:children]
      elsif feature.has_key? :scenarioDefinitions
        return feature[:scenarioDefinitions]
      else
        raise "unknown gherkin parsed format"
      end
    end

    def feature_dirs
      @feature_dirs ||= [
        File.join(HOME, "features"),
        File.join(PRIVATE_DIR, "features")
      ].select {|p| File.directory? p}
    end

    # convert test case ids to [file, line] pairs based on comments e.g.
    #   `# case_id ABC-123456`
    # @param case_ids [Array<String>] test case IDs
    # @return [Hash<String, Array>] `{ case_id => [file, line] }` mapping
    def locations_for(*case_ids)
      raise "specify test case IDs" if case_ids.empty?
      res = {}
      Find.find(*feature_dirs) do |path|
        next unless path.end_with?(".feature") && File.file?(path)

        id_found = nil
        IO.foreach(path).with_index(1) do |line, index|
          break if !id_found && case_ids.empty?
          if id_found
            # valid scenario or examples table should be located at first
            #   non-comment/tag line
            if line =~ /^\s*(#|@)/
              next
            elsif line =~ /^\s*(Scenario|Examples:)/
              res[id_found] = [path, index]
              id_found = nil
              next
            else
              raise "invalid line following #{id_found} comment: #{line}"
            end
          else
            id_found = case_ids.find {|id| line =~ /^(.*)# @case_id #{id}$/}
            pre_tag = $1
            case_ids.delete(id_found) if id_found

            if !id_found || pre_tag =~ /^\s*$/
              next
            elsif pre_tag =~ /^\s*\|.+\|\s+$/
              res[id_found] = [path, index]
              id_found = nil
              next
            else
              raise "cannot understand line: #{line}"
            end
          end
        end
      end
      if case_ids.empty?
        return res
      else
        raise "could not find locations for case IDs: #{case_ids.join(?,)}"
      end
    end

    # convert {case_id => [file, line], ...} pairs to Hash like:
    # some_case_id:
    #   file: some/path
    #   scenario: some scenarioname
    #   args:
    #     arg: if any
    def spec_for(hash, root: File.absolute_path("#{__FILE__}/../.."))
      final = {}
      hash.each do |case_id, (file, line)|
        file_rel = Pathname.new(File.absolute_path(file)).relative_path_from(Pathname.new(root)).to_s
        res = {}
        scenarios_raw(file).each do |scenario|
          if scenario[:location][:line] == line
            res["file"] = file_rel
            res["scenario"] = scenario[:name]
            res["tags"] = scenario[:tags].map{|s| s[:name][1..-1]}
          elsif scenario[:type] == :ScenarioOutline
            scenario[:examples].each do |examples_table|
              if examples_table[:location][:line] == line
                res["file"] = file_rel
                res["scenario"] = scenario[:name]
                res["tags"] = scenario[:tags].map{|s| s[:name][1..-1]}
                res["tags"].concat examples_table[:tags].map { |ex_tag|
                  ex_tag[:name][1..-1]
                }
                # FYI example[:keyword] == "Examples" but we hardcode
                res["args"] = {"Examples" => examples_table[:name]}
              else
                examples_table[:tableBody].each do |example|
                  if example[:location][:line] == line
                    res["file"] = file_rel
                    res["scenario"] = scenario[:name]
                    res["tags"] = scenario[:tags].map{|s| s[:name][1..-1]}
                    res["tags"].concat examples_table[:tags].map { |ex_tag|
                      ex_tag[:name][1..-1]
                    }

                    header = examples_table[:tableHeader][:cells].map { |cell|
                      cell[:value]
                    }
                    values = example[:cells].map { |cell| cell[:value] }
                    res["args"] = Hash[header.zip(values)]
                  end
                  break unless res.empty? # break out of examples rows loop
                end
              end
              break unless res.empty? # break out of example tables loop
            end
          end
          break unless res.empty? # break out of scenarios loop
        end
        if res.empty?
          raise "could not find matching scenario for #{case_id}"
        else
          final[case_id] = res
        end
      end
      return final
    end
  end
end
