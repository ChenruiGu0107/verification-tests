# support library for using RHT JIRA
lib_path = File.expand_path(File.dirname(__FILE__))
unless $LOAD_PATH.any? {|p| File.expand_path(p) == lib_path}
  $LOAD_PATH.unshift(lib_path)
end
require 'jira'
require 'common'



module CucuShift
  class Jira
    include Common::Helper

    def initialize(options={})
      raise "No default options detected, please makse sure the PRIVATE_REPO \
      is cloned into your repo or ENV CUCUSHIFT_PRIVATE_DIR is defined" if default_opts.nil?
      @options = default_opts.merge options

      ## try to obtain user/password in all possible ways
      @options[:user] = ENV['JIRA_USER'] if ENV['JIRA_USER']
      @options[:password] = ENV['JIRA_PASSWORD'] if ENV['JIRA_PASSWORD']
      unless @options[:user]
        Timeout::timeout(120) {
          STDERR.puts "JIRA user (timeout in 2 minutes): "
          @options[:user] = STDIN.gets.chomp
        }
      end
      unless @options[:password]
        STDERR.puts "JIRA Password: "
        @options[:password] = STDIN.noecho(&:gets).chomp
      end
      ## set logger
      @logger = @options[:logger] || logger
      raise "specify JIRA user and password" unless @options[:user] && @options[:password] && !@options[:user].empty? && !@options[:password].empty?
    end

    def client
      return @client if @client
      options = {
        :username => @options[:user],
        :password => @options[:password],
        :site     => @options[:site],
        :context_path => @options[:context_path],
        :auth_type => @options[:auth_type],
        :use_ssl => true,
        :ca_path => expand_private_path(@options[:ca_path],
                                        public_safe: true),
        :read_timeout => @options[:read_timeout]
      }
      @client = JIRA::Client.new(options)
    end

    ## XXX not sure if a regular user can delete issues
    def delete_issue(issue_id)
      issue = client.Issue.find(issue_id)
      if issue.delete
        @logger.info("Issue #{issue_id} deleted successfully")
      else
        @logger.info("Failed to delete issue #{issue_id}")
      end
    end

    # @params is a hash of paramters to be created for the JIRA issue.
    # returns the save status & the issue object
    def create_issue(params)
      issue = client.Issue.build
      status = issue.save("fields"=>params)
      # call fetch to update the issue object
      @logger.error("Failed to create JIRA issue") unless status
      issue.fetch
      return status, issue
    end

    # @params is a hash containing: assignee, and testrun id in the summary
    # returns an array of matching JIRA issue, empty array otherwise.
    def find_issue_by_testrun_id(query_params)
      query = "(assignee = #{query_params[:assignee]}) AND (summary ~ run:#{query_params[:run_id]})"
      res = client.Issue.jql(query)
      return res
    end

    # returns a component object
    def get_component(comp_id)
      # Automation component has id of 11173
      return client.Component.find(comp_id)
    end

    # constuct a text str that will appear as hyperlink under JIRA
    def make_link(url, text)
      return ("[#{text}|#{url}]")
    end

    # @testcases is an array of failed testcase in a TCMS hash format.  Use
    # this method to create an issue that is targeted for jenkins run failure
    #
    # We create an issued for a user based on the testrun id.  Create an issue
    # if there is no existing issued around that testrun id (need to query
    # JIRA).  If there's an JIRA already, we just append the new infromation
    # to the 'comments' section of the existing JIRA.  This way we minimize
    # the amount of JIRA issued to the user.
    #
    def create_failed_testcases_issue(testcases)
      query_params = {
        :assignee => testcases[0]['auto_by'], 
        :run_id => testcases[0]['run_id']}
      # read in the config from the :tcms section
      @options[:tcms_base_url] = conf[:services, :tcms][:tcms_base_url]
      issues = find_issue_by_testrun_id(query_params)
      error_logs = ""
      testcases.each do | tc |
        tc_url = @options[:tcms_base_url] + "case/#{tc['case_id']}"
        error_logs += make_link(tc_url, tc['case_id']) + " " + make_link( tc[:log_url], 'run_log') + "\n"
      end
      if issues.count > 0
        # issue already exist, just append the run logs as comments
        issue = issues[0]
        issue.fetch('reload')  # this is needed to reload all comments
        @logger.info("JIRA issue '#{issue.key}' already exists, adding logs to comments section...")

        comment = issue.comments.build
        comment.save!(:body => error_logs)
      else
        # step 1. get the author's information
        assignee = get_user(query_params[:assignee])
        if assignee.nil?
          @logger.error("JIRA system does not have username '#{query_params[:assignee]}', assigning issue to the reporter '#{@options[:user]}'")
          assignee = get_user(@options[:user])
        end

        component_auto = get_component(@options[:component_id])
        run_url = make_link(url=(@options[:tcms_base_url] + "run/#{query_params[:run_id]}"), text=query_params[:run_id])
        error_logs = "Errors from test run #{run_url}" + "\n" + error_logs
        issue_params = {
          "summary" => "test failure from run:#{query_params[:run_id]}",
          "project" => {"id"=> @options[:project]},
          "issuetype"=>{"id"=>"1"},
          "assignee" => assignee.attrs,
          "description" => error_logs,
          "components" => [component_auto.attrs]
        }
        status, new_issue = create_issue(issue_params)
        @logger.info("Created issue #{new_issue.key} for '#{assignee}'") if status
      end
    end

    def get_user(user_name)
      user = nil
      begin
        user = client.User.find(user_name)
      rescue => e
        @logger.error("Error: #{e.to_s}")
      end
    end

    def default_opts
      return  conf[:services, :jira]
    end

    def finalize
    end
  end
end

module JIRA
  class HttpClient
    old_http_client = instance_method(:http_conn)
    define_method(:http_conn) do |url|
      h = old_http_client.bind(self).(url)
      h.ca_path = @options[:ca_path] if @options[:ca_path]
      h.ca_file = @options[:ca_file] if @options[:ca_file]
      return h
    end
  end
end
