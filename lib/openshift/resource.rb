# TODO: frozen_string_literal: true

require 'yaml'
require 'common'

module CucuShift
  # @note represents a Resource / OpenShift API Object
  class Resource
    include Common::Helper
    include Common::UserObjectHelper
    extend  Common::BaseHelper

    # this needs to be set per sub class
    # represents the string we use with `oc get ...`
    # also represents string we use in REST call URL path
    # e.g. RESOURCE = "pods"

    attr_reader :props, :name
    attr_writer :default_user

    def annotation(annotation_name, user:, cached: true, quiet: false)
      options = {
        prop:   :annotations,
        user:   user,
        quiet:  quiet,
        cached: cached,
      }.freeze

      get_cached_prop(options)&.fetch(annotation_name, nil)
    end

    def created_at(user:, cached: true, quiet: false)
      get_cached_prop(prop: :created, user: user, cached: cached, quiet: quiet)
    end
    alias created created_at

    def env
      raise "need to be implemented by subclass"
    end

    def visible?(user:, result: {}, quiet: false)
      result.clear.merge!(get(user: user, quiet: quiet))
      if result[:success]
        return true
      elsif result[:response] =~ /not found/
        return false
      else
        # e.g. when called by user without rights to list Resource
        raise "error getting #{self.class.name} '#{name}' existence: #{result[:response]}"
      end
    end
    alias exists? visible?

    def get_checked(user: nil, quiet: false)
      res = get(user: user, quiet: quiet)
      unless res[:success]
        logger.error(res[:response])
        raise "could not get self.class::RESOURCE"
      end
      return res
    end

    def get(user: nil, quiet: false)
      user = default_user(user)

      get_opts = {
        as: user, key: :get,
        resource_name: name,
        resource: self.class::RESOURCE,
        output: "yaml"
      }
      get_opts[:_quiet] = true if quiet

      if defined? project
        get_opts[:namespace] = project.name
      end

      res = cli_exec(get_opts)

      if res[:success]
        res[:parsed] = YAML.load(res[:response])
        update_from_api_object(res[:parsed])
      end

      return res
    end
    alias reload get

    def default_user(user=nil)
      if user
        default_user = user unless @default_user
        return user
      elsif @default_user
        return @default_user
      else
        raise("must specify user for the operation")
      end
    end

    # update multiple API resources in as little calls as possible
    # @param user [User] the user to use for the API calls
    # @param resources [Array<Resource>]
    # @return [Array<Resource>] if any resources have not been found
    def self.bulk_update(user:, resources:, quiet: true)
      groups = resources.group_by(&:class).map(&:last)
      return groups.map { |group|
        group[0].class.bulk_update(user: user, resources: group, quiet: quiet)
      }.reduce([], :+)
    end

    # @param res [Hash] if caller wants to see result from the get call;
    #   note that it might not be updated if property returned from cache
    def get_cached_prop(prop:, user: nil, cached: false, quiet: false, res: nil)
      if res && cached
        raise "result cannot be returned with cached requests"
      end

      unless cached && props[prop]
        res ||= {}
        res.merge! get_checked(user: user, quiet: quiet)
      end

      return props[prop]
    end

    private def raw_resource(user: nil, cached: false, quiet: false, res: nil)
      get_cached_prop(prop: :raw, user: user, cached: cached, quiet: quiet, res: res)
    end

    def update_from_api_object(hash)
      case
      when hash["kind"] != shortclass
        raise "hash not from a #{shortclass}: #{hash["kind"]}"
      when name != hash["metadata"]["name"]
        raise "hash from a different #{shortclass}: #{name} vs #{hash["metadata"]["name"]}"
      when self.respond_to?(:project) &&
           hash["metadata"]&.has_key?("namespace") &&
           project.name != hash["metadata"]["namespace"]
        raise "hash from a #{shortclass} of a different namespace '#{project}"
      end

      props[:raw] = Collections.deep_freeze(hash)

      return self # mainly to help ::from_api_object
    end

    # subclasses need to implement #delete method
    def delete_graceful(by:)
      res = delete(by: by)

      # this will actually fail for mising project when run by a regular user;
      # we can override this method in project.rb but I'm thinking that
      #  ensuring project deleted is not a regular user's job, just like
      #  user cannot ensure PVs are deleted
      res[:success] = res[:success] || res[:response].include?("not found")

      return res
    end

    def ensure_deleted(user: , wait: 60)
      res = delete_graceful(by: user)

      unless res[:success]
        raise "cannot delete #{self.class} #{name}"
      end
      unless disappeared?(user, wait)
        raise "#{self.class} #{name} did not disappear within #{wait} sec"
      end

      return res
    end

    # @return [CucuShift::ResultHash]
    def wait_to_appear(user, seconds = 30)
      res = {}
      iterations = 0
      start_time = monotonic_seconds

      wait_for(seconds) {
        exists?(user: user, result: res, quiet: true)

        logger.info res[:command] if iterations == 0
        iterations = iterations + 1

        res[:success]
      }

      duration = monotonic_seconds - start_time
      logger.info "After #{iterations} iterations and #{duration.to_i} " <<
        "seconds:\n#{res[:response]}"

      return res
    end
    alias wait_to_be_created wait_to_appear

    # @return [Boolean]
    def disappeared?(user, seconds = 30)
      res = {}
      iterations = 0
      start_time = monotonic_seconds

      wait_for(seconds) {
        visible?(user: user, result: res, quiet: true)

        logger.info res[:command] if iterations == 0
        iterations = iterations + 1

        !res[:success]
      }

      duration = monotonic_seconds - start_time
      logger.info "After #{iterations} iterations and #{duration.to_i} " <<
        "seconds:\n#{res[:response]}"

      return !res[:success]
    end
    alias wait_to_disappear disappeared?

    # @return [Hash] the raw status of resource as returned by API
    def status_raw(user: nil, cached: false, quiet: false)
      if cached && props[:status]
        return props[:status]
      else
        res = get(user: user, quiet: quiet)
        if cached && !props[:status]
          raise "#{self.class}} does not cache status"
        end
        if res[:success]
          return props[:status]
        elsif res[:response].include?('not found')
          return props[:status] = {"phase" => "Missing"}
        else
          raise "cannot get #{self.class::RESOURCE} #{name}: #{res[:response]}"
        end
      end
    end

    def phase(user: nil, cached: false, quiet: false)
      return status_raw(user: user, cached: cached, quiet: quiet)["phase"].downcase.to_sym
    end

    # @param status [Symbol, Array<Symbol>] the expected statuses as a symbol
    # @return [ResultHash]
    def status?(user: nil, status:, quiet: false, cached: false)
      matched_status = phase(user: user, quiet: quiet, cached: cached)
      status = [ status ].flatten
      res = {
        instruction: "get #{cached ? 'cached' : ''} #{self.class::RESOURCE} #{name} status",
        response: "matched status for #{self.class::RESOURCE} #{name}: '#{matched_status}' while expecting '#{status}'",
        matched_status: matched_status,
        exitstatus: 0
      }

      #Check if the user-provided status actually exists
      if defined?(self.class::STATUSES)
        unknown_statuses = status - [:missing] - self.class::STATUSES
        unless unknown_statuses.empty?
          raise "some requested statuses are unknown: #{unknown_statuses}"
        end
      end
      res[:success] = status.include? matched_status
      return res
    end

    # @return [CucuShift::ResultHash] with :success true if we've eventually got
    #   the resource in ready status; the result hash is from last executed
    #   get call
    # @note sub-class needs to implement the `#ready?` method
    def wait_till_ready(user, seconds)
      res = nil
      iterations = 0
      start_time = monotonic_seconds

      success = wait_for(seconds) {
        res = ready?(user: user, quiet: true)

        logger.info res[:command] if iterations == 0
        iterations = iterations + 1

        res[:success]
      }

      duration = monotonic_seconds - start_time
      logger.info "After #{iterations} iterations and #{duration.to_i} " <<
        "seconds:\n#{res[:response]}"

      return res
    end

    # waits until resource status is reached
    # @note this method requires sub-class to define the `#status?` method
    def wait_till_status(status, user, seconds)
      res = nil
      iterations = 0
      start_time = monotonic_seconds

      success = wait_for(seconds) {
        res = status?(user: user, status: status, quiet: true)

        logger.info res[:command] if iterations == 0
        iterations = iterations + 1

        # if build finished there's little chance to change status so exit early
        if !status_reachable?(res[:matched_status], status)
          break
        end
        res[:success]
      }

      duration = monotonic_seconds - start_time
      logger.info "After #{iterations} iterations and #{duration.to_i} " <<
        "seconds:\n#{res[:response]}"

      return res
    end

    # @param from_status [Symbol] the status we currently see
    # @param to_status [Array, Symbol] the status(es) we check whether current
    #   status can change to
    # @return [Boolean] true if it is possible to transition between the
    #   specified statuses (same -> same should also be true)
    # @note dummy class for generic use but better overload in sub-class
    def status_reachable?(from_status, to_status)
      true
    end

    # TODO: implement fallback `#status?` method

    def self.shortclass
      self.name.split("::").last
    end

    def shortclass
      self.class.shortclass
    end

    ############### take care of object comparison ###############
    def ==(resource)
      raise "need to be implemented by subclass"
    end
    alias eql? ==

    def hash
      raise "need to be implemented by subclass"
    end
  end
end
