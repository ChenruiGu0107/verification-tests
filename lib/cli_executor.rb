require 'yaml'

require 'rules_command_executor'
require 'token'

module CucuShift
  class CliExecutor
    include Common::Helper

    RULES_DIR = File.expand_path(HOME + "/lib/rules/client")

    attr_reader :opts

    def initialize(env, **opts)
      @opts = opts
    end

    # @param [CucuShift::User] user user to execute command with
    # @param [Symbol] key command key
    # @param [Hash] opts command options
    def exec(user, key, **opts)
      raise
    end

    private def version
      return opts[:cli_version]
      # this method needs to be overwriten per executor to find out version
    end

    private def rules_version(str_version)
      return str_version.split('.')[1]
    end

    def clean_up
    end
  end

  # execute cli commands on the first master machine as each user respectively
  #   it also does prior cert and token setup
  class MasterOsPerUserCliExecutor < CliExecutor
    def initialize(env, **opts)
      super
      @executors = {}
    end

    # @param [CucuShift::User] user user to execute command with
    # @return rules executor, separate one per user
    def executor(user)
      return @executors[user.name] if @executors[user.name]

      host = user.env.api_host
      version = version_for_user(user, host)
      executor = RulesCommandExecutor.new(host: host, user: user.name, rules: File.expand_path(RULES_DIR + "/" + rules_version(version) + ".yaml"))

      # make sure cli execution environment is setup for the user
      # in environments where we run client commands as single operating system
      # user, perhaps we need to do this upon switching users
      # clean-up:
      #   .config/openshift/config
      #   .kube/config
      if user.cached_tokens.size == 0
        ## login with username and password and generate a bearer token
        executor.run(:logout, {}) # ignore outcome
        res = executor.run(:login, username: user.name, password: user.password, ca: "/etc/openshift/master/ca.crt", server: user.env.api_endpoint_url)
      else
        ## login with existing token
        res = executor.run(:login, token: user.cached_tokens.first, ca: "/etc/openshift/master/ca.crt", server: user.env.api_endpoint_url)
      end
      unless res[:success]
        logger.error res[:response]
        raise "cannot login with command: #{res[:instruction]}"
      end

      if user.cached_tokens.size == 0
        ## lets cache tokens obtained by username/password
        res = executor.exec(user, :config_view, output: "yaml")
        unless res[:success]
          logger.error res[:response]
          raise "cannot read user configuration by: #{res[:instruction]}"
        end
        conf = YAML.load(res[:response])
        uhash = conf["users"].find{|u| u["name"].start_with?(user.name + "/")}
        # hardcode one day validity as we cannot get validity from config
        user.cached_tokens << Token.new(user: user, token: uhash["user"]["token"], valid: Time.now + 24 * 60 * 60)
      end

      return @executors[user.name] = executor
    end

    private def version_for_user(user, host)
      # return user requested version if set
      return version if version

      res = host.exec_as(user.name, "oc version")
      raise "cannot execute on host #{host.hostname} as user #{user.name}" unless res[:success]

      # we assume all users will use same oc version
      return opts[:cli_version] = res[:response].scan(/^os?c v(.+)$/)[0][0]
    end

    def exec(user, key, **opts)
      executor(user).run(key, opts)
    end

    def clean_up
      @executors.each(&:clean_up)
      @executors.clear
      super
    end
  end
end
