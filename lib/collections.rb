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

    # @param hash [Hash] object to be symbolized
    # @param block to return new key/val pairs based on original values
    def self.map_hash!(hash)
      if hash.kind_of? Hash
        hash.keys.each do |k|
          new_k, new_v = yield [k, hash.delete(k)]
          hash[new_k] = new_v
        end
      end
      return hash # return the object itself to aid recursion
    end

    # @param hash [Hash] object to be symbolized
    # @param block to return new key/val pairs based on original values
    def self.deep_map_hash!(hash)
      map_hash!(hash) { |k, v|
        new_k, new_v = yield [k, v]
        [new_k, deep_map_hash!(new_v) { |nk, nv| yield [nk, nv] }]
      }
    end

    # @param tgt [Hash] target hash that we will be **altering**
    # @param src [Hash] read from this source hash
    # @return the modified target hash
    # @note this one does not merge Arrays
    def self.deep_merge!(tgt_hash, src_hash)
      tgt_hash.merge!(src_hash) { |key, oldval, newval|
        if oldval.kind_of?(Hash) && newval.kind_of?(Hash)
          deep_merge!(oldval, newval)
        else
          newval
        end
      }
    end
  end
end
