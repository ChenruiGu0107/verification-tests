#!/usr/bin/env ruby

lib_path = File.expand_path(File.dirname(File.dirname(__FILE__)))
unless $LOAD_PATH.any? {|p| File.expand_path(p) == lib_path}
    $LOAD_PATH.unshift(lib_path)
end

require 'json'
require 'rest-client'
require 'io/console' # for reading password without echo
require 'timeout' # to avoid freezes waiting for user input

require 'common'
require 'host'
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

    # TODO: migrate this to use Common::Http::request and support :ca_path
    def rest_run(url, method, params, token = nil, timeout = 60, open_timeout = 60)
      headers = {'Content-Type' => 'application/json',
                 'Accept' => 'application/json'}
      token ?   headers['X-Auth-Token'] = token : headers

      params = (params == {}) ? false : JSON.dump(params)
      req = RestClient::Request.new(:url => "#{url}",
                                    :method => method,
                                    :payload => params,
                                    :headers => headers,
                                    :timeout => timeout,
                                    :open_timeout => open_timeout)
      begin
        res = req.execute()
      rescue => e
        # REST request unsuccessful
        if e.respond_to?(:response) and e.response.respond_to?(:code) and e.response.code.kind_of? Integer
          logger.info("HTTP error:  #{e.response}")
          # server replied with non-success HTTP status, that's ok
          res = e.response
        else
          # request failed badly, server/network issue?
          logger.error("Unsuccessful REST request: #{method} #{url} #{JSON.dump(params)}: #{e.message}")
          raise e
        end
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
      res = self.rest_run(self.os_url, "POST", params)
      begin
        result = JSON.load(res)
        @os_token = result['access']['token']['id']
        logger.info "logged in to tenant: #{result['access']['token']["tenant"].to_json}" if result['access']['token']["tenant"]
        for server in result['access']['serviceCatalog']
          if server['name'] == "nova" and server['type'] == "compute"
            @os_ApiUrl = server['endpoints'][0]['publicURL']
            break
          end
        end
      rescue JSON::ParserError => e
        logger.info("HTTP CODE: #{res.code}")
        logger.info(res.to_s)
        raise e
      rescue => e
        logger.error("OpenStack Error: #{e.inspect}")
        raise e
      end
      unless @os_ApiUrl
        logger.error res
        raise "API did not return API URL, did you use proper tenant?"
      end
      return @os_token
    end

    def get_obj_ref(obj_name,obj)
      params = {}
      url = self.os_ApiUrl + '/' + obj
      logger.info("Get #{url}")
      res = self.rest_run(url, "GET", params, self.os_token)
      logger.info("Try to get the ref of #{obj}:  #{obj_name}")
      begin
        result = JSON.load(res)
        for obj in result[obj]
          if obj['name'] == obj_name
            return obj["links"][0]["href"]
          end
        end
        return nil
      rescue => e
        logger.error("Can not get the image info: #{e.message}")
        #logger.info("Try to get the info of RHEL_6.4_x86_64")
      end
      #get_image("RHEL_6.4_x86_64")
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
      begin
        logger.info("Create Instance: #{instance_name}")
        return JSON.load(res)
      rescue => e
        logger.error("Can not create #{instance_name} instance:  #{e.message}")
        logger.error(res.to_a.flatten(1).join("\n")) rescue nil
        raise e
      end
    end

    # doesn't really work if you didn't use tenant when authenticating
    def list_tenants
      url = self.os_ApiUrl + '/' + 'tenants'
      res = self.rest_run(url, "GET", {}, self.os_token)
      return JSON.load(res)
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
          result = JSON.load(res)
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
      url = self.get_obj_ref(instance_name,"servers")
      self.rest_run(url, "DELETE", params, self.os_token) if url
      1.upto(60)  do
        sleep 10
        if self.get_obj_ref(instance_name,"servers")
          logger.info("Wait for 10s to delete #{instance_name}")
        else
          return true
        end
      end
      self.delete_instance(instance_name)
    end

    def assign_ip(instance_name)
      assigning_ip = nil
      params = {}
      url = self.os_ApiUrl + '/os-floating-ips'
      logger.info("Get #{url}")
      res = self.rest_run(url, "GET", params, self.os_token)
      result = JSON.load(res)
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
