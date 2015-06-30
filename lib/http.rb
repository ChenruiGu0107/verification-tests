require 'rest-client'

module CucuShift
  module Http
    extend Common::Helper # include methods statically

    # perform a HTTP request
    #   Implementation resembles rest-client, for options see:
    #   * http://www.rubydoc.info/gems/rest-client/1.8.0/RestClient/Request
    #   Idea is to use this method instead of rest-client directly for
    #   convenience, as well in the future we may resamble same behavior using
    #   HttpClient which is more flexible but less convenient. My main concern
    #   is lack of per request proxy and request hooks with RestClient.
    #   Other than that it looks descent, supports replay logging which we may
    #   enable for better post fail debugging.
    # @param [Hash] opts the rest-client request options
    # @return standard cucushift result hash
    def self.http_request(url:, cookies: nil, headers: {}, params: nil, payload: nil, method:, user: nil, password: nil, max_redirects: 10, verify_ssl: false, proxy: ENV['http_proxy'], read_timeout: 30, open_timeout: 10, quiet: false)
      rc_opts = {}
      rc_opts[:url] = url
      rc_opts[:cookies] = cookies if cookies
      rc_opts[:headers] = headers
      rc_opts[:headers][:params] = params if params
      rc_opts[:payload] = payload if payload
      rc_opts[:max_redirects] = max_redirects
      rc_opts[:verify_ssl] = verify_ssl
      rc_opts[:method] = method
      rc_opts[:user] = user if user
      rc_opts[:password] = password if password
      rc_opts[:read_timeout] = read_timeout
      rc_opts[:open_timeout] = open_timeout

      RestClient.proxy = proxy if proxy && ! proxy.empty?

      userstr = user ? "#{user}@" : ""
      result = {}
      result[:instruction] = "HTTP #{method.upcase} #{userstr}#{url}"
      result[:request_opts] = rc_opts
      result[:proxy] = RestClient.proxy if RestClient.proxy
      logger.info(result[:instruction]) unless quiet

      response = RestClient::Request.new(rc_opts).execute
    rescue => e
      # REST request unsuccessful
      if e.respond_to?(:response) and e.response.respond_to?(:code) and e.response.code.kind_of? Integer
        # server replied with non-success HTTP status, that's ok
        response = e.response
      else
        # request failed badly, server/network issue?
        result[:exitstatus] = -1
        result[:error] = e
        result[:cookies] = {}
        result[:headers] = {}
        response = exception_to_string(e)
      end
    ensure
      logger.info("HTTP status: #{result[:error] || result[:exitstatus]}") unless quiet
      result[:exitstatus] ||= response.code
      result[:response] = response
      result[:success] = result[:exitstatus].to_s[0] == "2"
      result[:cookies] ||= response.cookies
      result[:headers] ||= response.headers
      return result
    end

    # simple HTTP GET an URL
    def self.http_get(url: , max_redirects: 10)
      return http_request(url: url, method: :get, max_redirects: max_redirects)
    end
  end
end
