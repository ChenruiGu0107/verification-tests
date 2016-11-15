require 'openshift/project_resource'

module CucuShift
  # represents an OpenShift PersistentVolumeClaim (pvc for short)
  class PersistentVolumeClaim < ProjectResource
    STATUSES = [:bound, :failed, :pending, :lost]
    RESOURCE = "persistentvolumeclaims"

    # cache some usualy immutable properties for later fast use; do not cache
    #   things that can change at any time like status and spec
    def update_from_api_object(dc_hash)
      props[:metadata] = m = dc_hash["metadata"]
      s = dc_hash["spec"]
      props[:labels] = m["labels"]
      props[:created] = m["creationTimestamp"] # already [Time]
      props[:spec] = s
      props[:status] = dc_hash["status"] # for brave and stupid people

      return self # mainly to help ::from_api_object
    end

    # @return [CucuShift::ResultHash] with :success if status is Bound
    def ready?(user, quiet: false, cached: false)
      status?(user: user, status: :bound, quiet: quiet, cached: cached)
    end

    def volume_name(user: nil, cached: true, quiet: false)
      spec = get_cached_prop(prop: :spec, user: user, cached: cached, quiet: quiet)
      return spec['volumeName']
    end

    def capacity(user: nil, cached: true, quiet: false)
      status = get_cached_prop(prop: :status, user: user, cached: cached, quiet: quiet)
      # I guess would be nil when not bound
      return status.dig('capacity', 'storage')
    end

    def access_modes(user: nil, cached: true, quiet: false)
      status = get_cached_prop(prop: :status, user: user, cached: cached, quiet: quiet)
      return status['accessModes']
    end

    def storage_class(user: nil, cached: true, quiet: false)
      status = get_cached_prop(prop: :metadata, user: user, cached: cached, quiet: quiet).dig("annotations")
      return status['volume.beta.kubernetes.io/storage-class']
    end
  end
end
