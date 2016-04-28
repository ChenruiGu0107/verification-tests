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
            c.key?("tag")
          }
      end

      return res
    end
  end
end
