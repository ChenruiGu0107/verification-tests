#!/usr/bin/env ruby

lib_path = File.expand_path(File.dirname(File.dirname(__FILE__)))
unless $LOAD_PATH.any? {|p| File.expand_path(p) == lib_path}
  $LOAD_PATH.unshift(lib_path)
end

require 'xmlrpc/client'
require 'json'
require 'uri'
require 'openssl'
require 'log'
require 'io/console' # for reading password without echo

require 'base_helper'

module CucuShift
  class TCMS
    include Common::BaseHelper

    [:ENABLE_NIL_PARSER, :ENABLE_NIL_CREATE, :ENABLE_MULTICALL].each do |const|
      XMLRPC::Config.send(:remove_const, const)
      XMLRPC::Config.send(:const_set, const, true)
    end
    CASE_RUN_STATUS = {'IDLE' => 1,
                       'PASSED' => 2,
                       'FAILED' => 3,
                       'RUNNING' => 4,
                       'PAUSED' => 5,
                       'BLOCKED' => 6,
                       'ERROR' => 7,
                       'WAIVED' => 8}
    CASE_STATUS = { 'PROPOSED' => 1,
                    'CONFIRMED' => 2,
                    'DISABLED' => 3,
                    'NEED_UPDATE' => 4}

    BUG_SYSTEMS = { 'BZ' => 1,
                    'JIRA' => 2}

    #mapping tags=>Integer
    @@tags = {}

    def initialize(user, password, options={})
      @options = options.dup
      @options[:user] = user if user
      @options[:password] = password if password
      @logger = @options[:logger] || Logger.new

      raise "specify TCMS user and password" unless @options[:user] && @options[:password]
    end

    def finalize
    end

    def self.get_tcms(opts={})
      if ENV['TCMS_USER']
        tcms_user = ENV['TCMS_USER']
      else
        STDERR.puts "TCMS user: "
        tcms_user = STDIN.gets.chomp
      end
      if ENV['TCMS_PASSWORD']
        tcms_pass = ENV['TCMS_PASSWORD']
      else
        STDERR.puts "TCMS Password: "
        tcms_pass = STDIN.noecho(&:gets).chomp
      end
      tcms =  CucuShift::TCMS.new(tcms_user, tcms_pass, opts)
    end

    def client
      return @client if @client
      xmlrpc_client = XMLRPC::Client.new2(@options[:xmlrpc_url],
                                          (ENV.has_key?'http_proxy')?ENV['http_proxy'].sub(/https?:\/\//,''):nil,
                                          @options[:timeout])
      if @options[:ca_file]
        xmlrpc_client.instance_variable_get("@http").ca_file = @options[:ca_file]
      elsif @options[:ca_path]
        xmlrpc_client.instance_variable_get("@http").ca_path = @options[:ca_path]
      else
        xmlrpc_client.instance_variable_get("@http").verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      xmlrpc_client.user = @options[:user]
      xmlrpc_client.password = @options[:password]

      @client = xmlrpc_client
      return xmlrpc_client
    end


    def call(method, *args)
      @logger.info("TCMS: #{method} #{args}")
      begin
        return client.call(method, *args)
      rescue => e
        @logger.error("Error: #{e.to_s}")
        # @client = nil # client automatically reconnects
      end
      raise "TCMS: Unable to call #{method}(#{args})"
    end

    def multicall(*methods)
      @logger.info("TCMS: calling #{methods.size} methods")
      return client.multicall(*methods)
    rescue => e
      @logger.error("Error: #{e.to_s}")
      raise "TCMS: ERROR calling #{methods.size} methods"
    end

    # need to run in a new thread
    def call2_async(method, *args)
      @logger.info("TCMS async: #{method} #{args}")
      noerr, ret = client.call2_async(method, *args)
      @logger.error(exception_to_string(ret)) unless noerr
      return noerr, ret
    end

    # need to run in a new thread
    def multicall2_async(*methods)
      @logger.info("TCMS async: calling #{methods.size} methods")
      noerr, ret = client.multicall2_async(*methods)
      @logger.error(exception_to_string(ret)) unless noerr
      return noerr, ret
    end

    def version
      return self.call('Version.get')
    end

    def get_testrun(testrun_id)
      return self.call('TestRun.get', testrun_id.to_i)
    end
    alias_method :get_run, :get_testrun

    # @param [Array of Integer]
    # @return [Array of TestCase]
    def get_cases2(case_ids)
      return self.call('TestCase.filter', {'case_id__in'=>case_ids})
    end
    alias_method :filter_cases_by_id, :get_cases2

    # @param [Integer]
    # @return [TestCase]
    def get_blessed_case(case_id)
      return self.call('TestCase.get', case_id.to_i)
    end
    alias get_case get_blessed_case

    def get_blessed_cases(*cases)
      return self.multicall(
        *cases.map { |case_id| ['TestCase.get', case_id.to_i] }
      )
    end

    def get_case_status(case_id)
      return self.call('TestCase.get_case_status', case_id.to_i)
    end

    def get_case_script(case_id)
      testcase = self.get_case(case_id)
      begin
        json = JSON.load(testcase['script'])
      rescue JSON::ParserError, NoMethodError
        raise "Invalid json in script field of test case #{case_id}"
      end
      if json['ruby']
        return json['ruby']
      else
        raise "No ruby script for test case #{case_id}"
      end
    end
    alias_method :get_script, :get_case_script

    # @param [Integer] the testrun ID
    # @return [Array of TestCase]
    def get_cases(testrun_id)
      testcases = self.call('TestRun.get_test_cases', testrun_id.to_i)
      testcases.each do |testcase|
        testcase['run_id'] = testrun_id.to_i
      end
      return testcases
    end

    def get_cases_by_id(case_ids)
      case_ids = [case_ids] unless case_ids.class == Array
      testcases = []
      case_ids.each do |id|
        testcases.push(self.get_case(id))
      end
      return testcases
    end
    alias_method :get_cases_by_ids, :get_cases_by_id

    def get_cases_by_tags(tag_names, plan_id=@options[:plan])
      if @@tags.empty?
        self.get_all_cases_tags(plan_id)
      end
      tag_names = [tag_names] unless tag_names.class == Array
      tag_ids = []
      tag_names.each do |tag_name|
        tag_ids.push(@@tags[tag_name])
      end

      cases = []
      tag_ids.each do |tag_id|
        testcases = self.filter_cases({'tag'=>tag_id, 'plan'=>plan_id})
        testcases.select! {|item| item['tag'].include?(tag_id) }
        # merge the arrays
        cases += testcases
      end
      # now we need to consolidate and weed out the duplicates but only if
      # multiple tags are given
      unique_case_ids = []
      unique_testcases = []
      if tag_ids.count > 1
        cases.each do |tc|
          if not unique_case_ids.include? tc['case_id']
            unique_case_ids.push(tc['case_id'])
            unique_testcases.push(tc)
          end
        end
      else
        unique_testcases = cases
      end
      return unique_testcases
    end

    def filter_cases(options={})
      options[:plan] = @options[:plan] unless options[:plan]
      options[:case_status] = CASE_STATUS['CONFIRMED'] unless options[:case_status]
      return self.call('TestCase.filter', options)
    end
    alias_method :get_cases_by_filter, :filter_cases

    def get_all_cases_tags(plan_id=@options[:plan])
      tags = self.call('TestPlan.get_all_cases_tags', plan_id)
      @@tags.clear
      tags.each do |tag|
        @@tags[tag['name']] = tag['id']
      end
      return tags
    end

    def get_tags(values)
      return self.call('Tag.get_tags', values)
    end

    def get_tag_id(tag_name)
      if @@tags.empty?
        self.get_all_cases_tags(@options[:plan])
      end
      return @@tags[tag_name]
    end

    def get_tag_name(tag_id)
      if @@tags.empty?
        self.get_all_cases_tags(@options[:plan])
      end
      @@tags.each do |name, id|
        return name if id == tag_id
      end
      return nil
    end

    def add_testcase_tags(case_ids, tags)
      return self.call('TestCase.add_tag', case_ids, tags)
    end

    def remove_testcase_tags(case_ids, tags)
      return self.call('TestCase.remove_tag', case_ids, tags)
    end

    # @return [TestCaseRun merged with TestCase]
    def get_caserun(caserun_id)
      caserun = self.call('TestCaseRun.get', caserun_id.to_i)
      testcase = self.get_case(caserun['case_id'])
      return testcase.merge(caserun)
    end

    def get_test_case_runs(testrun_id)
      testcase_runs = self.call('TestRun.get_test_case_runs', testrun_id)
    end

    # Given a testrun_id, reset all status that's not IDLE to
    # @param [Integer] testrun_id to be modified
    # @param [String] target_status, the status of the runs you are looking to change from
    # @param [String] case_status, the status that you want to set the targets to
    def reset_testrun(options)
      #testrun_id, status_to_be='IDLE', status_current=nil)
      # set all (if status.nil?) caseruns' status to IDLE
      testrun_id = options[:testrun_id]
      target_status_id = CASE_RUN_STATUS[options[:status_target]]
      testcase_runs = self.get_test_case_runs(testrun_id)
      caseruns2update = []
      testcase_runs.each do |testcase|
        if options[:status_from].nil?
          if options[:case_ids]
            if options[:case_ids].include? testcase['case_id']
              caseruns2update << testcase['case_run_id']
            end
          else
            if testcase['case_run_status_id'] != target_status_id
              caseruns2update << testcase['case_run_id']
            end
          end
        elsif options[:case_ids]
          if options[:case_ids].include? testcase['case_id']
            caseruns2update << testcase['case_run_id']
          end
        else
          # user wants to target a specific type of status to update
          if options[:status_from].include? testcase['case_run_status']
            caseruns2update << testcase['case_run_id']
          end
        end
      end
      if caseruns2update.count > 0
        update_caserun_status(caseruns2update, options[:status_target])
      else
        @logger.info("No matching caserun to update")
      end
    end

    # Get realtime case run status
    def get_caserun_status(caserun_id)
      caserun = self.call('TestCaseRun.get', caserun_id.to_i)
      return caserun['case_run_status']
    end

    # @param [Array of Integer] integers which represetns caserun_id
    # @return [{TestCaseRun+TestCase}, ...]
    def get_caseruns(caserun_ids)
      hash = {}
      # Get case runs and store them in hash
      caserun_ids = [caserun_ids] unless caserun_ids.class == Array
      case_ids = []
      caseruns = self.call('TestCaseRun.filter', {'case_run_id__in'=>caserun_ids})
      caseruns.each do |caserun|
        hash[caserun['case_id']] = caserun
        case_ids.push(caserun['case_id'])
      end
      # Get test cases and merge them to hash
      cases = self.call('TestCase.filter', {'case_id__in' => case_ids})
      cases.each do |testcase|
        hash[testcase['case_id']].merge!(testcase)
      end
      return hash.values
    end
    alias_method :get_caseruns_by_id, :get_caseruns

    def update_caserun(caserun_ids, options)
      return self.call('TestCaseRun.update', caserun_ids, options)
    end

    def update_caserun_status(caserun_ids, status)
      return self.call('TestCaseRun.update', caserun_ids,
                      {'case_run_status' => CASE_RUN_STATUS[status]})
    end

    def add_caserun_comment(caserun_ids, comment)
      return self.call('TestCaseRun.add_comment', caserun_ids, comment.to_s)
    end
    alias_method :update_caserun_comments, :add_caserun_comment

    def attach_caserun_log(caserun_id, name, url)
      return self.call('TestCaseRun.attach_log', caserun_id, name, url)
    end
    alias_method :update_caserun_testlog, :attach_caserun_log

    def detach_caserun_log(caserun_id, link_id)
      return self.call('TestCaseRun.detach_log', caserun_id, link_id)
    end

    # Detach all the logs of the caserun
    def detach_caserun_logs(caserun_id)
      caserun = self.call('TestCaseRun.get', caserun_id)
      caserun['links'].each do |link_id|
        self.detach_caserun_log(caserun_id, link_id)
      end
    end
    alias_method :detach_logs, :detach_caserun_logs

    def create_testrun(options)
      options = @options.merge(options)
      ['timeout', 'xmlrpc_url'].each do |key|
        options.delete(key)
      end
      return self.call('TestRun.create', options)
    end
    alias_method :create_run, :create_testrun

    def filter_user(options={})
      return self.call('User.filter', options)
    end

    def update_testcases(case_ids, params)
      return self.call('TestCase.update', case_ids, params)
    end

    def get_plan_info_by_name(plan_name)
      return self.call('TestPlan.filter', {"name"=> plan_name})
    end
  end
end
