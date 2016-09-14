require 'yaml'

module CucuShift

  # module which interacts with the master-config.yaml file on the master(s) of the openshift instalation.
  module MasterConfig

    # loads the config file from the server and returns it as a hash
    def self.as_hash(env)
      res = env.master_hosts[0].exec_admin("cat /etc/origin/master/master-config.yaml")
      self.res_err_check(res)
      return YAML.load(res[:response])
    end

    def self.raw(env)
      res = env.master_hosts[0].exec_admin("cat /etc/origin/master/master-config.yaml")
      self.res_err_check(res)
      return res
    end


    def self.update(env, content)
      res = nil
      env.master_hosts.each { |master|
        res = master.exec_admin("test -e /etc/origin/master/master-config.yaml.bak")
        if res[:success]
          # dump escapes non-printable characters, but also double qoutes.
          # so we gsub them that they are not escaped
          res = master.exec_admin("cat > /etc/origin/master/master-config.yaml", stdin: content)
          self.res_err_check(res)
        else
          self.res_err_check(res, "Backup file for master-config.yaml does not exists!")
        end
      }

      return res
    end

    def self.backup(env)
      res = nil
      env.master_hosts.each { |master|
        res = master.exec_admin("test -e /etc/origin/master/master-config.yaml.bak")
        raise res[:error] if res.key?(:error)
        unless res[:success]
          res = master.exec_admin("cat /etc/origin/master/master-config.yaml > /etc/origin/master/master-config.yaml.bak")
          self.res_err_check(res)
        end
      }
      return res
    end

    def self.restore(env)
      res = nil
      env.master_hosts.each { |master|
        res = master.exec_admin("test -e /etc/origin/master/master-config.yaml.bak")
        if res[:success]
          res = master.exec_admin("cat /etc/origin/master/master-config.yaml.bak > /etc/origin/master/master-config.yaml")
          if res[:success]
            res = master.exec_admin("rm /etc/origin/master/master-config.yaml.bak")
            self.res_err_check(res)
          else
            self.res_err_check(res)
          end
        else
          self.res_err_check(res, "Backup file for master-config.yaml does not exists!")
        end
      }

      return res
    end

    def self.res_err_check(res, custom_err = false)
      unless res[:success]
        raise res[:error] if res.key?(:error)
        raise custom_err if custom_err
        raise res[:stderr]
      end
    end

  end

end
