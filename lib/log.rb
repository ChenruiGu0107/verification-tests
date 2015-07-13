require 'time'

require 'base_helper'

# should not require 'common'
# filename is log.rb to avoid interference with logger ruby feature
require 'base_helper'

module CucuShift
  class Logger
    include Common::BaseHelper
    begin
      require 'term/ansicolor'
      include Term::ANSIColor
    rescue
    end

    @@runtime = Kernel unless defined? @@runtime
    @@color = nil

    def self.runtime=(runtime)
      @@runtime = runtime
    end

    def self.runtime
      return @@runtime
    end

    def self.reset_runtime
      @@runtime = Kernel
    end

    def initialize(level=nil)
      if level
        @level = level
      elsif ENV['CUCUSHIFT_LOG_LEVEL']
        @level = ENV['CUCUSHIFT_LOG_LEVEL'].to_sym
      else
        @level = :normal
      end
    end

    def time
      @@runtime.puts("#{Time.now.localtime}")
    end

    def log(msg, prefix="INFO> ", show_datetime='time')
      ## take case of special message types
      case msg
      when Exception
        msg = exception_to_string(msg)
      end

      m = ""
      if show_datetime == 'time'
        m = "#{Time.now.strftime("[%H:%M:%S]")} #{prefix}#{msg}"
      elsif show_datetime == 'datetime'
        m ="#{Time.now.strftime("[%Y-%m-%d %H:%M:%S]")} #{prefix}#{msg}"
      else
        m = "#{prefix}#{msg}"
      end

      # set colo/reset terminal if Term::ANSIColor installed, skip otherwise
      begin
        m = @@color+m+reset
      rescue => e
      end

      @@runtime.puts(m)
    end

    def info(msg, show_datetime='time')
      @@color=yellow if defined? yellow
      self.log(msg, "INFO> ", show_datetime)
    end

    def warn(msg, show_datetime='time')
      @@color=magenta if defined? magenta
      self.log(msg, "WARN> ", show_datetime)
    end

    def error(msg, show_datetime='time')
      @@color=red if defined? red
      self.log(msg, "ERROR> ", show_datetime)
    end

    def debug(msg, show_datetime='time')
      return if @level != :debug
      @@color=green if defined? green
      self.log(msg, "DEBUG> ", show_datetime)
    end

    def print(msg, show_datetime='time')
      @@color = reset if defined? reset
      self.log(msg, '', show_datetime)
    end
  end
end
