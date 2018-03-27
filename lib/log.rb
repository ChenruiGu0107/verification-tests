lib_path = File.expand_path(File.dirname(__FILE__))
unless $LOAD_PATH.any? {|p| File.expand_path(p) == lib_path}
    $LOAD_PATH.unshift(lib_path)
end

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

    def dedup_start
      require 'strscan'

      @dup_buffer = LogDupBuffer.new
    end

    def dedup_flush
      @dup_buffer && @dup_buffer.flush(self)
      @dup_buffer = nil
    end

    def time
      print("#{Time.now.utc}")
    end

    def self.timestr
      Time.now.utc.strftime("[%H:%M:%S]")
    end

    def self.datetimestr
      Time.now.utc.strftime("[%Y-%m-%d %H:%M:%S]")
    end

    def log(msg, level=INFO, show_datetime='time')
      return if level > self.level

      ## take care of special message types
      case msg
      when Exception
        msg = exception_to_string(msg)
      end

      if show_datetime == 'time'
        timestamp = Logger.timestr + " "
      elsif show_datetime == 'datetime'
        timestamp = Logger.datetimestr + " "
      else
        timestamp = ''
      end

      m = {msg: msg, level: level, timestamp: timestamp}
      if @dup_buffer
        @dup_buffer.push(m)
      else
        print(construct(m))
      end
    end

    def construct(msg)
      "#{COLOR[msg[:level]]}#{msg[:timestamp]}#{PREFIX[msg[:level]]}#{msg[:msg]}#{RESET}"
    end

    def info(msg, show_datetime='time')
      self.log(msg, INFO, show_datetime)
    end
    alias << info

    def warn(msg, show_datetime='time')
      self.log(msg, WARN, show_datetime)
    end

    def error(msg, show_datetime='time')
      self.log(msg, ERROR, show_datetime)
    end

    def debug(msg, show_datetime='time')
      self.log(msg, DEBUG, show_datetime)
    end

    def trace(msg, show_datetime='time')
      self.log(msg, TRACE, show_datetime)
    end

    def plain(msg, show_datetime='time')
      self.log(msg, PLAIN, show_datetime)
    end

    def print(msg)
      @@runtime.puts(msg)
    end

    # supports embedding content similar with same semantics as Cucumber
    def embed(src, mime_type, label)
      if @@runtime.respond_to? :embed
        info "embedding #{label.inspect}"
        @@runtime.embed src, mime_type, label
      else
        if !src.kind_of?(String) || src.empty?
          warn "empty embedding #{label}??"
        elsif (File.file?(src) rescue false)
          info "Embedding request for file: #{File.absolute_path(src)}"
        elsif src =~ /\A[[:print:]]*\z/
          print "Embedded #{mime_type} data labeled #{label}:\n#{src}"
        else
          print "Unrecognized #{mime_type} data labeled #{label} (Base64):\n#{Base64.encode64 src}"
        end
      end
    end

    def reset_dedup
      @dup_buffer.reset if @dup_buffer
    end

    # map messages to unique characters, then run a regular expression to
    #   catch duplicates, finally convert back
    class LogDupBuffer
      RE = /(.+?)\1+/ # /((.+?)\2+)/

      attr_accessor :strings, :messages

      def initialize()
        @strings = []
        @messages = []
      end

      def push(msg)
        msg_idx = strings.find_index(msg[:msg])
        unless msg_idx
          msg_idx = strings.size
          strings << msg[:msg]
        end

        msg[:msg] = msg_idx
        @messages << msg
      end

      def format
        if strings.size > 256
          format = "U*"
        else
          format = "C*"
        end
      end

      def tokenize(strlog)
        ss = StringScanner.new(strlog)
        res = []
        lastpos = 0

        while ss.skip_until(RE)
          matched_pos = ss.pos - ss.matched_size
          pre_match_size = matched_pos - lastpos
          res << [strlog[lastpos...matched_pos], 1] if pre_match_size > 0
          lastpos = ss.pos
          # after the fact I figured we don't need exact sequences, only length
          #   but leaving it like that for the time being
          res << [ss[1], ss.matched_size/ss[1].size]
        end

        res << [ss.rest, 1] if ss.rest?

        ## safety check
        processed = res.reduce(0) {|sum, seq| sum + seq[0].size * seq[1]}
        raise "tokanized #{processed} but had #{strlog.size}" if processed != strlog.size

        return res
      end

      # destructive to messages array, but we don't care at this point
      def print(logger, tokenized_log)
        format = self.format
        msg_idx = 0
        tokenized_log.each do |seq, rep|
          seq.size.times do |sidx|
            # in fact we don't need unpack because message contains its string
            #   index and we track message index
            messages[msg_idx][:msg] = strings[messages[msg_idx][:msg]]
            logger.print(logger.construct(messages[msg_idx]))
            msg_idx = msg_idx + 1
          end
          if rep > 1
            msg_idx = msg_idx + seq.size * ( rep - 1 )
            logger.print(logger.construct({
              level: Logger::INFO,
              timestamp: messages[msg_idx - 1][:timestamp],
              msg: "last #{seq.size} messages repeated #{rep - 1} times"
            }))
          end
        end
        raise "bad dedup indexing #{msg_idx} vs #{messages.size}" if msg_idx != messages.size
      end

      def flush(logger)
        strlog = messages.map {|m| m[:msg]}.pack(format)

        tokenized_log = tokenize strlog
        print(logger, tokenized_log)
        reset
      end

      def reset
        strings.clear
        messages.clear
      end
    end
  end
end

## Standalone test
if __FILE__ == $0
  messages = [
    "message1",
    "message1",

    "message2",
    "message3",
    "message4",
    "message5",
    "message6",
    "message1",
    "message1",

    "message2",
    "message2",
    "message2",
    "message2",

    "message4",
    "message5",
    "message5",
    "message5",
    "message6",
    "message7",

    "message4",
    "message5",
    "message5",
    "message5",
    "message6",
    "message7",

    "message1",
    "message2",
    "message3",
    "message4",
    "message5",

    "message1",
    "message2",
    "message3",
    "message4",
    "message5",

    "message8",
    "message3",
    "message2",
    "message4",
    "message5",

    "message6",
    "message6",
    "message6",
    "message3"
  ]

  res = [
    "message1",
    "1 messages repeated 1",
    "message2",
    "message3",
    "message4",
    "message5",
    "message6",
    "message1",
    "1 messages repeated 1",
    "message2",
    "1 messages repeated 3",
    "message4",
    "message5",
    "message5",
    "message5",
    "message6",
    "message7",
    "6 messages repeated 1",
    "message1",
    "message2",
    "message3",
    "message4",
    "message5",
    "5 messages repeated 1",
    "message8",
    "message3",
    "message2",
    "message4",
    "message5",
    "message6",
    "1 messages repeated 2",
    "message3"
  ]

  logger = CucuShift::Logger.new

  logger.dedup_start
  messages.each { |m| logger.info m }
  logger.dedup_flush

  # TODO: check expected result with custom logger runtime

  require 'pry'
  binding.pry
end
