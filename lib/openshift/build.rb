require 'openshift/project_resource'

module CucuShift
  # represents an OpenShift build
  class Build < ProjectResource

    RESOURCE = "builds"
    TERMINAL_STATUSES = [:complete, :failed, :cancelled, :error]

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

    # @param status [Symbol, Array<Symbol>] the expected statuses as a symbol
    # @return [Boolean] if build status is what's expected
    def status?(user:, status:, quiet: false)

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

      res = get(user: user, quiet: quiet)

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
    def finished?(user:, quiet: false)
      status?(user: user, status: TERMINAL_STATUSES, quiet: quiet)
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
      iterations = 0
      start_time = monotonic_seconds

      wait_for(seconds) {
        res = finished?(user: user, quiet: true)

        logger.info res[:command] if iterations == 0
        iterations = iterations + 1

        res[:success]
      }

      duration = monotonic_seconds - start_time
      logger.info "After #{iterations} iterations and #{duration.to_i} " <<
        "seconds:\n#{res[:response]}"

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

    def wait_till_pending(user, seconds)
      wait_till_status(:pending, user, seconds)
    end

    def wait_till_status(status, user, seconds)
      res = nil
      iterations = 0
      start_time = monotonic_seconds

      success = wait_for(seconds) {
        res = status?(user: user, status: status, quiet: true)

        logger.info res[:command] if iterations == 0
        iterations = iterations + 1

        # if build finished there's little chance to change status so exit early
        if !res[:success] && !status_can_change?(res[:matched_status], status)
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
  end
end
