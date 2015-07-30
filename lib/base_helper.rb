# should not require 'common'
# should only include helpers that do NOT load any other cucushift classes

module CucuShift
  module Common
    module BaseHelper
      def to_bool(param)
        return false unless param
        if param.kind_of? String
          return !!param.downcase.match(/^(true|t|yes|y|on|[0-9]*[1-9][0-9]*)$/i)
        elsif param.respond_to? :empty?
          # true for non empty maps and arrays
          return ! param.empty?
        else
          # lets be more conservative here
          return !!param.to_s.downcase.match(/^(true|yes|on)$/)
        end
      end

      def word_to_num(which)
        if which =~ /first|default/
          return 0
        elsif which =~ /other|another|second/
          return 1
        elsif which =~ /third/
          return 2
        elsif which =~ /fourth/
          return 3
        elsif which =~ /fifth/
          return 4
        end
        raise "can't translate #{which} to a number"
      end

      # normalize strings used for keys
      # @param [String] key the key to be converted
      # @return string converted to a Symbol key
      def str_to_sym(key)
        return key if key.kind_of? Symbol
        return key.gsub(" ", "_").sub(/^:/,'').to_sym
      end

      def exception_to_string(e)
        str = "#{e.inspect}\n    #{e.backtrace.join("\n    ")}"
        e = e.cause
        while e do
          str << "\nCaused by: #{e.inspect}\n    #{e.backtrace.join("\n    ")}"
          e = e.cause
        end
        return str
      end

      def rand_str(length=8, compat=:nospace_sane)
        raise if length < 1

        result = ""
        array = []

        case compat
        when :dns
          #  matching regex [a-z0-9]([-a-z0-9]*[a-z0-9])?
          #  e.g. project name (up to 63 chars)
          for c in 'a'..'z' do array.push(c) end
          for n in '0'..'9' do array.push(n) end
          array << '-'

          result << array[rand(36)] # needs to start with non-hyphen
          (length - 2).times { result << array[rand(array.length)] }
          result << array[rand(36)] # end with non-hyphen
        when :dns952
          # matching regex [a-z]([-a-z0-9]*[a-z0-9])?
          # e.g. service name (up to 24 chars)
          for c in 'a'..'z' do array.push(c) end
          for n in '0'..'9' do array.push(n) end
          array << '-'

          result << array[rand(26)] # start with letter
          (length - 2).times { result << array[rand(array.length)] }
          result << array[rand(36)] # end with non-hyphen
        else # :nospace_sane
          for c in 'a'..'z' do array.push(c) end
          for c in 'A'..'Z' do array.push(c) end
          for n in '0'..'9' do array.push(n) end

          # avoid hiphen in the beginning to not confuse cmdline
          result << array[rand(array.length)] # begin with non-hyphen
          array << '-' << '_'

          (length - 1).times { result << array[rand(array.length)] }
        end

        return result
      end

      # replace <something> strings inside strings given option hash with symbol
      #   keys
      # @param [String] str string to replace
      # @param [Hash] opts hash options to use for replacement
      def replace_angle_brackets!(str, opts)
        str.gsub!(/<(.+?)>/) { |m|
          opt_key = m[1..-2].to_sym
          opts[opt_key] || raise("need to provide '#{opt_key}' REST option")
        }
      end

      # platform independent way to get monotonic timer seconds
      def monotonic_seconds
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      # repeats block until it returns true or timeout reached; timeout not
      #   strictly enforced, use other timeout techniques to avoid freeze
      # @param seconds [Numeric] the max number of seconds to try operation to
      #   succeed
      # @yield block the block will be yielded until it returns true or timeout
      #   is reached
      def wait_for(seconds)
        if seconds > 60
          Kernel.puts("waiting for operation up to #{seconds} seconds..")
        end

        start = monotonic_seconds
        success = false
        until monotonic_seconds - start > seconds
          success = yield and break
          sleep 1
        end

        return success
      end
    end
  end
end
