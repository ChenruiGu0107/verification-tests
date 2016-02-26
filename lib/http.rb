require 'rest-client'
require 'http-cookie'

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
    # @param params [Hash] URL params to send (not sure about POST requests)
    # @param payload [Hash|String|File|Object] payload to send; here you put
    #   your string content, JSON or file data. For file to be recognized and
    #   automatically multipart mime to be chosen, you need to look at
    #   rest-client documentation.
    # @param headers [Hash] request heders
    # @yield [str_chunk] block will be called by rest-client (actually Net:HTTP)
    #   with chunks of body content as read by the remote server; note that
    #   HTTP status redirections, cookies, headers, etc. are all lost from
    #   response when a block is passed
    # @return [CucuShift::ResultHash] standard cucushift result hash;
    #   there is :headers populated as a [Hash] where headers are lower-cased
    def self.http_request(url:, cookies: nil, headers: {}, params: nil, payload: nil, method:, user: nil, password: nil, max_redirects: 10, verify_ssl: OpenSSL::SSL::VERIFY_NONE, proxy: ENV['http_proxy'], read_timeout: 30, open_timeout: 10, quiet: false, &block)
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

      # RestClient.proxy = proxy if proxy && ! proxy.empty?
      rc_opts[:proxy] = proxy if proxy && ! proxy.empty?

      userstr = user ? "#{user}@" : ""
      result = {}
      result[:instruction] = "HTTP #{method.upcase} #{userstr}#{url}"
      result[:request_opts] = rc_opts
      result[:proxy] = RestClient.proxy if RestClient.proxy
      logger.info(result[:instruction]) unless quiet

      started = monotonic_seconds
      response = RestClient::Request.new(rc_opts).execute &block
    rescue => e
      # REST request unsuccessful
      if e.respond_to?(:response) and e.response.respond_to?(:code) and e.response.code.kind_of? Integer
        # server replied with non-success HTTP status, that's ok
        response = e.response
      else
        # request failed badly, server/network issue?
        result[:exitstatus] = -1
        result[:error] = e
        result[:cookies] = HTTP::CookieJar.new # empty cookies
        result[:headers] = {}
        result[:size] = 0
        response = exception_to_string(e)
      end
    ensure
      total_time = monotonic_seconds - started
      if block && !result[:error]
        logger.info("HTTP #{method.upcase} took #{'%.3f' % total_time} sec: #{response} bytes of data passed to block") unless quiet
        result[:exitstatus] ||= -1
        result[:response] = ""
        result[:success] = true # we actually don't know
        result[:cookies] = HTTP::CookieJar.new # empty cookies
        result[:headers] = {}
        result[:size] = response
      else
        logger.info("HTTP #{method.upcase} took #{'%.3f' % total_time} sec: #{result[:error] || response.description}") unless quiet
        result[:exitstatus] ||= response.code
        result[:response] = response
        result[:success] = result[:exitstatus].to_s[0] == "2"
        result[:cookies] ||= response.cookie_jar
        result[:headers] ||= response.raw_headers
        result[:size] ||= response.size
      end
      result[:total_time] = total_time
      return result
    end
    class << self
      alias request http_request
    end

    # simple HTTP GET an URL
    def self.http_get(url: , max_redirects: 10, &block)
      return http_request(url: url, method: :get, max_redirects: max_redirects, &block)
    end
    class << self
      alias get http_get
    end
  end
end
