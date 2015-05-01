# should not require 'common'

module CucuShift
  module Collections
    def self.deep_freeze(struc)
      struc.freeze
      if struc.kind_of? Hash
        struc.each do |k, v|
          # deep_freeze(k) # keys are freezed already by ruby
          deep_freeze(v)
        end
      elsif struc.respond_to? :each
        struc.each do |el|
          deep_freeze(el)
        end
      else
        # we don't know how to go deeper here
      end
    end

    # @param [Hash] hash object to be symbolized
    def self.deep_sym_keys(obj)
      if obj.kind_of? Hash
        obj.each do |k, v|
          obj[k.to_sym] = deep_sym_keys(obj.delete(k))
        end
      end
    end

    def self.monkey_patch_deep_merge(hash_object)
      hash_object.instance_eval <<      EOT
      def deep_merge!(hash)
        hash.each do |k, v|
          if self[k].kind_of?(Hash) and hash[k].kind_of?(Hash)
            Collections.monkey_patch_deep_merge(self[k])
            self[k].deep_merge!(hash[k])
          else
            self[k] = hash[k]
          end
        end
      end
      EOT
    end
  end
end
