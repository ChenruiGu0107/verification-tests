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

      def rand_str(length=8)
        result = Array.new
        array = Array.new
        for c in 'a'..'z' do array.push(c) end
        for c in 'A'..'Z' do array.push(c) end
        for n in '0'..'1' do array.push(n) end
        result.push(array[rand(26)])
        for i in 1..length-1
          result.push(array[rand(array.length)])
        end
        return result.join
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
    end
  end
end
