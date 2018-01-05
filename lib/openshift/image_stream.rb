require 'openshift/project_resource'

module CucuShift
  # represents an OpenShift Image Stream
  class ImageStream < ProjectResource
    RESOURCE = "imagestreams"

    # # should be ready when all items in `Status` have tag
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

    def docker_image_repository(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      rr.dig('status', 'dockerImageRepository')
    end

    def docker_registry_ip_or_hostname(user)
      return self.docker_image_repository(user).match(/[^\/]*\//)[0]
    end

    def tags(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      rr.dig('status', 'tags')
    end

    # some heuristics to try find latest tag's dockerImageReference
    def latest_tag_docker_image_reference(user: nil, cached: true, quiet: false)
      tags = self.tags(user: user, cached: cached, quiet: quiet)
      tag = tags.find {|t| t["tag"] == "latest"}
      unless tag
        tag = tags.first
      end
      return tag["items"].first["dockerImageReference"]
    end

    # get all the items listed for specific tag.
    def tag_items(user: nil, name: nil, cached: true, quiet: false)
      tags = self.tags(user: user, cached: cached, quiet: quiet)
      raise "No tags found for image stream #{self.name}" unless tags.length > 0
      if name
        tag = tags.find{|t| t["tag"] == name}
        raise "No matching tag '#{name}' found" unless tag
        return tag["iterms"]
      else
        return tags.first["items"]
      end
    end
  end
end
