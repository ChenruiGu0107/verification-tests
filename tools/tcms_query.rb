#!/usr/bin/env ruby
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib")

"""
Utility to query a TCMS run much like the Chrome extension

use -i to specify the testrun id
use -f to filter the output for only a specific user@redhat.com
use -e to exclude displaying those that have ruby scripts and have 'AUTO' labeled already
use -a to query for ruby testcases that have 'Script' filed with 'ruby' and is CONFIRMED
use --help to see usage information

Examples:
$ ./query_tcms.rb -i 130186 -f pruan@redhat.com
 - will filter out the results only with author pruan@redhat.com
 - if you leave out the -f portion it will return all caseruns
"""
require 'tcms/tcms'
require 'text-table'
require 'optparse'
require 'json'
require 'io/console' # for reading password without echo
require 'time'

def print_report(options)
  status_lookup = {
    1 => 'IDLE',
    2 => 'PASSED',
    3 => 'FAILED',
    4 => 'RUNNING',
    5 => 'PAUSED',
    6 => 'BLOCKED',
    7 => 'ERROR',
    8 => 'WAIVED'}

  testrun_id = options.testrun_id
  author_filter = options.author if options.author
  outcome_filter = options.outcome if options.outcome
  tcms =  options.tcms
  res  = tcms.get_run_cases(testrun_id)
  table = Text::Table.new
  table.head = ['caserun_id', 'case_id', 'summary', 'status', 'notes']
  regex = /(automated)? by\s(\w+)?/
  cases = []
  res.each do |caserun|
    auto_by = caserun['notes'].match(regex)[2] if caserun['notes'].match(regex)
    row = [caserun['case_run_id'], caserun['case_id'], caserun['summary'].strip[0..50], caserun['case_run_status'], auto_by]
    next if author_filter && author_filter != auto_by
    next if outcome_filter && outcome_filter != caserun['case_run_status']
    table.rows << row
  end
  puts table
  puts "Total: #{table.rows.count}\n"
  if options.create_run
    table.rows.each do |row|
      cases.push(row[1])
    end
  end
  return cases
end
#########################################################################
# search for scenario tags of a scenario
# search backward for the line Scenario or Scenario Outline.
# Once we find the indicator line we keep searching back looking for
# @tagX lines skipping blank lines; we stop on any other line or line 0
#########################################################################
def get_scenario_tags(line_number, file_contents)
  tags = []
  original_line_number = line_number
  scenario_regex = /^\s*Scenario(?: Outline)?:/
  # we only add the tags if they are one or more of the following groups
  # https://mojo.redhat.com/docs/DOC-935729
  valid_tags_to_be_added = ['@devenv', '@destructive', '@aggressive', '@sequential']
  # goes back searching for Scenario line
  while line_number > 0
    line = file_contents[line_number]
    break if line.match(scenario_regex)
    line_number -= 1
  end
  unless line.match(scenario_regex)
    raise "could not find scenario line; are line number and syntax correct?"
  end
  # now go backwards getting scenario tags until we hit line where no more tags
  # can be found
  while true
      line_number -= 1
      if line_number <= 0
        raise "syntax error? we reached beginning of file but should have stopped already at most on the Feature line"
      end

      line = file_contents[line_number].strip()
      case line
      when ""
        # skip empty lines
        next
      when /^@/
        t = line.split(/\s+/)
        unless t.all? {|w| w.start_with? "@"}
          raise "found invalid tag line: #{line}"
        end
        tags.concat t
      else
        # we found non-blank line that is not tags so we stop
        break
      end
  end
  return ( tags & valid_tags_to_be_added).map{|t| t[1..-1]}.join(',')
end

def get_scenario_outline_info(arg_values, line_number, file_contents)
  original_line_number = line_number
  scenario_outline_info = {}
  # goes back searching for a line that contains Scenario Outline:
  while line_number > 0 do
    if file_contents[line_number].include? 'Scenario Outline:'
      scenario_description = file_contents[line_number].split("Scenario Outline:")[1].strip()
      scenario_outline_info[:description] = scenario_description
      break
    else
      line_number -= 1
    end
  end
  # now get the Arguements field by looking for 'Examples:', the line after that is the hash key to the Arguments field
  arg_hash = {}
  while line_number < original_line_number do
    line = file_contents[line_number]
    if line.match(/\s+\Examples:/)
      # skip lines that are not part of the 'Example:' table
      while line_number < original_line_number do
        if file_contents[line_number+1].match(/\s+\|/)
          break
        else
          line_number += 1
        end
      end
      arg_hash_keys = file_contents[line_number+1].match(/\s+\|(.*)\|/)[1].split('|').map! { |n| n.strip }
      arg_hash_keys.each_with_index do |value, index|
        arg_hash[value] = arg_values[index]
      end
      scenario_outline_info[:arg_field] = arg_hash
      break
    else
      line_number += 1
    end
  end
  return scenario_outline_info
end

def report_auto_testcases_by_author(options)
  tcms = options.tcms
  table = Text::Table.new
  table.head = ['case_id', 'summary', 'author']
  regex = /(automated by)\s(\w+)?/
  script_pattern = "\"ruby\""
  cases = []
  authors = {}
  auto_case_total = 0
  res = tcms.filter_cases()
  total_cases = res.count
  res.each do | testcase|
    # we only care about script field that's not empty (meaning it's automated)
    if not testcase['script'].nil?
      if (testcase['script'].include? script_pattern and testcase['case_status'] == 'CONFIRMED')
        auto_case_total += 1
        auto_by = testcase['notes'].match(regex)[2] if testcase['notes'].match(regex)
        auto_by = "unknown" if auto_by.nil?
        if authors.keys().include? auto_by
          authors[auto_by] += 1
        else
          authors[auto_by] = 1
        end

        #authors.push(auto_by) unless authors.include? auto_by
        if options.by_author
          if auto_by ==  options.author
            table.rows << [testcase['case_id'], testcase['summary'].strip[0..20], auto_by]
          end
        end
      end
    end
  end
  print table
  table_sum = Text::Table.new
  table_sum.head = ['author', 'testcases']
  authors.each do |a, c|
    table_sum.rows << [a, c]
  end
  print table_sum
  print "Automated a total of #{auto_case_total} out of #{total_cases} possible testcases for a ratio of #{(auto_case_total.to_f/total_cases * 100).round(2)}%"
end


##  query testplan and return all testcases with script field that has
#   "auto" and 'ruby' in the script section
def report_auto_testcases(options)
  tcms = options.tcms
  table = Text::Table.new
  table.head = ['case_id', 'summary', 'ruby script', 'auto_by']
  script_pattern = "\"ruby\""
  cases = []
  res = tcms.filter_cases()
  total_cases = res.count
  ruby_scripts_count = 0
  ruby_cases = []
  need_update = 0
  regex = /(automated)? by\s(\w+)?/
  res.each do | testcase |
    if not testcase['script'].nil?
      if (testcase['script'].include? script_pattern and testcase['case_status'] == 'CONFIRMED')
        ruby_scripts_count += 1
        begin
          script = JSON.parse(testcase['script'])
        rescue Exception => e
          print "Error parsing testcase #{testcase["case_id"]} entry in TCMS, please check for formatting" + "\n" + e.message
        end

        auto_by = testcase['notes'].match(regex)[2] if testcase['notes'].match(regex)
        if options.exclude_auto
          if testcase['is_automated'] == 0
            need_update += 1
            table.rows << [testcase['case_id'], testcase['summary'].strip[0..20],
                           script['ruby'].strip[0..40], auto_by] #testcase['is_automated']]
          end
        else
          raise "bad case #{testcase['case_id']}" unless script.kind_of?(Hash)
          table.rows << [testcase['case_id'], testcase['summary'].strip[0..20],
                         script['ruby'].strip[0..40], auto_by] #testcase['is_automated']]

        end
        ruby_cases.push(testcase['case_id'])
      end
    end
  end
  puts table
  table.rows.each do |row|
    cases.push(row[0])
  end

  puts "Total: #{ruby_scripts_count} out of possible #{total_cases}, need_update: #{need_update}"

  return cases
end

def update_notes(options)
  if options.cases.nil?
    puts "You need to specify at least one testcase id"
    return
  end
  time_stamp = "#{Time.now().strftime("%Y-%m-%d")}"
  notes =  options.notes + " " + time_stamp
  cases = options.cases.split(',')
  tcms  = options.tcms
  tcms.update_testcases(cases, {"notes" => notes})
end

def get_cucushift_home
  ENV['CUCUSHIFT_HOME'] || File.dirname(File.dirname(__FILE__))
end

# generic update script field of TCMS case
# usage example:
# Scenario
# tcms_query.rb -c 295234 -s "features/rest/add_app.feature:78"
# Scenario Outline
# tcms_query.rb -c 259977 -s "features/rest/add_app.feature:41"
def update_script(options)
  tcms  = options.tcms
  path, line_number = options.script.split(':')
  raise "A line number must be specified" unless line_number
  target_line_number = line_number.to_i
  scenario_description = nil

  file_contents = File.readlines(File.join(get_cucushift_home, path))
  target_line = file_contents[target_line_number - 1]
  if target_line.include? 'Scenario:'
    scenario_description = target_line.split("Scenario:")[1].strip()
  elsif target_line.include? 'Scenario Outline:'
    scenario_description = target_line.split("Scenario Outline:")[1].strip()
  elsif (res = target_line.match(/\s+\|(.*)\|/))
    # res[1] is the arg , now we need to search back until to get the Senario Outline line
    arg_values = res[1].split('|').map { |a| a.strip }
    scenario_info = get_scenario_outline_info(arg_values, target_line_number-1, file_contents)
    scenario_description = scenario_info[:description]
    tcms_arg_field = scenario_info[:arg_field].to_json
  else
    raise 'Can not find Scenario or Scenario Outline target line, please check the line number specified for the file is correct'
  end
  # for tcms we need to strip out the features/ part of the arguement
  path = path[9..path.length]
  ruby_script = "#{path}:#{scenario_description}"
  tcms_script_field =  {"ruby"=>ruby_script}.to_json
  tags = get_scenario_tags(line_number.to_i - 1, file_contents)
  tcms.add_testcase_tags(options.cases, tags) unless tags == ""

  if options.notes
    time_stamp = "#{Time.now().strftime("%Y-%m-%d")}"
    notes =  options.notes + " " + time_stamp
    tcms.update_testcases(options.cases, {"script"=>tcms_script_field, "arguments"=>tcms_arg_field, "is_automated"=>1, "notes"=> notes})
  else
    tcms.update_testcases(options.cases, {"script"=>tcms_script_field, "is_automated"=>1, "arguments"=>tcms_arg_field})
  end
end

if __FILE__ == $0
  options = OpenStruct.new

  OptionParser.new do |opts|
    opts.banner = "Usage: bin/query_tcms.rb [options]"
    opts.separator("Options")
    opts.on('--ping', "exit with error if tcms cannot be reached") do
      options.ping=true
    end
    opts.on('-a', '--autocases', "query for all cases that has 'Script' entry and have 'ruby' as key") do
      options.get_auto=true
    end
    opts.on('-b', '--by_author', "query for all cases that has is CONFIRMED, and report it by author name") do
      options.by_author=true
    end
    opts.on('-o', '--outcome [testcase run outcome]', String, "the output to filter by per status_lookup table") do |outcome|
      options.outcome = outcome
    end
    opts.on('-e', '--exclude_auto', "exclude displaying those that have ruby scripts and marked as AUTO already") do
      options.exclude_auto=true
    end
    opts.on('-i', '--testrun [testrun_id]', Integer, "The id of the test run") do |id|
      options.testrun_id = id
    end
    opts.on('-f', '--filter <auto_by_author_email>', String, "The email of the automation writer") do |author|
      options.author = author
    end
    # this option is used mainly to update the Notes: field in TCMS
    opts.on('-n', '--notes <text_to_be_placed_in_notes>', String, "Notes you want to enter into the testcase") do |notes|
      options.notes = notes
      options.update_tcms = true
    end
    opts.on('-s', '--script <script_and_line_number>', String, "") do | script|
      options.script = script
      options.update_tcms = true
    end
    opts.on('-c', '--cases <csv of case_ids to be update>', String, "csv of testcase ids that you wish to update") do |cases|
      options.cases = cases
    end
    opts.on('-p', '--plan_id [testplan_id]', Integer, "The id of the test plan, default (v3:14587 v2:4962) plan id will be used if none is given") do |id|
      options.plan = id
    end
  end.parse!
  tcms = CucuShift::TCMS.new(options.to_h)

  options.tcms = tcms
  cases = []
  if options.get_auto
    cases = report_auto_testcases(options)
  elsif options.ping
    puts tcms.version.to_s
    exit 0
  elsif options.update_tcms
    update_notes(options) if options.notes
    update_script(options) if options.script
  elsif options.by_author
    report_auto_testcases_by_author(options)
  else
    cases = print_report(options)
  end
end
