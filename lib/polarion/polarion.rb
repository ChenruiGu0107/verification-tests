require 'thread'

require 'common'
require 'http'

require_relative 'hack'

module CucuShift
module Polarion
  class Connector
    include Common::Helper
    extend Common::BaseHelper

    PROJECT  = "ProjectWebService"
    BUILDER  = "BuilderWebService"
    PLANNING = "PlanningWebService"
    SECURITY = "SecurityWebService"
    SESSION  = "SessionWebService"
    TRACKER  = "TrackerWebService"
    TEST     = "TestManagementWebService"

    # for some reason don't want to use uri class here
    # this should match URL up to the host:port part
    # if unstable we can use URI(url).host = ...
    URL_HOST_MATCH = %r{^.+?://.+?(?=$|[?#/])}

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
      @options[:password] = ENV['POLARION_PASSWORD'] if ENV['POLARION_PASSWORD']
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

    def self.deep_snake(hash)
      Collections.deep_map_hash(hash) { |k,v|
        new_k = camel_to_snake_case(k).to_sym
        if Array === v
          new_v = v.map { |e| Hash === e ? deep_snake(e) : e }
        else
          new_v = v
        end
        [ new_k, new_v ]
      }
    end

    def deep_snake(hash)
      self.class.deep_snake(hash)
    end

    def new_client
      Connector.new(opts)
    end

    # can be useful to avoid interference during a transaction
    def mutex
      @mutex ||= Mutex.new
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

    private def wsdl_base_url
      opts[:wsdl_base_url]
    end

    # @return [String] wsdl XML for particular type of requests
    private def wsdl(type)
      return @wsdl_cache[type] if (@wsdl_cache ||= {})[type]

      @wsdl_cache[type] = CucuShift::Http.request(
        method: :get,
        url: "#{wsdl_base_url}/#{type}?wsdl",
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
    private def do_request(type, op, login: true, raise_faults: true,
                           sticky_session: true)
      raise "you need to supply block" unless block_given?

      cl = client(type)
      req = cl.request(op)
      yield req.body # req.body {|b| yield b}
      req.header.__node__ << auth_header if login

      unless mutex.owned?
        mutex.lock
        should_unlock = true
      end

      raw = Http.request(
        method: :post,
        url: login && sticky_session ? use_session_host(req.url) : req.url,
        headers: headers_sym(req.headers),
        payload: req.content,
        raise_on_error: false,
        **ssl_opts
      )

      if raw[:exitstatus] == 500 && raw[:response].include?(">Not authorized.<") && login && !session_safe?
        ## possibly session has expired, try to login again
        logout
        return do_request(type, op, login: true) { |b| yield(b) }
      elsif raw[:success] || raw[:exitstatus].between?(500, 599)
        res = cl.response(req, raw[:response])
      else
        raise raw[:error] rescue raise "failed to perform #{op}"
      end

      if res.fault && raise_faults
        raise PolarionCallError.new(res),
          "failed to perform #{op}, #{res.body_hash["faultstring"]}"
      end

      res.instance_variable_set(:@raw, raw[:response])
      def res.raw
        @raw
      end

      return res
    ensure
      mutex.unlock if should_unlock
    end

    private def session_checkpoint!
      @session_checkpoint = monotonic_seconds
    end

    private def session_checkpoint
      @session_checkpoint ||= 0
    end

    private def session_safe_seconds
      opts[:session_safe_seconds] || 900
    end

    # @return [Boolean] true if session is safe to assume not expired
    private def session_safe?
      monotonic_seconds - session_checkpoint < session_safe_seconds
    end

    # when API endpoint server changed by load balancer, we want to reset
    # have to investigate when that can be an issue
    # I never saw issues when getting WSDL files close after one another
    #   but saw issues after some time of inactivity and then login again
    # This method does nothing as using same host always is now implemented
    private def reset_state
      # @wsdl_cache = nil
      # @client_cache = nil
    end


    # @return [String, Nokogiri::XML::NodeSet, Nokogiri::XML::Node] that is
    #   only SessionID header so far
    def auth_header
      # TODO: check if session expired if possible
      login unless @auth_header
      @auth_header
    end

    # this methed should help when downloading wsdl not in cache and load
    #   balancer gives us WSDL file not from the server we performed auth
    #   against
    # @return [String] the same url with proto://host:port part changed to the
    #   host that was used for authentiation
    private def use_session_host(url)
      login unless @auth_host
      url.sub(URL_HOST_MATCH) { |m| @auth_host }
    end

    ############ REQUEST HELPERS BELOW ############

    # execute login unconditionally and set session header if successful
    # @return [String, Nokogiri::XML::NodeSet, Nokogiri::XML::Node] that is
    #   only SessionID header so far
    def login
      reset_state
      res = do_request(SESSION, 'logIn', login: false) do |b|
        b.userName opts[:user]
        b.password opts[:password]
      end
      session_checkpoint!

      @auth_host = res.request.url.match(URL_HOST_MATCH)[0]
      # dup because of https://github.com/sparklemotion/nokogiri/issues/1200
      @auth_header = res.doc.xpath("//*[local-name()='sessionID']")[0].dup
    end

    def get_self
      project.get_user(user_id: opts[:user])
    end

    def self_uri
      user_uri(opts[:user])
    end

    def logout(raise_on_error: false)
      session_checkpoint! # make sure we don't relogin just to logout
      return do_request(SESSION, 'endSession') {}
    rescue
      raise if raise_on_error
    ensure
      @auth_header = nil
      @auth_host = nil
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

    module UriHelpers
      def user_uri(username)
        "subterra:data-service:objects:/default/${User}#{username}"
      end
      def workitem_uri(workitem_id, project_id)
        "subterra:data-service:objects:/default/#{project_id}${WorkItem}#{workitem_id}"
      end
      def testrun_uri(testrun_id, project_id)
        "subterra:data-service:objects:/default/#{project_id}${TestRun}#{testrun_id}"
      end
      def testrun_template_uri(template_id, project_id)
        testrun_uri(template_id, project_id)
      end
      def project_uri(project_id)
        # we can get this with get_project as well
        "subterra:data-service:objects:/default/#{project_id}${Project}#{project_id}"
      end
    end

    include UriHelpers

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
        # @tracker_methods ||= MethodHolder.new(self, self.class.const_get(__method__.upcase))

        ## artificially add :id element to custom fields value; WSDL?!!
        return @tracker_methods if @tracker_methods
        @tracker_methods = MethodHolder.new(self, self.class.const_get(__method__.upcase))
        custom_field_val_sub = @tracker_methods.instance_variable_get(:@snake_map)[:create_work_item][:sub][:content][:sub][:custom_fields][:sub][:custom][:sub][:value][:sub] ||= {}
        custom_field_val_sub[:id] = {:camel=>"id"} # for enums
        custom_field_val_sub[:type] = {:camel=>"type"} # for multiline strings
        custom_field_val_sub[:content] = {:camel=>"content"} # for strings
        custom_field_val_sub[:content_lossy] = {:camel=>"contentLossy"} # for strings
        return @tracker_methods

        ## allow arbitrary structures under custom fields value
        # return @tracker_methods if @tracker_methods
        # @tracker_methods = MethodHolder.new(self, self.class.const_get(__method__.upcase))
        #@tracker_methods.instance_variable_get(:@snake_map)[:create_work_item][:sub][:content][:sub][:custom_fields][:sub][:custom][:sub][:value][:sub] = :non_validated
        # return @tracker_methods
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
        @snake_map = {}
        mother.send(:client, type).wsdl.operations.each do |op_name, op|
          elements = op.input.body.type.elements
          if elements.size != 1
            raise "#{type}::#{op_name} doesn't have exactly one body element"
          end
          unless elements[op_name]
            ## do we need to ensure op_name == element_name at all?
            raise "#{type}::#{op_name} no body element named #{op_name}"
          end

          build_mappings(@op_map, @snake_map, elements.values[0])
          op_snake = @snake_map.keys.last # used inside dyn.defined method proc

          # define method in the singleton class
          (class << self; self; end).class_eval do
            define_method(op_snake) do |**params|
              do_build = proc do |builder, snake_map, params|
                extra_params = params.keys - (snake_map || {}).keys
                unless extra_params.empty?
                  raise "unknown polarion param (somewhere deep) in op=#{op_snake}, extra parameters=#{extra_params}"
                end

                params.each do |param, value|
                  case value
                  when Hash
                    # builder.__tag__(snake_map[param][:camel]) do |b|
                    builder.__send__(snake_map[param][:camel]) do |b|
                      do_build.call(b, snake_map[param][:sub], value)
                    end
                  when Array
                    # untested
                    value.each do |v|
                      do_build.call(builder, snake_map, {param => v})
                    end
                  else
                    # using internal api method as #send and #method are removed
                    # in fact :send method should handle attr vs sub-element
                    #   automatically
                    # builder.__tag__(snake_map[param][:camel], value)
                    builder.__send__(snake_map[param][:camel], value)
                  end
                end
              end

              return mother.send(:do_request, type, op_name) do |builder|
                do_build.call(builder, @snake_map[op_snake][:sub], params)
              end
            end
          end
        end

        (class << self; self; end).class_eval do
          define_method(:_op_map) { @op_map }
        end
      end

      # builds element tree and operation/element snake/camel mapping
      # @param element [LolSoap::WSDL::Element]
      # @param type_rec [Hash] yes, we have recursive WSDL types, at least
      #   `document` that has a `branched_from` el. from same type
      # @return undefined
      private def build_mappings(el_tree, snake_map, element, type_rec = {})
        el_snake = camel_to_snake_case(element.name).to_sym

        attributes = element.type.attributes rescue []
        subelements = element.type.elements

        if subelements.empty? && attributes.empty?
          type_name = element.type.name rescue "Unknown"
          el_tree[el_snake] = type_name
          snake_map[el_snake] = {camel: element.name}
        elsif type_rec.keys.include? element.type
          el_tree[el_snake] = type_rec[element.type][:tree]
          snake_map[el_snake] = type_rec[element.type][:snake_map]
        else
          el_tree[el_snake] = {}
          snake_map[el_snake] = {camel: element.name, sub: {}}

          attributes.each { |attribute|
            camel_attr = camel_to_snake_case(attribute).to_sym
            el_tree[el_snake][camel_attr] = "Attribute"
            snake_map[el_snake][:sub][camel_attr] = {camel: attribute}
          }

          type_rec[element.type] = {tree: el_tree[el_snake],
                                    snake_map: snake_map[el_snake]}
          subelements.keys.each do |key|
            build_mappings(el_tree[el_snake], snake_map[el_snake][:sub], subelements[key], type_rec)
          end

          type_rec.delete(element.type)
        end
      end
    end
  end

  class PolarionCallError < StandardError
    attr_reader :response

    def initialize(response)
      @response = response
    end
  end
end
end
