require 'etc'
require 'socket'
# should not require 'common' and any other files from cucushift, base helpers
#   are fine though

# @note put only very base things here, do not use for configuration settings
module CucuShift
  HOME = File.expand_path(__FILE__ + "/../..")
  PRIVATE_DIR = ENV['CUCUSHIFT_PRIVATE_DIR'] || File.expand_path(HOME + "/private")
  HOSTNAME = Socket.gethostname.freeze
  LOCAL_USER = Etc.getlogin.freeze

  if ENV["NODE_NAME"]
    # likely a jenkins environment
    EXECUTOR_NAME = "#{ENV["NODE_NAME"]}-#{ENV["EXECUTOR_NUMBER"]}".freeze
  else
    EXECUTOR_NAME = "#{HOSTNAME.split('.')[0]}-#{LOCAL_USER}".freeze
  end
end
