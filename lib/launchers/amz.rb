#!/usr/bin/env ruby
require 'parseconfig'
require 'aws-sdk'

require 'common'
require 'host'

module CucuShift

  class Amz_EC2
    include Common::Helper
    # include Common::CloudHelper

    def initialize(conf)
      awscred = nil
      # try to find a suitable Amazon AWS credentials file
      [ expand_private_path(conf[:services, :AWS, :awscred]),
      ].each do |cred_file|
        begin
          cred_file = File.expand_path(cred_file)
          logger.info("Using #{cred_file} credentials file.")
          awscred = ParseConfig.new(cred_file)
          break # break if no error was raised above
        rescue
          logger.warn("Problem reading credential file #{cred_file}")
          next # try next configuration file
        end
      end

      raise "no readable credentials file found" unless awscred
      Aws.config.update({
        region: conf['services'][:AWS][:region],
        credentials: Aws::Credentials.new(awscred.params["AWSAccessKeyId"],
          awscred.params["AWSSecretKey"])
        })
      client = Aws::EC2::Client.new
      @ec2 = Aws::EC2::Resource.new(client: client)
    end

    def create_instance(image_id=nil)
      launch_instances(image=image_id)
    end

    ########################################################################
    # AMI helper methods
    ########################################################################
    def get_amis(filter_val=conf[:services][:AWS][:devenv_wildcard])
      # returns a list of amis
       @ec2.images({
        filters: [
            {
              name: "name",
              values: [filter_val],
            },
            {
              name: "state",
              values: ["available"],
            },
          ],
       }).to_a
    end

    def get_all_qe_ready_amis()
      # returns a list of amis
       @ec2.images({
        filters: [
            {
              name: "state",
              values: ["available"],
            },
            {
              name: "tag-value",
              values: [conf[:services][:AWS][:qe_ready]],
            },
          ],
        })

    end
    # Returns the ami-id given a name
    # @return [Sting] ami-id, if no match then nil
    #
    def get_ami_id_from_name(ami_name)
      ami = @ec2.images({
        filters: [
            {
              name: "name",
              values: [ami_name],
            },
          ],
        }).to_a
      if ami.count == 0
        return nil
      else
        return ami[0].id
      end
    end

    def get_latest_ami(filter_val=conf[:services][:AWS][:devenv_wildcard])
      devenv_amis = @ec2.images({
        filters: [
            {
              name: "name",
              values: [filter_val],
            },
            {
              name: "state",
              values: ["available"],
            },
            {
              name: "tag-value",
              values: [conf[:services][:AWS][:qe_ready]],
            },
          ],
        })
      # take the last devenv ami
      devenv_amis.to_a.sort_by {|ami| ami.name.split("_")[-1].to_i}.last
    end

    # Returns snaphost hash
    # @return [Hash] snapshot_set
    # example: {:tag_set=>[], :snapshot_id=>"snap-b4f04508", :volume_id=>"vol-81ab9fce", :status=>"completed", :start_time=>2014-11-11 16:05:50 UTC, :progress=>"100%", :owner_id=>"531415883065", :volume_size=>25, :description=>"Created by CreateImage(i-37f49418) for ami-1e51db76 from vol-81ab9fce", :encrypted=>false}
    def get_snapshot_info(ami_id)
      client = @ec2.client
      res = @ec2.client.describe_images({:image_ids => [ami_id]})
      begin
        snapshot_id = res.images_set[0].block_device_mapping[0].ebs.snapshot_id
        snapshot_res = client.describe_snapshots({:snapshot_ids=> [snapshot_id]})
        return snapshot_res.snapshot_set[0]
      rescue
        $logger.info("Unable to get ami creation time for #{ami_id}, will be not stored into database")
        return nil
      end
    end
    # Returns latest devenv-stage-* AMI
    # @return [String] ami-id
    def get_latest_stable_ami
      return get_latest_ami(conf[:services][:AWS][:stable_ami])
    end

    # @param [String] ec2_tag the EC2 'Name' tag value
    # @return [Array<String>, Array<Object>] the array of IP address with array of instances object
    #
    def get_instance_ip_by_tag(ec2_tag)
      instances = @ec2.instances({
        filters: [
          {
            name: "tag:Name",
            values:[ec2_tag],
          },
        ]
      }).to_a
      if block_given?
        instances.each do |i|
          yield(i)
        end
      else
        ips = instances.map { |i| i.public_dns_name }
        return ips, instances
      end
    end

    #
    # @return [Array<Object>]
    def get_instance_by_id(ec2_instance_id)
      return @ec2.instances({
        filters: [
          {
            name: "instance-id",
            values:[ec2_instance_id],
          },
        ]
      }).to_a[0]
    end

    def get_instance_by_ip(ec2_instance_ip)
      # convert dns name to IP if necessary
      require 'resolv'
      ec2_instance_ip = Resolv.getaddress(ec2_instance_ip) unless ec2_instance_ip =~ /^[0-9]/
      res = @ec2.instances({
        filters: [
          {
            name: "ip-address",
            values:[ec2_instance_ip],
          },
        ]
      }).to_a[0]
    end
    # @param [String] ami_id the EC2 AMI-ID
    # @return [Array<String>, Array<Object>] the array of IP address with array of instances object
    #
    def get_instance_ip_by_ami_id(ami_id)
      instances = @ec2.instances({
        filters: [
          {
            name: "image-id",
            values:[ami_id],
          },
        ]
      }).to_a
      ips = instances.map{ |i| i.public_dns_name }
      return ips, instances
    end

    def add_tag(instance, name, retries=2)
      (1..retries).each do |i|
        begin
          # tag the instance
          instance.create_tags({
            tags: [
              {
                key: "Name",
                value: name,
              },
            ]
            })
        rescue Exception => e
          logger.info("Failed adding tag: #{e.message}")
          raise if i == retries
          sleep 5
        end
      end
    end

    def instance_status(instance)
      (1..10).each do |i|
        begin
          status = instance.state[:name].to_sym
          return status
        rescue Exception => e
          if i == 10
            logger.info("Failed to get instance status after 10 retries.")
            raise e
          end
          logger.info("Error getting status(retrying): #{e.message}")
          sleep 30
        end
      end
    end

    # returns ssh connection
    def block_until_available(instance, ssh_user='root')
      logger.info "Waiting for instance to be available..."
      if instance.public_dns_name == ''
        logger.info("Reloading instance...")
        instance.reload
      end

      hostname = instance.public_dns_name
      logger.info("hostname: #{hostname}")
      ssh_opts = {:user=>ssh_user, :ssh_key=> conf[:services][:AWS][:key_pair]}
      logger.info("Testing ssh connection with options #{ssh_opts}")
      aws_ssh = nil
      # sleep 30
      (1..5).each do |i|
        begin
          aws_ssh = SSH.new(hostname, ssh_opts)
          next
        rescue Exception => e
          if i == 5
            logger.info("Failed to get ssh connection!")
            raise e
          end
          logger.info("Timed out getting ssh session, retrying....")
          sleep 10
        end
      end
      aws_ssh = SSH.new(hostname, ssh_opts)
      logger.info("SSH connection estashlished")
      (1..17).each do
        break if aws_ssh.active?
        logger.info "SSH access failed... retrying"
        sleep 17
      end

      unless aws_ssh.active?
        terminate_instance(instance)
        raise ScriptError, "SSH availability timed out"
      end
      logger.info "Instance (#{hostname}) is accessible"
      return aws_ssh
    end

    def terminate_instance(instance)
      # we don't really have root permission to terminate, we'll just label it
      # 'teminate-qe' and let charlie takes care of it.
      logger.info("Terminating instance #{instance.public_dns_name}")
      instance.stop
      add_tag(instance, 'terminate-qe')
    end


    # Launch an EC2 instance either based on particular AMI or with the latest one.
    # If a tag_name is given then launch instance with it, otherwise use
    # the nameing convention of QE_devenv_<latest_ami>
    #
    # @param [String] image the AMI id
    # @param [String] tag_name the tag name for EC2 instance
    # @param [Hash] amz_options Amazon options TODO:
    # @param [Integer] max_retries max retries to try
    #
    # @return [Object] the object with all of the information
    #
    def launch_instances(config={:image=>nil,
                        :tag_name=>nil,
                        :stage=>false,
                        :username=>nil,
                        :image_filter=>nil,
                        :amz_options=>nil,
                        :root_disk_size=>nil,
                        :max_retries=>1})
      # default to use rhel if no filter is specified
      config[:base_os] = conf[:services][:AWS]['rhel7'] if config[:base_os].nil?
      default_amz_options = {:key_name => conf[:services][:AWS][:key_pair], :instance_type => conf[:services][:AWS][:instance_type]}
      config[:amz_options] = default_amz_options unless config[:amz_options]
      #default KEY
      config[:amz_options][:key_name] = default_amz_options[:key_name] unless config[:amz_options][:key_name]
      config[:amz_options][:instance_type] = default_amz_options[:instance_type] unless config[:amz_options][:instance_type]
      config[:max_retries] = 1 unless config[:max_retries]
      if config[:image].nil?
        if config[:stage]
          image = self.get_latest_stable_ami
        else
          logger.info("Using image filter #{config[:image_filter]}...")
          image = self.get_latest_ami(config[:image_filter])
        end
      elsif config[:image].kind_of? String
        image = @ec2.images[config[:image]]
      end
      if config[:tag_name].nil?
        config[:tag_name] = "QE_" + image.name + "_" + rand_str(6)
      end
      if image.nil?
        raise "No images with label 'qe-ready' found!"
      end
      instance_opt = config[:amz_options]
      instance_opt[:image_id] = image.id
      instance_opt[:subnet_id] = conf[:services][:AWS][:vpc_subnet_id]
      instance_opt[:min_count] = conf[:services][:AWS][:min_count]
      instance_opt[:max_count] = conf[:services][:AWS][:max_count]
      requested_disk_size = config[:root_disk_size]
      instance_opt[:block_device_mappings] = [
        {
          :device_name => "/dev/sda1",
          :ebs => {
            :volume_size => requested_disk_size.to_i
          }
        }
      ] if requested_disk_size
      instances = @ec2.create_instances(instance_opt)
      logger.info("Launching EC2 instance from #{image.name} with tag #{config[:tag_name]}...")
      instances.each do | instance |
        inst = instance.wait_until_running
        logger.info("Tagging instance with name #{config[:tag_name]} ...")
        inst.create_tags({
          tags: [
            {
              key: "Name",
              value: config[:tag_name]
            },
          ]
        })
        # make sure we can ssh into the instance
        aws_ssh = block_until_available(instance)
        start_openshift_service(aws_ssh) if aws_ssh
      end
    end
  end
end
