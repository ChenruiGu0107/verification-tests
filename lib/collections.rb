require 'set'

# should not require 'common'

module CucuShift
  # a collections module that can be included
  module CollectionsIncl
    # @param struc [Object] array, hash or object to be deeply freezed
    # @return [Object] the freezed object
    def deep_freeze(struc)
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
      return struc
    end

    # @param hash [Hash] object to be worked on
    # @yield block to return new key/val pairs based on original values
    # @return modified hash
    def map_hash(hash)
      if hash.kind_of? Hash
        target = {}
        hash.keys.each do |k|
          new_k, new_v = yield [k, hash[k]]
          target[new_k] = new_v
        end
      else
        return hash # return the object itself to aid recursion
      end
      return target # return the object itself to aid recursion
    end

    # @return hash with same content but keys.to_sym
    def hash_symkeys(hash)
      # Hash[hash.collect {|k,v| [k.to_sym, v]}]
      map_hash(hash) { |k, v| [k.to_sym, v] }
    end

    # @param hash [Hash] object to be modified
    # @yield block to return new key/val pairs based on original values
    # @return modified hash
    def map_hash!(hash)
      if hash.kind_of? Hash
        hash.keys.each do |k|
          new_k, new_v = yield [k, hash.delete(k)]
          hash[new_k] = new_v
        end
      end
      return hash # return the object itself to aid recursion
    end

    # @return hash with same content but keys.to_sym
    def hash_symkeys!(hash)
      map_hash!(hash) { |k, v| [k.to_sym, v] }
    end

    # @param hash [Hash] object to be symbolized
    # @yield block to return new key/val pairs based on original values
    def deep_map_hash!(hash)
      map_hash!(hash) { |k, v|
        new_k, new_v = yield [k, v]
        [new_k, deep_map_hash!(new_v) { |nk, nv| yield [nk, nv] }]
      }
    end

    # @param tgt_hash [Hash] target hash that we will be **altering**
    # @param src_hash [Hash] read from this source hash
    # @return the modified target hash
    # @note this one does not merge Arrays
    def deep_merge!(tgt_hash, src_hash)
      tgt_hash.merge!(src_hash) { |key, oldval, newval|
        if oldval.kind_of?(Hash) && newval.kind_of?(Hash)
          deep_merge!(oldval, newval)
        else
          newval
        end
      }
    end

    # Method to covert Cucumber `Table.raw` into a hash
    # @param [Hash|Array] opts normalized Hash or raw array of String options
    # @param [Boolean] sym_mode if true, all keys are converted to Symbols
    # @param [Boolean] array_mode output is a two-dimentional array, not a Hash
    # @return unmodified hash or 2 dimentional array converted to a hash where
    #   multiple instances of same key are converted to `key => [value1, ...]`
    #   and keys starting with `:` are converted to Symbols
    # @note using this method may reorder options when multiple time same
    #   parameter is found; also when key is empty, the value is assumed a
    #   multi-line value
    def opts_array_to_hash(opts, sym_mode: true, array_mode: false)
      case opts
      when Hash
        # we assume that things are normalized when Hash is passed in
        return opts
      when Array
        if opts[0] && opts[0].size != 2
          # we accept empty opts array or array of two element arrays
          raise 'only array of two-values arrays is supported'
        end
        res = array_mode ? [] : {}
        lastval = nil
        opts.each do |key, value|
          key.strip!

          case key
          when ""
            if lastval
              # value modified in-place
              lastval << "\n" << value
              next
            else
              raise "cannot start table with an empty key"
            end
          when /^:/
            key = str_to_sym(key)
          end

          # convert keys to Symbol when in sym_mode
          key = str_to_sym(key) if sym_mode

          lastval = value
          if array_mode
            res << [key, value]
          else
            res[key] = res.has_key?(key) ? [res[key], value].flatten(1) : value
          end
        end

        return res
      else
        raise "unknown options format"
      end
    end
    def opts_array_process(opts, sym_mode: true, array_mode: true)
      opts_array_to_hash(opts, sym_mode: sym_mode, array_mode: array_mode)
    end
  end

  # a module to call the methods directly on
  module Collections
    extend CollectionsIncl
  end

  # a hacked Hash that will track all accessed keys from base_hash
  #class UsageTrackingHash < Hash
  #  def initialize(base_hash)
  #    @base_hash = base_hash
  #    super do |hash, key|
  #      if @base_hash.has_key? key
  #        self[key] = @base_hash[key]
  #      else
  #        nil
  #      end
  #    end
  #  end
  #
  #  def not_accessed_keys
  #    return keys - @base_hash.keys
  #  end
  #end

  # hash like object to that will track all accessed keys from base_hash
  class UsageTrackingHash
    def initialize(base_hash)
      @base_hash = base_hash
      @accessed_keys = Set.new
    end

    def [](k)
      if @base_hash.has_key?(k)
        @accessed_keys << k
        return @base_hash[k]
      else
        return nil
      end
    end

    def has_key?(key)
      return @base_hash.has_key?(key)
    end

    def keys
      @base_hash.keys
    end

    def not_accessed_keys
      return @base_hash.keys - @accessed_keys.to_a
    end
  end
end
