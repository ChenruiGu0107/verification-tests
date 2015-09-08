#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
require 'log'
require 'json'
require 'rest-client'

module CucuShift
  class OpenStack
    attr_reader :os_user, :os_passwd, :os_tenant_id, :os_url
    attr_accessor :os_token, :os_ApiUrl, :os_image, :os_flavor
    def initialize(user, password, url='http://10.3.0.3:5000/v2.0/tokens', tenantId='68408e6815dd4078b911d8ba4228766f')
      @os_user = user
      @os_passwd = password
      @os_tenant_id = tenantId
      @os_url = url
      self.get_token()
    end

    def rest_run(url, method, params, token = nil, timeout = 60, open_timeout = 60)
      headers = {'Content-Type' => 'application/json', 'Accept' => 'application/json'}
      token ?   headers['X-Auth-Token'] = token : headers
      
      params = (params == {}) ? false : JSON.dump(params)
      req = RestClient::Request.new(:url => "#{url}", :method => method, :payload => params, :headers => headers, :timeout => timeout, :open_timeout => open_timeout)
      begin
        res = req.execute()
      rescue => e
        # REST request unsuccessful
        if e.respond_to?(:response) and e.response.respond_to?(:code) and e.response.code.kind_of? Integer
          $logger.info("error:  #{e.response}")
          # server replied with non-success HTTP status, that's ok
          res = e.response
        else
          # request failed badly, server/network issue?
          $logger.error("Unsuccessful REST request: #{method} #{url} #{JSON.dump(params)}: #{e.message}")
          raise e
        end
      end
      return res
    end

    def get_token()
      params = {:auth => {"tenantId" => self.os_tenant_id, :passwordCredentials => { "username" => self.os_user, "password" => self.os_passwd }}}
      res = self.rest_run(self.os_url, "POST", params)
      begin
        result = JSON.load(res)
        @os_token = result['access']['token']['id']
        for server in result['access']['serviceCatalog']
          if server['name'] == "nova" and server['type'] == "compute"
            @os_ApiUrl = server['endpoints'][0]['publicURL']
            break
          end
        end 
      rescue => e
        $logger.error("JSON Format Error: #{e.message}")
        raise e
      end
    end
      
    def get_obj_ref(obj_name,obj)
      params = {}
      url = self.os_ApiUrl + '/' + obj
      $logger.info("Get #{url}")
      res = self.rest_run(url, "GET", params, self.os_token)
      $logger.info("Try to get the ref of #{obj}:  #{obj_name}")
      begin
        result = JSON.load(res)
        for obj in result[obj]
          if obj['name'] == obj_name
            return obj["links"][0]["href"]
          end
        end
        return nil
      rescue => e
        $logger.error("Can not get the image info: #{e.message}")
        #$logger.info("Try to get the info of RHEL_6.4_x86_64")
      end
      #get_image("RHEL_6.4_x86_64")
    end
    
    def get_image_ref(image_name)
      @os_image = get_obj_ref(image_name, 'images')
    end
   
    def get_flavor_ref(flavor_name)
      @os_flavor = get_obj_ref(flavor_name, 'flavors')
    end

    def create_instance(instance_name, image_name, flavor_name, key='libra')
      self.delete_instance(instance_name)
      self.get_image_ref(image_name)
      self.get_flavor_ref(flavor_name)
      params = {:server => {:name => instance_name, :key_name => key ,:imageRef => self.os_image, :flavorRef => self.os_flavor}}    
      url = self.os_ApiUrl + '/' + 'servers'
      res = self.rest_run(url, "POST", params, self.os_token)
      begin
        $logger.info("Create Instance: #{instance_name}")
        result = JSON.load(res)
        server_id = result["server"]["id"]
      rescue => e
        $logger.error("Can not create #{instance_name} instance:  #{e.message}")
        raise e
      end 
      params = {}
      url = self.os_ApiUrl + '/' + 'servers/' + server_id
      result_flag = true
      1.upto(120)  do
        res = self.rest_run(url, "GET", params, self.os_token)
        result = JSON.load(res)
        if result["server"]["status"] == "ERROR"
          $logger.error("The status of instance is ERROR")
          self.create_instance(instance_name, image_name, flavor_name, key)
        elsif result["server"]["status"] == "ACTIVE"
          result_flag = false
          if result["server"]["addresses"].has_key?("os1-internal-1400")
            $logger.info("Get the Pulic and Private IP: #{result["server"]["addresses"]["os1-internal-1400"][0]["addr"]}")
            $logger.info("Get the Pulic and Private IP: #{result["server"]["addresses"]["os1-internal-1400"][1]["addr"]}")
            return result["server"]["addresses"]["os1-internal-1400"][0]["addr"],result["server"]["addresses"]["os1-internal-1400"][1]["addr"]
          else
            if result["server"]["addresses"]["private"].length == 2
              $logger.info("Get the Pulic and Private IP: #{result["server"]["addresses"]["private"][0]["addr"]}")
              $logger.info("Get the Pulic and Private IP: #{result["server"]["addresses"]["private"][1]["addr"]}")
              return result["server"]["addresses"]["private"][0]["addr"],result["server"]["addresses"]["private"][1]["addr"] 
            else
              self.assign_ip(instance_name)
              next
            end
          end
        else
          $logger.info("Wait 10 seconds to get the IP of #{instance_name}")
          sleep 10
        end
      end
      self.create_instance(instance_name, image_name, flavor_name, key) if result_flag
    end
    
    def delete_instance(instance_name)
      params = {}
      url = self.get_obj_ref(instance_name,"servers")
      self.rest_run(url, "DELETE", params, self.os_token) if url
      1.upto(60)  do
        sleep 10
        if self.get_obj_ref(instance_name,"servers")
          $logger.info("Wait for 10s to delete #{instance_name}")
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
      $logger.info("Get #{url}")
      res = self.rest_run(url, "GET", params, self.os_token)
      result = JSON.load(res)
      result['floating_ips'].each do | ip |
        if ip['instance_id'] == nil
          assigning_ip = ip['ip']
          $logger.info("The floating ip is #{assigning_ip}")
          break
        end
      end
      
      params = { "addFloatingIp" => {"address" => assigning_ip }}
      instance_href = self.get_obj_ref(instance_name, 'servers') + "/action"
      self.rest_run(instance_href, "POST", params, self.os_token)
    end
  end
end
  #test = CucuShift::Mopenstack.new('jialiu','redhat')
  #puts test.create_instance("xiama_test", 'RHEL6.5-qcow2-updated-20131213', 'm1.medium')
  #test.delete_instance('test')
