module CucuShift
  module Platform
    # class which interacts with the master-config.yaml file on the master(s) of the openshift instalation.
    class OpenShiftConfig

      attr_accessor :host, :service, :config_modified, :config_file_path

      def initialize(host, service)
        @host = host
        @service = service
        @config_modified = false
      end

      def as_hash
        YAML.load raw
      end

      def exists?
        res = host.exec_admin("test -e #{config_file_path}")
        return res[:success]
      end

      def config_modified?
        config_modified
      end

      def raw
        res = host.exec_admin("cat #{config_file_path}")
        self.class.res_err_check(res)
        return res[:response]
      end


      def self.res_err_check(res, custom_err = false)
        unless res[:success]
          raise res[:error] if res.key?(:error)
          raise custom_err if custom_err
          raise res[:stderr]
        end
      end

      def update(content)
        if exists?
          res = host.exec_admin("test -e #{config_file_path}.bak")
          if res[:success]
            res = host.exec_admin("cat > #{config_file_path}", stdin: content)
            if res[:success]
              config_modified = true
            end
          else
            self.class.res_err_check(res, "Backup file for #{config_file_path} does not exists!")
          end
        else
          res = {
            :success => true,
            :response => "Config #{config_file_path} does not exist on this host!"
          }
        end

        return res
      end

      def backup()
        if exists?
          res = host.exec_admin("test -e #{config_file_path}.bak")
          raise res[:error] if res.key?(:error)
          unless res[:success]
            res = host.exec_admin("cat #{config_file_path} > #{config_file_path}.bak")
            self.class.res_err_check(res)
          end
        else
          res = {
            :success => true,
            :response => "Config #{config_file_path} does not exist on this host!"
          }
        end
        return res
      end

      def restore()
        if exists?
          if config_modified?
            res = host.exec_admin("test -e #{config_file_path}.bak")
            if res[:success]
              res = host.exec_admin("cat #{config_file_path}.bak > #{config_file_path}")
              if res[:success]
                res = host.exec_admin("rm #{config_file_path}.bak")
                if res[:success]
                  config_modified = false
                  service.restart_all
                else
                  self.class.res_err_check(res)
                end
              else
                self.class.res_err_check(res)
              end
            else
              self.class.res_err_check(res, "Backup file for #{config_file_path} does not exists!")
            end
          else
            res = {
              :success => true,
              :response => "Config #{config_file_path} was already restored!"
            }
          end
        else
          res = {
            :success => true,
            :response => "Config #{config_file_path} does not exist on this host!"
          }
        end

        return res
      end
    end
  end
end

