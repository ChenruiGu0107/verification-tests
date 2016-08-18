module CucuShift
  class Container
    ### example of a api_struct hash
    #{
    #    "containerID" => "docker://38e6326014bc3b7ac091e851192c3057dea85582060de07df4f0c659e7e99755",
    #          "image" => "172.30.52.166:5000/iiknq/docker-build@sha256:8cf0a92211b0f24b1ab84fab54b37e45ee4c4da7bb75bb0cdddcdd5e00f025fd",
    #        "imageID" => "docker://sha256:d7ed0afa41aec7f3598bcce828ac3fe0444adaeacec180b6ef2b1af2d120d5d3",
    #      "lastState" => {},
    #           "name" => "docker-build",
    #          "ready" => true,
    #   "restartCount" => 0,
    #          "state" => {
    #     "running" => {
    #       "startedAt" => 2016-08-09 21:56:36 UTC
    #     }
    #   }
    # }
    def initialize(api_struct, pod)
      expected_keys = ["containerID", "image", "imageID", "lastState", "name", "ready",  "restartCount", "state", "running"]
      raise "Hash does not have all the expected valued #{expected_keys}" if expected_keys.all? {|s| api_struct.key? s}
      @api_struct = api_struct
      if pod.kind_of? Pod
        @pod = pod
      else
        raise "#{pod} needs to be of type Pod"
      end
    end

    def id
      return @api_struct['containerID'].split('docker://')[1]
    end

    def image
      return @api_struct['image']
    end

    def image_id
      return @api_struct['imageID'].split('docker://')[1]
    end

    def name
      return @api_struct['name']
    end

    # returns true/false
    def ready?
      return @api_struct['ready']
    end

    ### TODO: these two methods need to be dynamic, will need to address them later
    # def restart_count
    #   return @api_struct['restartCount']
    # end

    # def state
    #   return @api_struct['state']
    # end
  end
end
