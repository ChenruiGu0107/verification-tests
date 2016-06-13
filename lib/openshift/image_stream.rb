require 'openshift/project_resource'

module CucuShift
  # represents an OpenShift Image Stream
  class ImageStream < ProjectResource
    RESOURCE = "imagestreams"

    # cache some usually immutable properties for later fast use; do not cache
    #   things that can change at any time
    def update_from_api_object(is_hash)
      m = is_hash["metadata"]
      props[:uid] = m["uid"]
      props[:selfLink] = m["selfLink"]
      props[:created] = m["creationTimestamp"] # already [Time]

      s = is_hash["status"]
      props[:docker_image_repository] = s["dockerImageRepository"]

      return self # mainly to help ::from_api_object
    end

    # should be ready when all items in `Status` have tag
    def ready?(user:, quiet: false)
      res = get(user: user, quiet: quiet)

      if res[:success]
        res[:success] =
          res[:parsed]["status"]["tags"] &&
          res[:parsed]["status"]["tags"].length > 0 &&
          res[:parsed]["status"]["tags"].all? { |c|
            c["items"] && c["items"].length > 0
          }
      end

      return res
    end

    def docker_image_repository(user:, cached: true, quiet: false)
      return get_cached_prop(prop: :docker_image_repository, user: user, cached: cached, quiet: quiet)
    end
  end
end
