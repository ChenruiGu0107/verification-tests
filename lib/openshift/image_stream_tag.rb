require 'openshift/project_resource'

module CucuShift
  # represents an OpenShift Image Stream Tag
  class ImageStreamTag < ProjectResource
    RESOURCE = "imagestreamtags"

    # cache some usually immutable properties for later fast use; do not cache
    # things that can change at any time
    def update_from_api_object(istag_hash)

      props[:metadata] = m = istag_hash["metadata"]
      props[:image] = i = istag_hash["image"]
      props[:docker_image_metadata] = i["dockerImageMetadata"]

      return self # mainly to help ::from_api_object
    end

    def digest(user:, cached: true, quiet: false)
      return get_cached_prop(prop: :image, user: user, cached: cached, quiet: quiet).dig("metadata", "name")
    end

    def docker_version(user:, cached: true, quiet: false)
      return get_cached_prop(prop: :docker_image_metadata, user: user, cached: cached, quiet: quiet).dig("DockerVersion")
    end

    def annotations(user:, cached: true, quiet: false)
      return get_cached_prop(prop: :image, user: user, cached: cached, quiet: quiet).dig("metadata", "annotations")
    end

    def labels(user:, cached: true, quiet: false)
      return get_cached_prop(prop: :docker_image_metadata, user: user, cached: cached, quiet: quiet).dig("Config", "Labels")
    end

    def config_user(user:, cached: true, quiet: false)
      return get_cached_prop(prop: :docker_image_metadata, user: user, cached: cached, quiet: quiet).dig("Config", "User")
    end

    def config_env(user:, cached: true, quiet: false)
      return get_cached_prop(prop: :docker_image_metadata, user: user, cached: cached, quiet: quiet).dig("Config", "Env")
    end

    def config_cmd(user:, cached: true, quiet: false)
      return get_cached_prop(prop: :docker_image_metadata, user: user, cached: cached, quiet: quiet).dig("Config", "Cmd")
    end

    def workingdir(user:, cached: true, quiet: false)
      return get_cached_prop(prop: :docker_image_metadata, user: user, cached: cached, quiet: quiet).dig("Config", "WorkingDir")
    end

    def exposed_ports(user:, cached: true, quiet: false)
      return get_cached_prop(prop: :docker_image_metadata, user: user, cached: cached, quiet: quiet).dig("Config", "ExposedPorts")
    end

    def image_layers(user:, cached: true, quiet: false)
      return get_cached_prop(prop: :image, user: user, cached: cached, quiet: quiet).dig("dockerImageLayers")
    end
  end
end
