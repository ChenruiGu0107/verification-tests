require 'json'
require 'yaml'
require 'tempfile'

require 'base_helper'

module CucuShift
  # @note represents an OpenShift environment Persistent Volume
  class PersistentVolume
    include Common::Helper
    include Common::UserObjectHelper

    attr_reader :props, :name, :env

    def initialize(name:, env:, props: {})

      if name.nil? || env.nil?
        raise "PersistentVolume need name and environment to be identified"
      end

      @name = name.freeze
      @env = env
      @props = props
    end

    def visible?(user:)
      res = get(user: user)
      case res[:success]
      when /metadata/
        return true
      when /not found/
        return false
      else
        # e.g. when called by user without rights to list PVs
        raise "error getting Persistent Volume existence: #{res[:response]}"
      end
    end
    alias exists? visible?

    def get(user:)
      res = cli_exec(as: user, key: :get,
                resource_name: name,
                resource: "pv",
                output: "yaml")

      if res[:success]
        res[:parsed] = YAML.load(res[:response])
        update_from_api_object(res[:parsed])
      end

      return res
    end
    alias reload get

    # list PVs
    # @param user [CucuShift::User] the user who can list PVs
    # @return [Array<PV>]
    # @note raises error on issues
    def self.list(user:)
      res = user.cli_exec(:get, resource: "pv", output: "yaml")
      if res[:success]
        list = YAML.load(res[:response])["items"]
        return list.map { |pv_hash|
          self.from_api_object(user.env, pv_hash)
        }
      else
        logger.error(res[:response])
        raise "error getting PVs"
      end
    end

    # creates a new PV
    # @param by [CucuShift::User, CucuShift::ClusterAdmin] the user to create PV as
    # @param spec [String, Hash] the API object to create PV or a JSON/YAML file
    # @return [CucuShift::ResultHash]
    def self.create(by:, spec:, **opts)
      if spec.kind_of? String
        name = YAML.load_file(spec)["metadata"]["name"]
      else
        name = spec["metadata"]["name"]
      end

      return self.new(name: spec["metadata"]["name"], env: by.env).
        create(by: by, spec: spec, **opts)
    end

    # creates PV as defined in this object and a spec
    def create(by:, spec:, **opts)
      res = nil
      if spec.kind_of? String
        res = cli_exec(as: by, key: :create, f: spec, **opts)
      else
        file = Tempfile.new(['pv-','.json'])
        begin
          file.write(spec.to_json)
          file.close
          res = cli_exec(as: by, key: :create, f: file.path, **opts)
        ensure
          file.close
          file.unlink
        end
      end

      res[:pv] = self
      return res
    end

    # creates new PV from an OpenShift API PV object
    def self.from_api_object(env, pv_hash)
      self.new(env: env, name: pv_hash["metadata"]["name"]).
                                update_from_api_object(pv_hash)
    end

    def update_from_api_object(pv_hash)
      m = pv_hash["metadata"]

      unless pv_hash["kind"] == "PersistentVolume"
        raise "hash not from a PV: #{pv_hash["kind"]}"
      end
      unless name == m["name"]
        raise "hash from a different PV: #{name} vs #{m["name"]}"
      end

      props[:uid] = m["uid"]
      props[:spec] = pv_hash["spec"]
      # status should be retrieved on demand

      return self # mainly to help ::from_api_object
    end

    def delete(by:)
      cli_exec(as: by, key: :delete, object_type: "pv", object_name_or_id: name)
    end

    # @param status [Symbol, Array<Symbol>] the expected statuses as a symbol
    # @return [Boolean] if PV status is what's expected
    def status?(user:, status:)
      statuses = {
        available: "Available",
        bound: "Bound",
        pending: "Pending",
        released: "Released",
        failed: "Failed",
      }

      res = get(user: user)

      if res[:success]
        expected = status.respond_to?(:map) ?
          status.map{ |s| statuses[s] } :
          [ statuses[status] ]

        res[:success] =
          res[:parsed]["status"] &&
          res[:parsed]["status"]["phase"] &&
          expected.include?(res[:parsed]["status"]["phase"])

        res[:matched_status], garbage = statuses.find { |sym, str|
          str == res[:parsed]["status"]["phase"]
        }
      end

      return res
    end

    def wait_till_status(status, user, seconds)
      res = nil
      success = wait_for(seconds) {
        res = status?(user: user, status: status)
        # if PV failed there's no chance to change status so exit early
        break if [:failed].include?(res[:matched_status])
        res[:success]
      }

      return res
    end

    # @return [CucuShift::ResultHash]
    def wait_to_appear(user, seconds)
      res = nil

      # make sure we fail early if user without permissions
      return get(user: user) if exists?(user: user)

      success = wait_for(seconds) {
        res = get(user: user)
        res[:success]
      }

      return res
    end
    alias wait_to_be_created wait_to_appear

    # @return [Boolean]
    def wait_to_be_deleted(user, seconds = 30)
      return wait_for(seconds) {
        ! exists?(user: user)
      }
    end

    ############### take care of object comparison ###############
    def ==(pv)
      pv.kind_of?(self.class) && name == pv.name && env == pv.env
    end
    alias eql? ==

    def hash
      :pv.hash ^ name.hash ^ env.hash
    end
  end
end
