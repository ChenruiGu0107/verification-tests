## add our lib dir to load path
$LOAD_PATH << File.expand_path("#{__FILE__}/../../../lib")

if RUBY_VERSION.split('.')[0].to_i < 2 || RUBY_VERSION.split('.')[0] == '2' &&  RUBY_VERSION.split('.')[1].to_i < 2
  raise "Ruby version earlier than 2.2 not supported"
end
if Cucumber::VERSION.split('.')[0].to_i < 2
  raise "Cucumber version < 2 not supported"
end

require 'common' # common code
require 'world' # our custom cucushift world
require 'log' # CucuShift::Logger
require 'manager' # our shared global state
require 'environment' # environment types classes
require 'debug'

## default course of action would be to update CucuShift files when
#  changes are needed but some features are specific to team and test
#  environment; lets allow customizing base classes by loading a separate
#  project tree
private_env_rb = File.expand_path(CucuShift::PRIVATE_DIR + "/env.rb")
require private_env_rb if File.exist? private_env_rb

World do
  # the new object created here would be the context Before and After hooks
  # execute in. So extend that class with methods you want to call.
  CucuShift::World.new
end

Before do |_scenario|
  localhost.chdir
  self.scenario = _scenario
  setup_logger
end

After do |scenario|
  @scenario = scenario # this is different object than in Before hook
  if debug_in_after_hook?
    require 'pry'
    binding.pry
  end

  manager.clean_up
end

AfterConfiguration do |config|
  CucuShift::Common::Setup.handle_signals
  CucuShift::Common::Setup.set_cucushift_home

  # use default classes if these were not overriden by private ones
  CucuShift::Manager ||= CucuShift::DefaultManager
  CucuShift::World   ||= CucuShift::DefaultWorld

  # install step failure debugging code
  if CucuShift::Manager.conf[:debug_failed_steps]
    CucuShift::Debug.step_fail_cucumber2
  end
end

at_exit do
  CucuShift::Logger.reset_runtime # otherwise we lose output
  CucuShift::Manager.instance.clean_up
end
