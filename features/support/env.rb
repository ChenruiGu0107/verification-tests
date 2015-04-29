## add our lib dir to load path
$LOAD_PATH.unshift(File.expand_path("#{__FILE__}/../../../lib"))

require 'common' # common code
require 'world' # our custom cucushift world
require 'manager' # our shared global state

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

  ## default course of action would be to update Default* classes when
  #  changes are needed but some features are specific to team and test
  #  environment; lets allow customizing base classes by loading a separate
  #  project tree
  private_env_rb = File.expand_path(CucuShift::HOME + "/private/env.rb")
  require private_env_rb if File.exist? private_env_rb

  # use default classes if these were not overriden by private ones
  CucuShift::Manager ||= CucuShift::DefaultManager
  CucuShift::World   ||= CucuShift::DefaultWorld
end

at_exit do
  CucuShift::Manager.instance.clean_up
end
