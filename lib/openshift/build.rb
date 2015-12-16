require 'common'

module CucuShift
  # represents an OpenShift build
  class Build
    include Common::Helper
    include Common::UserObjectHelper
    extend  Common::BaseHelper

    TERMINAL_STATUSES = [:complete, :failed, :cancelled, :error]

    attr_reader :props, :name, :project

    # @param name [String] name of the build
    # @param project [CucuShift::Project] the project this build belongs to
    # @param props [Hash] additional properties of the build
    def initialize(name:, project:, props: {})
      @name = name
      @project = project
      @props = props
    end

    # creates new Build object from an OpenShift API Pod object
    def self.from_api_object(project, build_hash)
      self.new(project: project, name: build_hash["metadata"]["name"]).
                                update_from_api_object(build_hash)
    end

    # cache some usualy immutable properties for later fast use; do not cache
    #   things that can change at any time like status and spec
    def update_from_api_object(build_hash)
      m = build_hash["metadata"]
      s = build_hash["spec"]

      if name != m["name"]
        raise "looks like a hash from another account: #{name} vs #{m["name"]}"
      end
      if m['namespace'] != project.name
        raise "looks like account from another project: #{project.name} vs #{m['namespace']}"
      end

      props[:uid] = m["uid"]
      props[:labels] = m["labels"]
      props[:created] = m["creationTimestamp"] # already [Time]

      props[:spec] = s

      return self # mainly to help ::from_api_object
    end

    def get(user:)
      res = cli_exec(as: user, key: :get, n: project.name,
                resource_name: name,
                resource: "build",
                output: "yaml")

      if res[:success]
        res[:parsed] = YAML.load(res[:response])
        update_from_api_object(res[:parsed])
      end

      return res
    end
    alias reload get

    def exists?(user:)
      res = get(user: user)

      unless res[:success] || res[:response].include?("not found")
        raise "error getting build from API"
      end

      res[:success] = ! res[:success]
      return res
    end

    # @param status [Symbol, Array<Symbol>] the expected statuses as a symbol
    # @return [Boolean] if build status is what's expected
    def status?(user:, status:)

      # see https://github.com/openshift/origin/blob/master/pkg/build/api/v1/types.go (look for `const` definition)
      statuses = {
        complete: "Complete",
        running: "Running",
        pending: "Pending",
        new: "New",
        failed: "Failed",
        error: "Error",
        cancelled: "Cancelled"
      }

      res = get(user: user)

      if res[:success]
        status = status.respond_to?(:map) ?
          status.map{ |s| statuses[s] } :
          [ statuses[status] ]

        res[:success] =
          res[:parsed]["status"] &&
          res[:parsed]["status"]["phase"] &&
          status.include?(res[:parsed]["status"]["phase"])

        res[:matched_status], garbage = statuses.find { |sym, str|
          str == res[:parsed]["status"]["phase"]
        }
      end

      return res
    end

    # @return [CucuShift::ResultHash] :success if build completes regardless of
    #   completion status
    def finished?(user:)
      status?(user: user, status: TERMINAL_STATUSES)
    end

    # @return [CucuShift::ResultHash] with :success depending on status
    def completed?(user:)
      status?(user: user, status: :complete)
    end

    # @return [CucuShift::ResultHash] with :success depending on status
    def failed?(user:)
      status?(user: user, status: :failed)
    end

    # @return [CucuShift::ResultHash] with :success depending on status
    def running?(user:)
      status?(user: user, status: :running)
    end

    # @return [CucuShift::ResultHash] with :success true if we've eventually got
    #   the build finished regardless of status, false if build never started or
    #   still running; the result hash is from last executed get call
    def wait_till_finished(user, seconds)
      res = nil
      wait_for(seconds) {
        res = finished?(user: user)
        res[:success]
      }
      return res
    end

    # @return [CucuShift::ResultHash] with :success true if we've eventually got
    #   the build completed; the result hash is from last executed get call
    def wait_till_completed(user, seconds)
      wait_till_status(:complete, user, seconds)
    end

    # @return [CucuShift::ResultHash] with :success true if we've eventually got
    #   the build failed; the result hash is from last executed get call
    def wait_till_failed(user, seconds)
      wait_till_status(:failed, user, seconds)
    end

    def wait_till_cancelled(user, seconds)
      wait_till_status(:cancelled, user, seconds)
    end

    def wait_till_running(user, seconds)
      wait_till_status(:running, user, seconds)
    end

    def wait_till_status(status, user, seconds)
      res = nil
      success = wait_for(seconds) {
        res = status?(user: user, status: status)
        # if build finished there's little chance to change status so exit early
        if !res[:success] && !status_can_change?(res[:matched_status], status)
          break
        end
        res[:success]
      }

      return res
    end

    # @param from_status [Symbol] the status we currently see
    # @param to_status [Array, Symbol] the status(es) we check whether current
    #   status can change to
    # @return [Boolean] true if it is possible to transition between the
    #   specified statuses (same -> same is not a transition)
    def status_can_change?(from_status, to_status)
      if TERMINAL_STATUSES.include?(from_status)
        if from_status == :failed &&
            [ to_status ].flatten.include?(:cancelled)
          return true
        end
        return false
      end
      return true
    end

    def wait_to_appear(user, seconds)
      res = nil
      success = wait_for(seconds) {
        res = get(user: user)
        res[:success]
      }

      return res
    end

    # @param labels [String, Array<String,String>] labels to filter on, read
    #   [CucuShift::Common::BaseHelper#selector_to_label_arr] carefully
    def self.wait_for_labeled(*labels, user:, project:, seconds:)
      wait_for_matching(user: user, project: project, seconds: seconds,
                        get_opts: {l: selector_to_label_arr(*labels)}) {true}
    end

    # @yield block that selects builds by returning true; see [#get_matching]
    # @return [CucuShift::ResultHash] with :matching key being array of matched
    #   builds;
    def self.wait_for_matching(user:, project:, seconds:, get_opts: {})
      res = nil

      wait_for(seconds) {
        res = get_matching(user: user, project: project, get_opts: get_opts) { |p, p_hash|
          yield p, p_hash
        }
        ! res[:matching].empty?
      }

      return res
    end

    # @yield block that selects builds by returning true; block receives
    #   |build, build_hash| as parameters where build is a reloaded [Build]
    # @return [CucuShift::ResultHash] with :matching key being array of matched
    #   builds
    def self.get_matching(user:, project:, get_opts: {})
      opts = {resource: 'build', n: project.name, o: 'yaml'}
      opts.merge! get_opts
      res = user.cli_exec(:get, **opts)

      if res[:success]
        res[:parsed] = YAML.load(res[:response])
        res[:builds] = res[:parsed]["items"].map { |b|
          self.from_api_object(project, b)
        }
      else
        user.logger.error(res[:response])
        raise "cannot get builds for project #{project.name}"
      end

      res[:matching] = []
      res[:builds].zip(res[:parsed]["items"]) { |b, b_hash|
        res[:matching] << b if !block_given? || yield(b, b_hash)
      }

      return res
    end
    class << self
      alias list get_matching
    end

    def env
      project.env
    end

    def ==(b)
      b.kind_of?(self.class) && name == b.name && project == b.project
    end
    alias eql? ==

    def hash
      :build.hash ^ name.hash ^ project.hash
    end
  end
end
