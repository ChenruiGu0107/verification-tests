# frozen_string_literal: true

module CucuShift
  module PolarShift
    class Request
      include Common::Helper

      def initialize(options={})
        svc_name = options[:service_name] ||
                   ENV['POLARSHIFT_SERVICE_NAME'] ||
                   :polarshift

        if conf[:services, svc_name.to_sym]
          @options = conf[:services, svc_name.to_sym].merge options
        else
          @options = options.dup
        end

        @options.merge! load_env

        unless @options[:user]
          Timeout::timeout(120) {
            STDERR.puts "PolarShift user (timeout in 2 minutes): "
            @options[:user] = STDIN.gets.chomp
          }
        end
        unless @options[:password]
          STDERR.puts "PolarShift Password: "
          @options[:password] = STDIN.noecho(&:gets).chomp
        end

        # make sure ca_paths are absolute
        if @options[:ca_file]
          @options[:ca_file] = expand_private_path(@options[:ca_file],
                                                   public_safe: true)
        elsif @options[:ca_path]
          @options[:ca_path] = expand_private_path(@options[:ca_path],
                                                   public_safe: true)
        end

        unless @options[:user] &&
               @options[:password] &&
               !@options[:user].empty? &&
               !@options[:password].empty?
          raise "specify POLARSHIFT user and password"
        end
      end

      # put all vars POLARSHIFT_* into a hash, e.g.
      # export POLARSHIFT_BASE_URL='https://...'
      # export POLARSHIFT_USER=...
      # export POLARSHIFT_PASSWORD=...
      private def load_env
        # get any PolaShift configuration from environment
        opts = {}
        vars_prefix = "POLARSHIFT_"

        ENV.each do |var, value|
          if var.start_with? vars_prefix
            opt = var[vars_prefix.length..-1].downcase.to_sym
            opts[opt] = value
          end
        end

        return opts
      end

      private def opts
        @options
      end

      private def base_url
        @base_url ||= opts[:base_url]
      end

      private def ssl_opts
        res_opts = {verify_ssl: OpenSSL::SSL::VERIFY_PEER}
        if opts[:ca_file]
          res_opts[:ssl_ca_file] = opts[:ca_file]
        elsif opts[:ca_path]
          res_opts[:ssl_ca_path] = opts[:ca_path]
        end

        return res_opts
      end

      private def common_opts
        {
          **ssl_opts,
          user: opts[:user],
          password: opts[:password],
          headers: {content_type: :json, accept: :json}
        }
      end

      def get_run(project_id, run_id, with_cases: "automation")
        params = with_cases ? {test_cases: with_cases} : {}
        Http.request(
          method: :get,
          url: "#{base_url}project/#{project_id}/run/#{run_id}",
          params: params,
          raise_on_error: false,
          **common_opts
        )
      end

      # get run with retries and raises on failure
      def get_run_smart(project_id, run_id, with_cases: "automation", timeout: 360)
        success = wait_for(timeout, interval: 15) {
          res = get_run(project_id, run_id, with_cases: with_cases)
          if res[:exitstatus] == 200
            return JSON.load(res[:response])["test_run"]
          elsif res[:exitstatus] == 202
            next
          else
            raise %Q{got status "#{res[:exitstatus]}" getting run "#{run_id}" from project "#{project_id}":\n#{res[:response]}}
          end
        }
        raise %Q{could not obtain run "#{run_id}" from project "#{project_id} within timeout of "#{timeout}" seconds}
      end

      # @param case_ids [Array<String>] test case IDs
      def get_cases(project_id, case_ids)
        Http.request(
          method: :get,
          url: "#{base_url}project/#{project_id}/test-cases",
          params: {"case_ids" => case_ids},
          raise_on_error: false,
          **common_opts
        )
      end

      def get_cases_smart(project_id, case_ids, timeout: 360)
        res = get_cases(project_id, case_ids)
        if res[:exitstatus] == 200
          return JSON.load(res[:response])["test_cases"]
        elsif res[:exitstatus] == 202
          wait_op(url: JSON.load(res[:response])["operation_result_url"],
                  timeout: timeout)
          res = get_cases(project_id, case_ids)
          if res[:exitstatus] == 200
            return JSON.load res[:response]
          else
            # raise at end of method
          end
        end
        raise %Q{got status "#{res[:exitstatus]}" getting cases "#{case_ids}" from project "#{project_id}":\n#{res[:response]}}
      end

      # refresh PolarShift cashe of test cases
      def refresh_cases(project_id, case_ids)
        Http.request(
          method: :put,
          url: "#{base_url}project/#{project_id}/test-cases",
          payload: {case_ids: case_ids}.to_json,
          raise_on_error: false,
          **common_opts
        )
      end

      def refresh_cases_wait(project_id, case_ids, timeout: 360)
        res = refresh_cases(project_id, case_ids)
        if res[:exitstatus] == 202
          wait_op(url: JSON.load(res[:response])["operation_result_url"],
                timeout: timeout)
        else
          raise %Q{got status "#{res[:exitstatus]}" refreshing cases "#{case_ids}" in project "#{project_id}":\n#{res[:response]}}
        end
      end

      # @param updates [Array<Hash>]
      def update_caseruns(project_id, run_id, updates)
        unless Array === updates
          updates = [updates]
        end
        Http.request(
          method: :post,
          url: "#{base_url}project/#{project_id}/run/#{run_id}/records",
          payload: {case_records: updates}.to_json,
          raise_on_error: false,
          **common_opts
        )
      end

      # checks result of a PolarShift async operation (like getting test run)
      # @return [Hash] where "status" key denotes status
      # @raise on request failure
      def check_op(url: nil, id: nil)
        raise "specify operation URL or id" unless url || id
        url ||= "#{base_url}/polarion/request/#{id}"
        res = Http.request(
          method: :get,
          url: url,
          raise_on_error: false,
          **common_opts
        )

        unless res[:success]
          raise "status #{res[:exitstatus]} trying to obtain result status:\n#{res[:response]}"
        end

        return JSON.load(res[:response])["polarion_request"]
      end

      def wait_op(url: nil, id: nil, timeout: 360)
        res = nil
        success = wait_for(timeout, interval: 15) {
          res = check_op(url: url, id: id)
          case res["status"]
          when "done"
            return
          when "queued", "running"
            next
          when "failed"
            raise "PolarShift operation failed:\n#{res["error"]}"
          else
            raise "unknown operation status #{res["status"]}"
          end
        }
        unless success
          raise "timeout waiting for operation, still status: #{res["status"]}"
        end
      end
    end
  end
end
