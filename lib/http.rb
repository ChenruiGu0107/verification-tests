require 'rest-client'

module CucuShift
  module Http
    # perform a HTTP request
    #   Implementation resembles rest-client, for options see:
    #   * http://www.rubydoc.info/gems/rest-client/1.8.0/RestClient/Request
    #   Idea is to use this method instead of rest-client directly for
    #   convenience, as well in the future we may resamble same behavior using
    #   HttpClient which is more flexible but less convenient. My main concern
    #   is lack of per request proxy and timeout configuration with RestClient.
    #   Other than that it looks descent, supports replay logging which we may
    #   enable for better post fail debugging.
    # @param [Hash] opts the rest-client request options
    # @return standard cucushift result hash
    def self.http_request(url:, cookies: nil, headers: nil, params: nil, payload: nil, method:)
    end

    # simple HTTP GET an URL
    def self.http_get(url: , max_redirects: 10)
      return http_request(url: url, method: :get, max_redirects: max_redirects)
    end
  end
end
