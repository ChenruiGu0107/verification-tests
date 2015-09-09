require 'yaml'
require 'common'
require 'web4'
require 'find'
require 'collections'
require 'rules_common'


module CucuShift
  class WebConsoleExecutor < Web4
    include Common::Helper

    RULES_DIR = File.expand_path(HOME + "/lib/rules/web/") + "/"

    def initialize(env, user, **opts)
      # placeholder
      @rules_source=RULES_DIR
      @env = env
      opts[:server] = user.env.api_endpoint_url
      super opts
    end

    def executor(user)
      @user = user

      unless user.web_logged_in
        res = run_action(:login, username: user.name, password: user.password, :rules=>rules) 
        unless res[:success]
          logger.error res[:response]
          raise "login via console got error: #{res[:instruction]}"
        else
          user.web_logged_in = true
        end
      end

      return self
    end 

    def run(user, action, **opts)
      opts[:rules] = rules 
      return executor(user).run_action(action, opts)
    end

    def clean_up
      finalize
    end
    
    private
    def rules
      @rules ||= Collections.deep_freeze(Common::Rules.load(@rules_source))
    end 
  end

end

