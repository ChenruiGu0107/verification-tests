require 'openshift/user'

module CucuShift
  # small abstraction over having admin access to environment
  class ClusterAdmin < User

    def initialize(env:)
      @env = env
      @rest_preferences = {}
    end

    # just blindly delegates to Environment#admin_cli_executor
    def cli_exec(*args, &block)
      env.admin_cli_executor.exec(*args, &block)
    end

    undef name # cluster admin name shall be known only to the enlightened
    undef webconsole_exec
    undef webconsole_executor

    def clean_up
      # do nothing
    end

    def clean_up_on_load
      # do nothing
    end
  end
end
