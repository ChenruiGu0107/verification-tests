require 'base_helper'
require 'http'
require 'lolsoap'

module CucuShift
  class Polarion
    include Common::Helper

    PROJECT  = "ProjectWebService"
    BUILDER  = "BuilderWebService"
    PLANNING = "PlanningWebService"
    SECURITY = "SecurityWebService"
    SESSION  = "SessionWebService"
    TRACKER  = "TrackerWebService"
    TEST     = "TestManagementWebService"

    def initialize(options={})
      svc_name = options[:service_name] ||
                 ENV['POLARION_SERVICE_NAME'] ||
                 :polarion

      unless conf[:services, svc_name.to_sym]
        raise "No default options detected, please makse sure the " +
          "PRIVATE_REPO is cloned into your repo or ENV CUCUSHIFT_PRIVATE_DIR" +
          " is defined"
      end

      @options = conf[:services, svc_name.to_sym].merge options

      ## try to obtain user/password in all possible ways
      @options[:user] = ENV['POLARION_USER'] if ENV['POLARION_USER']
      @options[:password] = ENV['TPOLARION_PASSWORD'] if ENV['POLARION_PASSWORD']
      unless @options[:user]
        Timeout::timeout(120) {
          STDERR.puts "Polarion user (timeout in 2 minutes): "
          @options[:user] = STDIN.gets.chomp
        }
      end
      unless @options[:password]
        STDERR.puts "Polarion Password: "
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

      raise "specify POLARION user and password" unless @options[:user] && @options[:password] && !@options[:user].empty? && !@options[:password].empty?

      login # can be removed but prefer to fail early if cannot login
    end

    # convert headers hash to header names suitable for rest-client
    private def headers_sym(hash)
      Collections.map_hash(hash) { |k, v| [k.tr('-','_').downcase.to_sym, v] }
    end

    private def opts
      @options
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

    # @return [String] wsdl XML for particular type of requests
    private def wsdl(type)
      return @wsdl_cache[type] if (@wsdl_cache ||= {})[type]

      @wsdl_cache[type] = CucuShift::Http.request(
        method: :get,
        url: "#{opts[:wsdl_base_url]}/#{type}?wsdl",
        raise_on_error: true,
        **ssl_opts
      )[:response]
    end

    # @return [LolSoap::Client]
    private def client(type)
      return @client_cache[type] if (@client_cache ||= {})[type]

      @client_cache[type] = LolSoap::Client.new(wsdl(type))
    end

    # execute a SOAP request
    # @return [LolSoap::Response] with monkey patched #raw method
    # @yield [body_builder] to set request params as with request.body.do |b|
    # @note all SOAP requests use the POST method
    private def do_request(type, op, login: true)
      raise "you need to supply block" unless block_given?

      cl = client(type)
      req = cl.request(op)
      yield req.body # req.body {|b| yield b}
      req.header.__node__ << login() if login
      raw = Http.request(
                          method: :post,
                          url: req.url,
                          headers: headers_sym(req.headers),
                          payload: req.content,
                          raise_on_error: true,
                          **ssl_opts
                        )
      res = cl.response(req, raw[:response])

      res.instance_variable_set(:@raw, raw[:response])
      def res.raw
        @raw
      end

      return res
    end

    # login should actually perform login only if needed (no session or expired)
    # @return [String, Nokogiri::XML::NodeSet, Nokogiri::XML::Node] that is
    #   only SessionID header so far
    def login
      # TODO: check if session expired if possible
      @auth_header ||= do_login
    end

    ############ REQUEST HELPERS BELOW ############

    # execute login unconditionally and set session header if successful
    # @return [String, Nokogiri::XML::NodeSet, Nokogiri::XML::Node] that is
    #   only SessionID header so far
    def do_login
      res = do_request(SESSION, 'logIn', login: false) do |b|
        b.userName opts[:user]
        b.password opts[:password]
      end
      # dup because of https://github.com/sparklemotion/nokogiri/issues/1200
      @auth_header = res.doc.xpath("//*[local-name()='sessionID']")[0].dup
    end

    def get_self
      project.get_user(user_id: opts[:user])
    end

    def logout
      res = do_request(SESSION, 'endSession') {}
      @auth_header = nil
      return res
    end

    def begin_transaction
      do_request(SESSION, 'beginTransaction') {}
    end

    # Check if there is a explicit transaction (started with beginTransaction)
    #   for the current session.
    # @return [Hash] s.body_hash["transactionExistsReturn"] == Boolean
    # @raise RestClient::InternalServerError: 500 Internal Server Error when
    #   current session has no transaction started
    def transaction_exists
      do_request(SESSION, "transactionExists") {}
    end

    # param rollback [Boolean]
    def end_transaction(rollback)
      do_request(SESSION, 'endTransaction') do |b|
        b.rollback rollback
      end
    end

    ################### GENERATE ALL METHODS #####################
    module Generated
      def test
        @test_methods ||= MethodHolder.new(self, self.class.const_get(__method__.upcase))
      end
      def planning
        @planning_methods ||= MethodHolder.new(self, self.class.const_get(__method__.upcase))
      end
      def security
        @security_methods ||= MethodHolder.new(self, self.class.const_get(__method__.upcase))
      end
      def builder
        @builder_methods ||= MethodHolder.new(self, self.class.const_get(__method__.upcase))
      end
      def tracker
        @tracker_methods ||= MethodHolder.new(self, self.class.const_get(__method__.upcase))
      end
      def project
        @project_methods ||= MethodHolder.new(self, self.class.const_get(__method__.upcase))
      end
    end

    include Generated

    class MethodHolder
      include Common::BaseHelper
      def initialize(mother, type)
        # generate a method for each supported operation with the accepted
        #   parameters as a hash or keyword arguments; some consistency checks
        @op_map = {}
        mother.send(:client, type).wsdl.operations.each do |op_name, op|
          elements = op.input.body.type.elements
          if elements.size != 1
            raise "#{type}::#{op_name} doesn't have exactly one body element"
          end
          unless elements[op_name]
            ## do we need to ensure op_name == element_name at all?
            raise "#{type}::#{op_name} no body element named #{op_name}"
          end

          body_params = {}
          elements.values[0].type.elements.keys.each do |key|
            body_params[camel_to_snake_case(key).to_sym] = key
          end
          op_snake = camel_to_snake_case(op_name).to_sym
          @op_map[op_snake] = body_params.keys

          # define method in the singleton class
          (class << self; self; end).class_eval do
            define_method(op_snake) do |**params|
              extra_params = params.keys - body_params.keys
              unless extra_params.empty?
                raise "unknown polarion #{op_snake} parameters #{extra_params}"
              end

              return mother.send(:do_request, type, op_name) do |builder|
                params.each do |param, value|
                  # using internal api method as #send and #method are removed
                  builder.__tag__(body_params[param], value)
                end
              end
            end
          end
        end

        (class << self; self; end).class_eval do
          define_method(:_op_map) { @op_map }
        end
      end
    end
  end
end
