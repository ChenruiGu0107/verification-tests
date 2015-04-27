LIB_PATH = File.expand_path(File.join(__FILE__, '..', '..', '..', 'lib'))
$LOAD_PATH.unshift(LIB_PATH)

require 'common' # common code
require 'world' # our custom cucushift world

World do
  # the new object created here would be the context Before and After hooks
  # execute in. So extend that class with methods you want to call.
  CucuShift::World.new
end

Before do |scenario|
end

After do |scenario|
end

AfterConfiguration do |config|
  CucuShift::Common::Setup.handle_signals
  CucuShift::Common::Setup.set_cucushift_home
end

at_exit do
  CucuShift::Common::Helper.manager.clean_up
end
