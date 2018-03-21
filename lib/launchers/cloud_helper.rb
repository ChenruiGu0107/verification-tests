# should not require 'common'
# should only include helpers that do NOT load any other cucushift classes

module CucuShift
  module Common
    module CloudHelper
      # based on information in https://github.com/openshift/vagrant-openshift/blob/master/lib/vagrant-openshift/templates/command/init-openshift/box_info.yaml
      # returns the proper username given the type of base image specified
      def get_username(image='rhel7')
        username = nil
        case image
        when 'rhel7', 'rhel7next'
          username = 'ec2-user'
        when 'centos7'
          username = 'centos'
        when 'fedora'
          username = 'fedora'
        when 'rhelatomic7'
          username = 'cloud-user'
        else
          raise "Unsupported image type #{image}"
        end
        return username
      end

      def iaas_by_service(service_name)
        case conf[:services, service_name, :cloud_type]
        when "aws"
          raise "TODO service choice" unless service_name == :AWS
          Amz_EC2.new
        when "azure"
          CucuShift::Azure.new(service_name: service_name)
        when "openstack"
          CucuShift::OpenStack.instance(service_name: service_name)
        when "gce"
          CucuShift::GCE.new(service_name: service_name)
        when "vsphere"
          CucuShift::VSphere.new(service_name: service_name)
        else
          raise "unknown service type " \
            "#{conf[:services, service_name, :cloud_type]} for cloud " \
            "#{service_name}"
        end
      end
    end
  end
end

