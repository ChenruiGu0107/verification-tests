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

    def initialize(level=nil, dup_buffer: 50)
      if level
        @level = level
      elsif ENV['CUCUSHIFT_LOG_LEVEL']
        @level = Logger.const_get(ENV['CUCUSHIFT_LOG_LEVEL'].upcase)
      else
        @level = INFO
      end

      if dup_buffer > 0
        @dup_buffer = LogDupBuffer.new(dup_buffer)
      end
    end

    private def dup_buffer
      @dup_buffer
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

      ## take case of special message types
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
        @dup_buffer.dedup(m).each do |m|
          print(construct(m))
        end
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

    def print(msg)
      @@runtime.puts(msg)
    end

    def reset_dedup
      @dup_buffer.reset if @dup_buffer
    end

    # not perfect but working log deduplicator
    class LogDupBuffer
      attr_accessor :buffer, :candidates, :size

      def initialize(size)
        @buffer = []
        # size.times { @buffer << nil }
        @candidates = {} # Hash<offset, size>
        @size = size # target buffer size
      end

      # @param msg [Hash] message hash
      # @return [Array<Hash>] array of message hashes
      # @note basically we take a message, check for dups and return to
      #   whatever can be printed immediately possibly inserting a message like
      #   "last X messages repeated Y times""
      def dedup(msg)
        dups = buffer.size.times.select {|i| buffer[i][:msg] == msg[:msg]}

        if dups.empty?
          # none matches in buffer, print out everything and reset state
          return flush(msg: msg)
        end

        # separate candidates on:
        #   rejected: last message makes them stop matching
        #   new: obvious
        #   ongoing: still candidates
        rejected_candidates = candidates.dup
        new_candidates = {}
        ongoing_candidates = {}
        dups.each do |i|
          candidate_to_update = rejected_candidates.find do |offset, size|
            i == offset + (size % (buffer.size - offset))
          end
          if candidate_to_update
            ongoing_candidates[candidate_to_update[0]] = candidate_to_update[1] + 1
            rejected_candidates.delete(candidate_to_update[0])
          else
            new_candidates[i] = 1
          end
        end

        require 'pry'
        binding.pry if msg[:msg] == "message1" || buffer.last[:msg] == "message1"

        if ongoing_candidates.empty? && new_candidates.empty?
          raise "log deduplicator bug, please report"
          flush(msg: msg)
        elsif ongoing_candidates.empty?
          # all previous candidates have been rejected
          flushres = flush(trim: false)
          self.candidates.replace new_candidates
          return flushres
        else
          self.candidates.replace(ongoing_candidates.merge(new_candidates))
        end

        rejected_max_size = rejected_candidates.reduce(0) do |max, c|
          c[1] > max ? c[1] : max
        end
        ongoing_max_size = ongoing_candidates.reduce(0) do |max, c|
          # here ongoing are already incremented by 1 but we want original
          c[1] - 1 > max ? c[1] - 1 : max
        end

        if rejected_candidates.empty? || rejected_max_size < ongoing_max_size
          # rejected candidates shorter that ongoing candidates, just drop them
          return []
        end

        # now we need to print out part of longest reject
        rejected_max = rejected_candidates.select {|o,s| s == rejected_max_size}

        # if we have longest match at end of queue buffer, then print dups
        at_end = rejected_max.find {|c| c[0] + c[1] >= buffer.size}
        if at_end
          chunk_size = buffer.size - at_end[0]
          # trash all candidates intersecting with that dup
          candidates.keys.each {|i| candidates.delete(i) if i >= at_end[0]}
          # print repeated times and any leftover lines
          return dup_msg(chunk_size, at_end[1]/chunk_size) +
            print_buf(at_end[0], at_end[1] % chunk_size)
        else
          # print only anything that was buffered but never printed
          # here we lose some possible candidates; imagine earlier we trashed
          #   a shorter candidate that was at the end of buffer but now with
          #   these new lines, it would have not been trashed; just too hard to
          #   handle
          return print_buf(rejected_max.first[0], rejected_max_size - ongoing_max_size)
        end
      end

      def dup_msg(num_msg, num_repeats)
        [{ level: Logger::INFO, time: Logger.timestr,
           msg: "last #{num_msg} messages repeated #{num_repeats} times"
        }]
      end

      # return messages to be printed + adds them to buffer and cleans up
      #   buffer if big with adjusting candidates
      def print_buf(buf_offset, length)
        buffer.concat buffer[buf_offset,length]
        trim_buf
        return buffer[buf_offset,length]
      end

      # trim buffer to target size
      def trim_buf
        count = buffer.size - size
        if count > 0 && !candidates.any?{|c| c[0] < count}
          buffer.shift(count)
          shifted_candidates = {}
          candidates.each {|c| shifted_candidates[c[0] - count] = c[1]}
          self.candidates = shifted_candidates
        end
      end

      # flush any messages that were not printed before
      # @param msg [Hash] optional message to add and print
      # @return [Array<Hash>] array of message hashes
      def flush(msg: nil, trim: true)
        # basically print oldest dup candidate up to the offset of the
        #   longest at_end dup candidate, then print at_end dup,
        #   then reset any candidates;
        if candidates.empty?
          if msg
            buffer << msg
            trim_buf
            return [msg]
          else
            return []
          end
        end

        at_end = candidates.select {|o,s| o + s >= buffer.size}.to_a
        if at_end
         at_end_longest = at_end.reduce(at_end[0]) {|max,c| max[1] > c[1] ? max : c}
        end

        longest = candidates.reduce(candidates.to_a[0]) {|max,c| max[1] > c[1] ? max : c}
        if at_end_longest && longest.size == at_end_longest.size
          longest = nil
        end

        if at_end_longest
          partial_res_1 = longest ? buffer[longest[0],(longest[1] - at_end_longest[1])] : []
          chunk_size = buffer.size - at_end_longest[0]
          partial_res_2 = dup_msg(chunk_size, at_end_longest[1]/chunk_size)
          partial_res_3 =
            buffer[at_end_longest[0],(at_end_longest[1]%chunk_size)]
        else
          partial_res_1 = buffer[longest[0],longest[1]]
        end
        partial_res_1 ||= []
        partial_res_2 ||= []
        partial_res_3 ||= []
        partial_res_3 << msg if msg

        buffer.concat partial_res_1
        buffer.concat partial_res_3

        candidates.clear
        trim_buf if trim

        return partial_res_1 + partial_res_2 + partial_res_3
      end

      def reset
        msgs = flush
        buffer.clear
        return msgs
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
    # "messageX",
    "message2",
    "message2",
    "message2",
    "message2",
    "message4",
    "message5",
    "message6",
    "message7",
    "message4",
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
    "message6"
  ]

  logger = CucuShift::Logger.new
  messages.each { |m| logger.info m }

  logger.reset_dedup

  require 'pry'
  binding.pry
end
