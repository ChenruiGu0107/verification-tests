# should not require 'common' and any other files from cucushift

# @note put only very base things here, do not use for configuration settings
module CucuShift
  HOME = File.expand_path(__FILE__ + "/../..")
  PRIVATE_DIR = ENV['CUCUSHIFT_PRIVATE_DIR'] || File.expand_path(HOME + "/private")
end
