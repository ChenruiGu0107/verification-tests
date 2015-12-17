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

      # these are the steps needed to get the AWS image to work properly for Openshift
      def start_openshift_service(ssh)
        service_gen_cmd = "sudo -i generate_openshift_service"
        restart_cmd = "sudo systemctl start openshift"
        gen_res = ssh.exec(service_gen_cmd)
        raise "Failed to generate Openshift service" unless gen_res[:success]
        restart_res = ssh.exec(restart_cmd)
        raise "Failed to restart openshift service" unless restart_res[:success]
      end
    end
  end
end

