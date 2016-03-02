#!/usr/bin/env ruby

lib_path = File.expand_path(File.dirname(File.dirname(__FILE__)))
unless $LOAD_PATH.any? {|p| File.expand_path(p) == lib_path}
    $LOAD_PATH.unshift(lib_path)
end

require 'json'
require 'io/console' # for reading password without echo
require 'timeout' # to avoid freezes waiting for user input
require 'yaml'

require 'common'
require 'host'
require 'http'
require 'net'

module CucuShift
  class OpenStack
    include Common::Helper

    attr_reader :os_tenant_id, :os_tenant_name
    attr_reader :os_user, :os_passwd, :os_url, :opts
    attr_accessor :os_token, :os_ApiUrl, :os_image, :os_flavor

    def initialize(**options)
      # by default we look for 'openstack' service in configuration but lets
      #   allow users to keep configuration for multiple OpenStack instances
      service_name = options[:service_name] ||
                     ENV['OPENSTACK_SERVICE_NAME'] ||
                     'openstack'
      @opts = default_opts(service_name).merge options

      @os_user = ENV['OPENSTACK_USER'] || opts[:user]
      unless @os_user
        Timeout::timeout(120) do
          STDERR.puts "OpenStack user (timeout in 2 minutes): "
          @os_user = STDIN.gets.chomp
        end
      end
      @os_passwd = ENV['OPENSTACK_PASSWORD'] || opts[:password]
      unless @os_passwd
        STDERR.puts "OpenStack Password: "
        @os_passwd = STDIN.noecho(&:gets).chomp
      end
      @os_tenant_id = ENV['OPENSTACK_TENANT_ID'] || opts[:tenant_id]
      @os_tenant_name = ENV['OPENSTACK_TENANT_NAME'] || opts[:tenant_name]
      if @os_tenant_id && @os_tenant_name
        raise "please provide only one of tenant name and tenant id, now we have both: #{@os_tenant_id} #{@os_tenant_name}"
      end

      @os_url = ENV['OPENSTACK_URL'] || opts[:url]

      if ENV['OPENSTACK_IMAGE_NAME'] && !ENV['OPENSTACK_IMAGE_NAME'].empty?
        opts[:image] = ENV['OPENSTACK_IMAGE_NAME']
      elsif ENV['CLOUD_IMAGE_NAME'] && !ENV['CLOUD_IMAGE_NAME'].empty?
        opts[:image] = ENV['CLOUD_IMAGE_NAME']
      end
      raise if opts[:image].nil? || opts[:image].empty?
      opts[:flavor] = ENV.fetch('OPENSTACK_FLAVOR_NAME') { opts[:flavor] }
      opts[:key] = ENV.fetch('OPENSTACK_KEY_NAME') { opts[:key] }

      self.get_token()
    end

    # @return [ResultHash]
    # @yield [req_result] if block is given, it is yielded with the result as
    #   param
    def rest_run(url, method, params, token = nil, read_timeout = 60, open_timeout = 60)
      headers = {'Content-Type' => 'application/json',
                 'Accept' => 'application/json'}
      headers['X-Auth-Token'] = token if token

      if headers["Content-Type"].include?("json") &&
          ( params.kind_of?(Hash) || params.kind_of?(Array) )
        params = params.to_json
      end

      res = Http.request(:url => "#{url}",
                          :method => method,
                          :payload => params,
                          :headers => headers,
                          :read_timeout => read_timeout,
                          :open_timeout => open_timeout)

      if res[:success]
        if res[:headers] && res[:headers]['content-type']
          content_type = res[:headers]['content-type'][0]
          case
          when content_type.include?('json')
            res[:parsed] = JSON.load(res[:response])
          when content_type.include?('yaml')
            res[:parsed] = YAML.load(res[:response])
          end
        end

        yield res if block_given?
      end
      return res
    end

    def get_token()
      # TODO: get token via token
      #   http://docs.openstack.org/developer/keystone/api_curl_examples.html
      auth_opts = {:passwordCredentials => { "username" => self.os_user, "password" => self.os_passwd }}
      if @os_tenant_id
        auth_opts[:tenantId] = self.os_tenant_id
      else
        auth_opts[:tenantName] = self.os_tenant_name
      end
      params = {:auth => auth_opts}
      res = self.rest_run(self.os_url, "POST", params) do |result|
        parsed = result[:parsed] || next
        @os_token = parsed['access']['token']['id']
        logger.info "logged in to tenant: #{parsed['access']['token']["tenant"].to_json}" if parsed['access']['token']["tenant"]
        for server in parsed['access']['serviceCatalog']
          if server['name'] == "nova" and server['type'] == "compute"
            @os_ApiUrl = server['endpoints'][0]['publicURL']
            break
          end
        end
      end

      unless @os_ApiUrl
        logger.error res.to_yaml
        raise "Could not obtain proper token and URL, see log"
      end
      return @os_token
    end

    def get_obj_ref(obj_name, obj_type, quiet: false)
      params = {}
      url = self.os_ApiUrl + '/' + obj_type
      res = self.rest_run(url, "GET", params, self.os_token)
      if res[:success] && res[:parsed]
        for obj in res[:parsed][obj_type]
          if obj['name'] == obj_name
            ref = obj["links"][0]["href"]
            logger.info("ref of #{obj_type} \"#{obj_name}\": #{ref}")
            return ref
          end
        end
        logger.warn "ref of #{obj_type} \"#{obj_name}\" not found" unless quiet
        return nil
      else
        raise "error getting object reference:\n" << res.to_yaml
      end
    end

    def get_image_ref(image_name)
      @os_image = get_obj_ref(image_name, 'images')
    end

    def get_flavor_ref(flavor_name)
      @os_flavor = get_obj_ref(flavor_name, 'flavors')
    end

    def create_instance_api_call(instance_name, image: nil,
                        flavor_name: nil, key: nil, **create_opts)
      image ||= opts[:image]
      flavor_name ||= opts[:flavor]
      key ||= opts[:key]

      self.delete_instance(instance_name)
      self.get_image_ref(image)
      self.get_flavor_ref(flavor_name)
      params = {:server => {:name => instance_name, :key_name => key ,:imageRef => self.os_image, :flavorRef => self.os_flavor}.merge(create_opts)}
      url = self.os_ApiUrl + '/' + 'servers'
      res = self.rest_run(url, "POST", params, self.os_token)
      if res[:success] && res[:parsed]
        logger.info("created instance: #{instance_name}")
        return res[:parsed]
      else
        logger.error("Can not create #{instance_name}")
        raise "error creating instance reference:\n" << res.to_yaml
      end
    end

    # doesn't really work if you didn't use tenant when authenticating
    def list_tenants
      url = self.os_ApiUrl + '/' + 'tenants'
      res = self.rest_run(url, "GET", {}, self.os_token)
      return res[:parsed]
    end

    def create_instance(instance_name, **create_opts)
      params = nil
      server_id = nil
      url = nil

      attempts = 120
      attempts.times do |attempt|
        logger.info("launch attempt #{attempt}..")

        # if creation attempt was performed, get instance status
        if url && params
          res = self.rest_run(url, "GET", params, self.os_token)
          result = res[:parsed]
        end

        # on first iteration and on instance launch failure we retry
        if !result || result["server"]["status"] == "ERROR"
          logger.info("** attempting to create an instance..")
          res = create_instance_api_call(instance_name, **create_opts)
          server_id = res["server"]["id"] rescue next
          params = {}
          url = self.os_ApiUrl + '/' + 'servers/' + server_id
          sleep 15
        elsif result["server"]["status"] == "ACTIVE"
          address_key = result["server"]["addresses"].keys[0]
          if result["server"]["addresses"][address_key].length == 2
            logger.info("Get the Private IP: #{result["server"]["addresses"][address_key][0]["addr"]}")
            logger.info("Get the Pulic IP:   #{result["server"]["addresses"][address_key][1]["addr"]}")
            return [
              result["server"]["addresses"][address_key][0]["addr"],
              result["server"]["addresses"][address_key][1]["addr"]
            ]
          else
            self.assign_ip(instance_name)
          end
        else
          logger.info("Wait 10 seconds to get the IP of #{instance_name}")
          sleep 10
        end
      end
      raise "could not create instance properly after #{attempts} attempts"
    end

    def delete_instance(instance_name)
      params = {}
      url = self.get_obj_ref(instance_name, "servers", quiet: true)
      if url
        logger.warn("deleting old instance \"#{instance_name}\"")
        self.rest_run(url, "DELETE", params, self.os_token)
        1.upto(60)  do
          sleep 10
          if self.get_obj_ref(instance_name, "servers", quiet: true)
            logger.info("Wait for 10s to delete #{instance_name}")
          else
            return true
          end
        end
        raise "could not delete old instance \"#{instance_name}\""
      end
    end

    def assign_ip(instance_name)
      assigning_ip = nil
      params = {}
      url = self.os_ApiUrl + '/os-floating-ips'
      res = self.rest_run(url, "GET", params, self.os_token)
      result = res[:parsed]
      result['floating_ips'].each do | ip |
        if ip['instance_id'] == nil
          assigning_ip = ip['ip']
          logger.info("The floating ip is #{assigning_ip}")
          break
        end
      end

      params = { "addFloatingIp" => {"address" => assigning_ip }}
      instance_href = self.get_obj_ref(instance_name, 'servers') + "/action"
      self.rest_run(instance_href, "POST", params, self.os_token)
    end

    # @param service_name [String] the service name of this openstack instance
    #   to lookup in configuration
    def default_opts(service_name)
      return  conf[:services, service_name.to_sym]
    end

    # launch multiple instances in OpenStack
    # @param os_opts [Hash] options to pass to [OpenStack::new]
    # @param names [Array<String>] array of names to give to new machines
    # @return [Hash] a hash of name => hostname pairs
    # TODO: make this return a [Hash] of name => CucuShift::Host pairs
    def launch_instances(names:, **create_opts)
      res = {}
      host_opts = create_opts[:host_opts] || {}
      host_opts = opts[:host_opts].merge(host_opts) # merge with global opts
      names.each { |name|
        _, ip = create_instance(name, **create_opts)
        res[name] = Host.from_ip(ip, host_opts)
      }
      return res
    end
  end
end

## Standalone test
if __FILE__ == $0
  test = CucuShift::OpenStack.new()
  #puts test.create_instance("xiama_test", 'RHEL6.5-qcow2-updated-20131213', 'm1.medium')
  #test.delete_instance('test')
end
