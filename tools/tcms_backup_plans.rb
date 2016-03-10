#!/usr/bin/env ruby

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib")

require 'tcms/tcms'

require 'commander'
require 'yaml'
require 'zlib'

require 'asciidoctor' # to generate html

module CucuShift
  class TcmsBackup
    include Commander::Methods

    # this file should match jenkins job archive pattern
    BACKUP_FILENAME_DEFAULT = "TCMS_backup.yml.gz"
    # following two must match filenames from jenkins system groovy script
    BACKUP_OLD_FILENAME = "old_TCMS_backup.yml.gz"
    BACKUP_DIFF_PREFIX = "TCMS_backup.report"

    def initialize
    end

    def tcms
      return @tcms if @tcms
      @tcms = CucuShift::TCMS.new
    end

    def run
      program :name, 'tcms_backup_plans'
      program :version, '0.0.1'
      program :description, 'Tool to backup TCMS plans into YAML files'

      # global_option('-p', '--plan-ids PLAN_IDS', 'comma separated list of plans to backup')
      # global_option('-o', '--output-file OUTPUT_FILE', 'output file')

      default_command :backup

      command :fiddle do |c|
        c.syntax = "#{$0} fiddle <backup_file.gz>"
        c.description = 'load backup from file and starts pry'
        c.action do |args, options|
          require 'pry'
          backup_struct = load_yaml_from_gz(args.first)
          binding.pry
        end
      end

      command :restore_case_tester do |c|
        c.syntax = "#{$0} restore_case_tester [options]"
        c.description = 'restore default case tester for a plan from backup'
        c.option('-p', '--plan-ids PLAN_IDS', 'comma separated list of plans to restore')
        c.option('-b', '--backup BACKUP_ARCHIVE', 'backup archive to restore from')
        c.option('--doit', 'actually perform the operation; dry run otherwise')
        c.action do |args, options|
          restore_cases_testers(
            options.plan_ids.split(',').map{|id| Integer(id)},
            options.backup,
            options.doit
          )
        end
      end

      command :restore_components do |c|
        c.syntax = "#{$0} restore_components [options]"
        c.description = 'restore components of test cases for a plan'
        c.option('-p', '--plan-ids PLAN_IDS', 'comma separated list of plans to restore')
        c.option('-b', '--backup BACKUP_ARCHIVE', 'backup archive to restore from')
        c.option('--doit', 'actually perform the operation; dry run otherwise')
        c.action do |args, options|
          restore_components(
            options.plan_ids.split(',').map{|id| Integer(id)},
            options.backup,
            options.doit
          )
        end
      end

      command :tags do |c|
        c.syntax = "#{$0} tags <backup_file.gz>"
        c.description = 'reports discrepancies between scenario and TCMS tags'
        c.action do |args, options|
          compare_tcms_to_code(args.first)
        end
      end

      command :backup do |c|
        c.syntax = "#{$0} backup [options]"
        c.description = 'backup plans to file and generates report if old backup is present (this is tightly coupled to jenkins job logic)'
        c.option('-p', '--plan-ids PLAN_IDS', 'comma separated list of plans to backup')
        c.option('-o', '--output-file OUTPUT_FILE', 'output file')
        c.action do |args, options|
          if options.plan_ids.nil?
            raise "You should specify TCMS plan ids to backup"
          end
          plan_ids = options.plan_ids.split(',')
          output_file = options.output_file || BACKUP_FILENAME_DEFAULT

          initial_cleanup(output_file)

          backup(plan_ids, output_file)
          diff_report(output_file)
        end
      end

      run!
    end

    def initial_cleanup(current_backup_file)
      File.delete(current_backup_file) if File.exist?(current_backup_file)
      [ current_backup_file,
        # BACKUP_OLD_FILENAME,
        # "../" + BACKUP_OLD_FILENAME,
        BACKUP_DIFF_PREFIX + ".adoc",
        BACKUP_DIFF_PREFIX + ".html" ].each { |file|
          File.delete(file) if File.exist?(file)
      }
    end

    def backup(plan_ids, file)
      ## this code would write a valid YAML without loading all data in RAM
      Zlib::GzipWriter.open(file, Zlib::BEST_COMPRESSION) do |f|
        #File.open(file, 'w') do |f|
        f.write "---\n" # write YAML header
        plan_ids.each do |p|
          f.write "#{p}:\n" # YAML is a map of plan: array of cases  pairs
          cases = tcms.call('TestCase.filter', {'plan' => p.to_i})
          cases.each_slice(25) { |mc|
            case_ids = mc.map { |c| c["case_id"] }
            get_blessed_cases(*case_ids).each { |case_hash|
              case_str = YAML.dump(case_hash)
              # now write case to file as part of the plan array
              case_str.sub!("---\n","").gsub!(/^/,"  ").sub!(" ","-")
              f.write case_str
            }
          }
        end
      end
    end

    def get_blessed_cases(*cases)
      timeout = 600 #seconds
      start = Time.now
      begin
        return tcms.get_blessed_cases(*cases)
      rescue => e
        if Time.now - start > timeout
          raise e
        else
          puts "Error getting #{cases.size} cases, retying"
          sleep 5
          retry
        end
      end
    end

    # will retry with timeout until case is retrieved
    def get_blessed_case(case_id)
      timeout = 600 #seconds
      start = Time.now
      begin
        tcms.get_case(case_id)
      rescue => e
        if Time.now - start > timeout
          raise e
        else
          puts "Error getting case #{case_id}, retying"
          sleep 5
          retry
        end
      end
    end

    # @param plan_ids [Array<integer>] plan IDs to restore
    # @param backup_archive [String] path to backup archive
    # @param perform [Boolean] should we actually perform the restore or dry run
    def restore_cases_testers(plan_ids, backup_archive, perform=false)
      backup_struct = load_yaml_from_gz(backup_archive)
      missing_plans = plan_ids - backup_struct.keys
      unless missing_plans.empty?
        raise "we don't have backup of plans: #{missing_plans}"
      end

      puts "Restoring Default Testers for plans: #{plan_ids}"
      plan_ids.each do |plan_id|
        plan_cases = backup_struct[plan_id]
        cases_by_tester_id = plan_cases.group_by {|c| c["default_tester_id"]}
        cases_by_tester_id.each do |tester_id, cases|
          puts "Restoring #{cases.size} cases to default tester: #{cases[0]["default_tester"]}"
          if perform
            case_ids = cases.map { |c| c["case_id"] }
            tcms.update_testcases(case_ids, {"default_tester" => tester_id})
          else
            puts "Nothing changed, dry run."
          end
        end
      end
    end

    # @param plan_ids [Array<integer>] plan IDs to restore
    # @param backup_archive [String] path to backup archive
    # @param perform [Boolean] should we actually perform the restore or dry run
    def restore_components(plan_ids, backup_archive, perform=false)
      backup_struct = load_yaml_from_gz(backup_archive)
      missing_plans = plan_ids - backup_struct.keys
      unless missing_plans.empty?
        raise "we don't have backup of plans: #{missing_plans}"
      end

      puts "Restoring Components for TestCases in plans: #{plan_ids}"
      commands = []
      plan_ids.each do |plan_id|
        plan_cases = backup_struct[plan_id]
        cur_cases = tcms.filter_cases_by_id(plan_cases.map{|c| c['case_id']})
        plan_cases.each do |tcase|
          cur_case = cur_cases.find { |c| c['case_id'] == tcase['case_id'] }
          extra_components = cur_case['component'] - tcase['component']
          missing_components = tcase['component'] - cur_case['component']

          if !missing_components.empty?
            commands << ['TestCase.add_component',
                         tcase['case_id'],
                         missing_components]
          end
          if !extra_components.empty?
            commands << ['TestCase.remove_component',
                         tcase['case_id'],
                         extra_components]
          end
        end
      end

      puts commands.map(&:to_s)
      if perform
        commands.each_slice(100) { |command_slice|
          tcms.multicall(*command_slice)
        }
      else
        puts "DRY Run, nothing changed"
      end
    end

    # @return [String] report test case differences between old and new [Hash]
    def diff_backups(old, new)
      new_plans = new.keys - old.keys
      missing_plans = old.keys - new.keys

      plans_to_compare = new.keys & old.keys
      plans_comparison = {}
      plans_to_compare.each do |p|
        cmp = plans_comparison[p] = {}
        interesting_new = new[p] - old[p]
        interesting_old = old[p] - new[p]
        interesting_new.select! {|c| c["case_status"] == "CONFIRMED"}
        interesting_old.select! {|c| c["case_status"] == "CONFIRMED"}
        changed_case_ids = interesting_new.select do |new_case|
          interesting_old.find { |old_case|
            old_case["case_id"] == new_case["case_id"]
          }
        end
        changed_case_ids.map! {|c| c["case_id"]}

        cmp[:new] = new_cases = interesting_new.select { |c|
          ! changed_case_ids.include? c["case_id"]
        }
        cmp[:removed] = removed_cases = interesting_old.select { |c|
          ! changed_case_ids.include? c["case_id"]
        }

        cmp[:changed] = changed_case_ids.reduce({}) do |res, id|
          res[id] = [ interesting_old.find {|c| c["case_id"] ==id},
              interesting_new.find {|c| c["case_id"] ==id}
          ]
          res
        end
      end

      gen_diff_report({
        :new_plans => new_plans,
        :missing_plans => missing_plans,
        :plans_comparison => plans_comparison
      })
    end

    # @param [Hash] what changed
    # @return [String] report based on plan diff
    def gen_diff_report (opts)
      report = "= TCMS DIFF report" + "\n" * 2

      unless opts[:new_plans].empty?
        report << "== tracking #{opts[:new_plans].size} new plans:\n"
        report << "* " + opts[:new_plans].join("\n* ") + "\n" * 2
      end
      unless opts[:missing_plans].empty?
        report << "== stopped tracking #{opts[:missing_plans].size} plans:\n"
        report << "* " + opts[:missing_plans].join("\n* ") + "\n" * 2
      end

      report << "== #{opts[:plans_comparison].size} plans compared:\n"
      report << "* " + opts[:plans_comparison].keys.join("\n* ") << "\n" * 2

      plans_changed = opts[:plans_comparison].select{ |plan_id, cmp|
        cmp.keys.any? {|k| ! cmp[k].empty?}
      }
      report << "== changes made to #{plans_changed.size} plans:\n"
      report << "* " + plans_changed.keys.join("\n* ") << "\n" * 2

      plans_changed.each do |plan_id, cmp|
        report << "== changes made to plan: #{plan_id}\n"

        report << "=== #{cmp[:removed].size} removed/disabled cases:\n"
        removed_cases = cmp[:removed].map {|c| "* #{case_id_url(c["case_id"])}: #{c["summary"]}"}
        report << removed_cases.join("\n") << "\n" * 2

        report << "=== #{cmp[:new].size} new cases:\n"
        new_cases = cmp[:new].map {|c| "* #{case_id_url(c["case_id"])}: #{c["summary"]}"}
        report << new_cases.join("\n") << "\n" * 2

        report << "=== #{cmp[:changed].size} changed cases:\n"
        changed_cases = cmp[:changed].map do |case_id, v|
          old_case, new_case = v

          fields_changed = []
          old_case.each { |field, value|
            unless value == new_case[field]
              fields_changed << field
            end
          }

          # make some fields easier to read
          fields_changed.map! { |f|
            case f
            when "is_automated"
              if new_case["is_automated"] == 0
                "deautomated"
              elsif old_case["is_automated"] == 0
                "automated"
              else
                f
              end
            when "tag"
              added = new_case["tag"] - old_case["tag"]
              removed = old_case["tag"] - new_case["tag"]
              tag_str = 'tags'
              tag_str << " added: " + added.join(" ") + ";" unless added.empty?
              tag_str << " removed: " + removed.join(" ")  unless removed.empty?
              f + footnote(tag_str)
            when "priority"
              "#{old_case["priority"]}->#{new_case["priority"]}"
            when "case_status_id", "priority_id"
              # mark for removal as already seen by other fields
              nil
            when "case_status"
              new_case["case_status"]
            else
              f
            end
          }
          fields_changed.delete_if(&:nil?)

          "* #{case_id_url(case_id)} - *#{fields_changed.join(", ")}* - #{old_case["summary"]}"
        end
        report << changed_cases.join("\n") << "\n" * 2

        report << "\n" * 2
      end

      return report
    end

    # @param string [String] string to appear literary inside doc
    # @return [String] the string inside a pass macro
    def literal(string)
      "{wj}pass:[#{string.gsub(']','\]')}]"
    end

    # @param [String] string to be put as a footnote
    # @param [map] opts
    # @return [String] the string in footnote notation
    def footnote(string, opts = {})
      literal = opts.has_key?(:literal) ? opts[:literal] : false
      superscript = opts.has_key?(:super) ? opts[:super] : false
      note = "{wj}footnote:[#{literal ? self.literal(string) : string}]"

      # it looks like asciidoctor.js makes it superscript by default
      # and shows ^ literary. Hope gem and js get behavior synced.
      superscript ? '^' << note << '^' : note
    end

    # @return [String] adoc url
    def case_id_url(id)
      "https://tcms.engineering.redhat.com/case/#{id}[#{id}]"
    end

    def diff_report(current_backup_file)
      old_backup_hash = get_old_backup(current_backup_file)
      if old_backup_hash
        new_backup_hash = load_yaml_from_gz(current_backup_file)
        report = diff_backups(old_backup_hash, new_backup_hash)
        diff_report_send(report)
      else
        # seems like we don't want to perform a report this time
      end
    end

    # @param [Hash] plans - a hash containing the backed-up plans
    # @return [String] automation ratio
    def automation_ratio(plans)
      total = 0
      auto = 0

      plans.each do |plan_id, cases|
        cases.each do |c|
          if c["case_status"] == "CONFIRMED"
            total = total + 1
            auto = auto + 1 if c["is_automated"] > 0
          end
        end
      end

      ratio = (auto.to_f / total * 100).round(1)
      return "| total: #{total} | auto: #{auto} | ratio: #{ratio}% |"
    end

    def find_non_marked_auto(case_ids, backup_struct)
      case_ids.map! { |cid| Integer(cid) }

      bad = []
      not_found = case_ids.reject do |cid|
        backup_struct.find do | plan, cases |
          cases.find do |case_hash|
            if case_hash["case_id"] == cid
              bad << case_hash unless case_hash["is_automated"] > 0
              true
            end
          end
        end
      end

      puts "not found cases: #{not_found.size}"
      puts "not marked auto cases with scenarios: #{bad.size}"
      puts "list: #{bad.map{|c|c["case_id"]}.join(",")}"
    end

    def find_case_in_backup(case_id, backup_struct)
      case_id = Integer(case_id)
      case_hash = nil
      backup_struct.find do | plan, cases |
        cases.find do |c_hash|
          case_hash = c_hash if c_hash["case_id"] == case_id
        end
      end
      return case_hash
    end

    def load_yaml_from_gz(gz)
      loaded = nil
      Zlib::GzipReader.open(gz) do |f|
        class << f
          def external_encoding
            Encoding::UTF_8
          end
        end
        loaded = YAML.load(f, gz)
      end
      return loaded
    end

    def get_old_backup(filename)
      # old file copied to workspace by jenkins

      old_backup_file = "old_" + filename

      if File.exist?(old_backup_file)
        file = old_backup_file
      elsif File.exist?("../#{old_backup_file}")
        file = "../#{old_backup_file}"
      else
        return
      end

      return load_yaml_from_gz(file)
    end

    def diff_report_send(report)
      # email done by jenkins
      File.write(BACKUP_DIFF_PREFIX + ".adoc", report)

      # generate HTML
      #doc = Asciidoctor.load(report)
      # older asciidoctor does not support rendering to file
      #File.write(
      #  BACKUP_DIFF_PREFIX + '.html',
      #  doc.render(:header_footer => true)
      #)
      Asciidoctor.render(report, :safe => :unsafe, :to_file => BACKUP_DIFF_PREFIX + '.html')
    end

    def compare_tcms_to_code(backup_file)
      backup_struct = load_yaml_from_gz(backup_file)
      diff_cases = {}
      backup_struct.values[0].each do |tcms_case|
        #Only check for 'CONFIRMED' cases in TCMS.
        if tcms_case['case_status'] == 'CONFIRMED'
          #Initialize arrays for missing tags. tcms_missing means that a tag
          #exists in a scenario but not TCMS. scenario_missing means that a
          #tag exists in TCMS, but not the scenario file.
          case_id = tcms_case["case_id"]
          tcms_missing = {case_id => []}
          scenario_missing = {case_id => []}
          #Get TCMS tags from the backup yml file
          tcms_tags = {case_id => tcms_case["tag"]}
          #Get Scenario tags from the source code
          #The 'metadata' key stores the author, case_id, and bug_id if they appear
          #to be used later if necessary.
          scenario_tags = {case_id => [], "metadata" => []}
          #Check for TCMS/source code automation mismatch
          auto_mismatch = {case_id => []}
          begin
            script_field = JSON.parse(tcms_case["script"])
            feature_file, scenario = script_field['ruby'].split(":")
          rescue => e
            puts "\e[0;31mError in case #: #{case_id}, #{e.message}, issue with JSON in script field.\e[0m"
            next
          end
          if script_field.keys.include? "ruby"
            if tcms_case['is_automated'] != 1
              auto_mismatch[case_id] = "mismatch"
            end
            begin
              feature = IO.readlines("#{ENV['CUCUSHIFT_HOME']}/features/#{feature_file}")
            rescue => e
              puts "\e[0;31mError in case #: #{case_id}, #{e.message}\e[0m"
              next
            end
            #Return the index of the feature file array where scenario is found
            index = feature.index{|scenario_index| scenario_index =~ /^\s*(?:Scenario(?: Outline)?:\s*#{Regexp.escape(scenario)})$/}
            if index == nil
              puts "\e[0;31mError in case #: #{case_id}, scenario name not found in file\e[0m"
              next
            end
            #Return all tags from the scenario file, if any.
            #TODO: retrieve orphaned tags at the top of the full feature file
            feature[0,index].reverse.each do |line|
              if line !~ /@/
                break #stop looking for tags if none immediately above scenario name
              else
                start_with = line.delete("\n").strip
                #Check if a tag begins with a comment, (#@author, #@case_id, etc),
                #if so, save it to the 'metadata' field of the scenario tags hash.
                if start_with !~ /#/
                  #Check for inline tags, like "@devenv @sequential"
                  start_with = start_with.split(/\s+/).map{|t| t[1..-1]}
                  start_with.each {|tag| scenario_tags[case_id].push tag}
                else
                  scenario_tags["metadata"].push start_with
                  next #Don't add metadata tags twice
                end
              end
            end
          end
          #Only push tcms tags if there are mismatched scenario tags
          if scenario_tags[case_id] != nil
            #Only list TCMS tag descrepancies if they are one of the "canonical" tags
            canonical_tags = ["devenv","destructive","aggressive","sequential","migration"]
            scenario_tags[case_id].each do |scenario_tag|
              if not tcms_tags[case_id].include? scenario_tag and canonical_tags.include? scenario_tag
               tcms_missing[case_id].push scenario_tag unless scenario_tag =~ /user/
              end
            end
            tcms_tags[case_id].each do |tcms_tag|
            if not scenario_tags[case_id].include? tcms_tag and canonical_tags.include? tcms_tag
                scenario_missing[case_id].push tcms_tag
              end
            end
          end
          diff_cases[case_id] = [{"tcms_missing" => tcms_missing[case_id]}, {"scenario_missing" => scenario_missing[case_id]},{"auto_mismatch" => auto_mismatch[case_id]}]
          #Remove cases with empty sets, i.e. no difference between TCMS and the scenario code.
          diff_cases.delete(case_id) if tcms_missing[case_id].empty? and scenario_missing[case_id].empty? and auto_mismatch[case_id].empty?
        end
      end
      diff_cases
      tcms_to_code_report(diff_cases)
    end

    def tcms_to_code_report(diff_cases)
      tcms_src_diff_report = "= TCMS vs. Scenario Code Diff Report" + "\n" * 2
      diff_cases.each do |case_discrepancy|
        case_id = case_discrepancy[0]
        tcms_missing = case_discrepancy[1][0]
        scenario_missing = case_discrepancy[1][1]
        auto_mismatch = case_discrepancy[1][2]
        #Print the case number as header
        tcms_src_diff_report << "https://tcms.engineering.redhat.com/case/#{case_id}[#{case_id}]: "
        if not tcms_missing["tcms_missing"].empty?
          tcms_src_diff_report << "TCMS missing: "
          tcms_src_diff_report << tcms_missing["tcms_missing"].join(", ")
          tcms_src_diff_report << "; "
        end
        if not scenario_missing["scenario_missing"].empty?
          tcms_src_diff_report << "Scenario missing: "
          tcms_src_diff_report << scenario_missing["scenario_missing"].join(", ")
          tcms_src_diff_report << "; "
        end
        if not auto_mismatch["auto_mismatch"].empty?
          tcms_src_diff_report << "Auto mismatch"
        end
        tcms_src_diff_report <<  "\n" * 2
      end
      #Generate the report, both in .adoc and .html format
      File.write("tcms_src_diff_report.adoc", tcms_src_diff_report)
      Asciidoctor.render(tcms_src_diff_report, :safe => :unsafe, :to_file => 'tcms_src_diff_report.html')
      puts "\e[0;32m Report successfully generated. \e[0m"
    end
  end
end

if __FILE__ == $0
  CucuShift::TcmsBackup.new.run
end
