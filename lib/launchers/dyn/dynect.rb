require_relative 'oo_exception'
require_relative 'dynect_plugin'

module CucuShift
  # we reuse DynectPlugin and add our convenience methods
  class Dynect < ::OpenShift::DynectPlugin
    # FYI logger method is overridden by Helper so we should be good to go
    include Common::Helper

  end
end
