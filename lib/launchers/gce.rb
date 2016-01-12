require 'google/api_client'
require 'common'
require 'host'
require 'launchers/cloud_helper'

lib_path = File.expand_path(File.dirname(File.dirname(__FILE__)))
unless $LOAD_PATH.any? {|p| File.expand_path(p) == lib_path}
  $LOAD_PATH.unshift(lib_path)
end


module CucuShift

  class GCE_Compute

    def initialize
      @config = conf[:services, :GCE]
      #config[:gce_service_account_pem_file_path] = '~/.gce/openshift-gce-devel_priv_key.pem'
      #config[:gce_service_account_email_address]='1043659492591-r0tpbf8q4fbb9dakhjfhj89e4m1ld83t@developer.gserviceaccount.com'
      
      pemfile = expand_private_path(@config[:gce_service_account_pem_file_path])
      pemfile = File.expand_path(pemfile)
      signed_key = Google::APIClient::KeyUtils.load_from_pem(pemfile, "notasecret")

      @client = Google::APIClient.new(api_client_options)
      @client.authorization = Signet::OAuth2::Client.new(
        :audience => "https://accounts.google.com/o/oauth2/token",
        :auth_provider_x509_cert_url => "https://www.googleapis.com/oauth2/v1/certs",
        :client_x509_cert_url => "https://www.googleapis.com/robot/v1/metadata/x509/#{config[:gce_service_account_email_address]}",
        :issuer => config[:gce_service_account_email_address],
        :scope => 'https://www.googleapis.com/auth/compute',
        :signing_key  =>signed_key,
        :token_credential_uri => "https://accounts.google.com/o/oauth2/token"
      )
      @client.authorization.fetch_access_token!

      @client
      @compute = client.discovered_api("compute", 'v1')
    end

    def get_resource_url_by_name(resource_name, resource_type ,project ,zone = nil)
      filter_str = "name eq #{resource_name}"
      params = {"project" => project, "filter" => filter_str}
      case resource_type
      when "zone"
        m = @compute.zones.list()
      when "snapshot"
        m = @compute.snapshots.list()
      when "image"
        m = @compute.images.list()
      when "network"
        m = @compute.networks.list()
      when "machineType"
        m = @compute.machine_types.list()
        params = {"project" => project,"zone" => zone, "filter" => filter_str}
      when "disk"
        m = @compute.disks.list()
        params = {"project" => project,"zone" => zone, "filter" => filter_str}
      when "instance"
        m = @compute.instances.list()
        params = {"project" => project,"zone" => zone, "filter" => filter_str }
      end
      res = @client.execute(:api_method => m, :parameters => params).data
      if res['items'] != []
        return res['items'][0]['selfLink'].gsub("https://www.googleapis.com/compute/v1/", '')
      else
        return nil
      end
    end

    def boot_from_image(project, image_name)
      image_url = self.get_resource_url_by_name(image_name, 'image', project)
      if image_url
        return true, image_url
      else
        image_url = self.get_resource_url_by_name(image_name, 'snapshot', project)
        if image_url
          image_url.gsub!("https://www.googleapis.com/compute/v1/", '')
          return false, image_url
        else
          raise "Can not found the image/snapshot: #{image_name}"
        end
      end
    end

    def create_instance(name: nil,image: nil, create_opts: {})
      if not create_opts['project']
        create_opts['project'] = "openshift-gce-devel"
      end

      from_image, image_url = boot_from_image(create_opts['project'], image)

      if create_opts['zone']
        zone_url = self.get_resource_url_by_name(create_opts['zone'], 'zone',create_opts['project'])
        if not zone_url
          raise "Can not found zone: #{create_opts['zone']} in project #{create_opts['project']}"
        end
      else
        create_opts['zone'] = "us-central1-c"
        zone_url = "projects/openshift-gce-devel/zones/us-central1-c"
      end

      if create_opts['network']
        network_url = self.get_resource_url_by_name(create_opts['network'],'network', create_opts['project'])
        if not network_url
          raise "Can not found network: #{create_opts['network']} in project #{create_opts['project']}"
        end
      else
        network_url = "projects/openshift-gce-devel/global/networks/default"
      end

      if create_opts['machinetype']
        machine_type = self.get_resource_url_by_name(create_opts['machinetype'],'machineType',create_opts['project'],create_opts['zone'])
        if not machine_type
          raise "Can not found machinetype: #{create_opts['machinetype']} "
        end
      else
        machine_type = "projects/openshift-gce-devel/zones/us-central1-c/machineTypes/n1-standard-1"
      end
     
      if from_image
        b = {'name' => name,'sourceImage' => image_url }
      else
        b = {'name' => name,'sourceSnapshot' => image_url}
      end
      p = {'project' => create_opts['project'], 'zone' => create_opts['zone']}
      self.delete_instance(create_opts['project'],create_opts['zone'], name)
      m = @compute.disks.insert()
      res = @client.execute(:api_method => m, :parameters => p, :body_object => b).data
      self.wait_operation(create_opts['project'], create_opts['zone'], res['name'])
      disk_url = self.get_resource_url_by_name(name, "disk",create_opts['project'], create_opts['zone'])

      b = { 'name' => name,
        'machineType' => machine_type,
        'disks' => [{
          'boot' => true,
          'autoDelete' => true,
          'source' => disk_url
          }],
        'networkInterfaces' => [{
          'network' => network_url,
          'accessConfigs' => [{'name' => 'external'}]
          }]
        }

      m = @compute.instances.insert()
      res = @client.execute(:api_method => m, :parameters => p, :body_object => b).data
      self.wait_operation(create_opts['project'], create_opts['zone'], res['name'])
      self.wait_instance(create_opts['project'],create_opts['zone'], name)
      self.get_instance_ip(create_opts['project'],create_opts['zone'], name)
    end

    def wait_operation(project, zone, operation)
      p = {'project' => project, 'zone' => zone, 'operation' => operation}
      m = @compute.zone_operations.get()
      120.times do | i |
        res = @client.execute(:api_method => m, :parameters => p).data
        if res['status'] == "DONE"
          break
        end
        if i >= 120 - 1
          raise "operation: #{operation} is not complete after 120 retries"
        end
        sleep 10
      end
    end

    def wait_instance(project, zone, instance, status = "RUNNING")
      p = {'project' => project, 'zone' => zone, 'instance' => instance}
      m = @compute.instances.get()
      120.times do | i |
        res = @client.execute(:api_method => m, :parameters => p).data
        if res['status'] == status
          break
        end
        if i >= 120 - 1
          raise "Can not wait instance: #{instance} #{status} after 120 retries"
        end
        sleep 10
      end
    end

    def get_instance_ip(project, zone, instance)
      self.wait_instance(project,zone, instance)
      p = {'project' => project, 'zone' => zone, 'instance' => instance}
      m = @compute.instances.get()
      res = @client.execute(:api_method => m, :parameters => p).data
      return res['networkInterfaces'][0]['networkIP'], res['networkInterfaces'][0]['accessConfigs'][0]['natIP']
    end

    def delete_disk(project, zone, disk)
      can_deleted = true
      m = @compute.disks.get()
      p = {"project" => project,"zone" => zone, "disk" => disk}
      res = @client.execute(:api_method => m, :parameters => p)
      if res.status == 200
        res_data = res.data
        if res_data['users'] != []
          can_deleted = false
        end
      else
        can_deleted = false
      end
      if can_deleted
        m = @compute.disks.delete()
        res = @client.execute(:api_method => m, :parameters => p).data
        self.wait_operation(project, zone, res['name'])
      end
    end

    def delete_instance(project, zone, instance)
      resource_url = self.get_resource_url_by_name(instance, 'instance', project,zone)
      if resource_url
        p = {'project' => project, 'zone' => zone, 'instance' => instance}
        m = @compute.instances.delete()
        res = @client.execute(:api_method => m, :parameters => p).data
        self.wait_operation(project, zone, res['name'])
      end
    end
  end
end

#test = CucuShift::GCE_Compute.new()
#opts = {"project" => "openshift-gce-devel",
#  "zone" => "us-central1-c",
#  "network" => "default",
#  "machinetype" => "n1-standard-1"
#}
#p test.create_instance(name: "xiama-test-master", image: "libra-rhel72", create_opts: opts)