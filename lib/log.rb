require 'time'

require 'base_helper'

# should not require 'common'
# filename is log.rb to avoid interference with logger ruby feature
require 'base_helper'

module CucuShift
  class Logger
    include Common::BaseHelper

    require 'term/ansicolor' rescue nil
    # include Term::ANSIColor

    attr_reader :level

    PLAIN = 0
    ERROR = 1
    WARN = 2
    INFO = 3
    DEBUG = 4
    TRACE = 5
    FLOOD = 6

    PREFIX = {
      INFO => "INFO> ",
      WARN => "WARN> ",
      ERROR => "ERROR> ",
      DEBUG => "DEBUG> ",
      PLAIN => "",
      FLOOD => "FLOOD> ",
      TRACE => "TRACE> "
    }

    COLOR = {
      INFO => (Term::ANSIColor.yellow rescue ""),
      WARN => (Term::ANSIColor.magenta rescue ""),
      ERROR => (Term::ANSIColor.red rescue ""),
      DEBUG => (Term::ANSIColor.blue rescue ""),
      PLAIN => "",
      FLOOD => (Term::ANSIColor.bright_black rescue ""),
      TRACE => (Term::ANSIColor.faint rescue "")
    }

    RESET = Term::ANSIColor.reset rescue ""

    @@runtime = Kernel unless defined? @@runtime

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
        @level = Logger.const_get(ENV['CUCUSHIFT_LOG_LEVEL'].upcase)
      else
        @level = INFO
      end
    end

    def time
      @@runtime.puts("#{Time.now.utc}")
    end

    def log(msg, level=INFO, show_datetime='time')
      return if level > self.level

      ## take case of special message types
      case msg
      when Exception
        msg = exception_to_string(msg)
      end

      prefix = PREFIX[level]

      m = ""
      if show_datetime == 'time'
        m = "#{Time.now.utc.strftime("[%H:%M:%S]")} #{prefix}#{msg}"
      elsif show_datetime == 'datetime'
        m ="#{Time.now.utc.strftime("[%Y-%m-%d %H:%M:%S]")} #{prefix}#{msg}"
      else
        m = "#{prefix}#{msg}"
      end

      # set colo/reset terminal if Term::ANSIColor installed, skip otherwise
      m = "#{COLOR[level]}#{m}#{RESET}"

      @@runtime.puts(m)
    end

    def info(msg, show_datetime='time')
      self.log(msg, INFO, show_datetime)
    end

    def warn(msg, show_datetime='time')
      self.log(msg, WARN, show_datetime)
    end

    def error(msg, show_datetime='time')
      self.log(msg, ERROR, show_datetime)
    end

    def debug(msg, show_datetime='time')
      self.log(msg, DEBUG, show_datetime)
    end

    def plain(msg, show_datetime='time')
      self.log(msg, PLAIN, show_datetime)
    end
    alias :print :plain
  end
end
