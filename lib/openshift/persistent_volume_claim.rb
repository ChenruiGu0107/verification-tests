require 'openshift/project_resource'

module CucuShift
  # represents an OpenShift PersistentVolumeClaim (pvc for short)
  class PersistentVolumeClaim < ProjectResource
    RESOURCE = "persistentvolumeclaims"

    # cache some usualy immutable properties for later fast use; do not cache
    #   things that can change at any time like status and spec
    def update_from_api_object(dc_hash)
      m = dc_hash["metadata"]
      s = dc_hash["spec"]
      props[:labels] = m["labels"]
      props[:created] = m["creationTimestamp"] # already [Time]
      props[:spec] = s

      return self # mainly to help ::from_api_object
    end

    # @param status [Symbol, Array<Symbol>] the expected statuses as a symbol
    # @return [Boolean] if pvc status is what's expected
    def status?(user:, status:, quiet: false)
      statuses = {
        bound: "Bound",
        failed: "Failed",
        pending: "Pending",
      }
      # in fact `#get` should work here but leaving describe for shorter
      # we need to use get if we want properties cache updated
      res = describe(user, quiet: quiet)
      if res[:success]
        res[:success] = res[:parsed][:overall_status] == statuses[status]
      end
      return res
    end

    # @return [CucuShift::ResultHash] with :success if status is Bound
    def ready?(user, quiet: false)
      status?(user: user, status: :bound, quiet: quiet)
    end
  end
end
