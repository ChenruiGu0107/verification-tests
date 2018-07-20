require 'openshift/flakes/limit_range_item'

module CucuShift
  # https://docs.openshift.com/online/rest_api/api/v1.LimitRange.html
  class LimitRange < ProjectResource
    RESOURCE = 'limitranges'

    private def limits_raw(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      rr.dig('spec', 'limits')
    end

    # @param type [String, Class] the type limit applies to
    # @return [LimitRangeItem, Array<LimitRangeItem>, nil] if `type` parameter
    #   is specified then a single [LimitRangeItem] is returned, otherwise
    #   an array; if type is not found, then `nil` can be returned
    def limits(type=nil, user: nil, cached: true, quiet: false)
      unless cached && params[:limits]
        params[:limits] =
          limits_raw(user: user, cached: cached, quiet: quiet).map { |limit|
           LimitRangeItem.new(limit)
          }
      end
      if type
        return params[:limits].find { |l| l === type }
      else
        return params[:limits]
      end
    end
  end
end
