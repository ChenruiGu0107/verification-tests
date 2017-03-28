module CucuShift
  module Platform
    autoload :MasterService, "platform/master_service"
    autoload :NodeService, "platform/node_service"
    autoload :MasterConfig, "platform/master_config"
    autoload :NodeConfig, "platform/node_config"
    autoload :OpenShiftService, "platform/os_service"
    autoload :OpenShiftConfig, "platform/os_config"
  end
end
