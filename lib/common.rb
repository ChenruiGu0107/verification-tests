require 'cucushift'
require 'manager'

module CucuShift
  module Common
    module Helper
      def manager
        CucuShift::Manager.instance
      end

      def conf
        manager.conf
      end

      def logger
        manager.logger
      end

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

      # @return hash with same content but keys.to_sym
      def hash_symkeys(hash)
        Hash[hash.collect {|k,v| [k.to_sym, v]}]
      end

      def exception_to_string(e)
        str = "#{e}\n    #{e.backtrace.join("\n    ")}"
        e = e.cause
        while e do
          str << "\nCaused by: #{e}\n    #{e.backtrace.join("\n    ")}"
          e = e.cause
        end
        return str
      end
    end

    module Setup
      def self.handle_signals
        # Exit the process immediately when SIGINT/SIGTERM caught,
        # since cucumber traps these signals.
        Signal.trap('SIGINT') { Process.exit!(255) }
        Signal.trap('SIGTERM') { Process.exit!(255) }
      end

      def self.set_cucushift_home
        # CucuShift.const_set(:HOME, File.expand_path(__FILE__ + "../../.."))
        CucuShift::HOME.freeze
        ENV["CUCUSHIFT_HOME"] = CucuShift::HOME
      end
    end

  end
end
