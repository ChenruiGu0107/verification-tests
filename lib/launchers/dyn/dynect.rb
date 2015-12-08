require_relative 'oo_exception'
require_relative 'dynect_plugin'

module CucuShift
  # we reuse DynectPlugin and add our convenience methods
  class Dynect < ::OpenShift::DynectPlugin
    # FYI logger method is overridden by Helper so we should be good to go
    include Common::Helper

    def initialize(opts={})
      args = opts.dup
      args.merge! conf[:services, :dyndns]
      args.merge! get_env_credentials
      unless args[:user_name] && args[:password]
        raise "no Dynect credentials found"
      end
      super(args)
    end

    def get_env_credentials
      idx = ENV["DYNECT_CREDENTIALS"].index(':')
      if idx
        return { user_name: ENV["DYNECT_CREDENTIALS"][0..idx-1],
                 password: ENV["DYNECT_CREDENTIALS"][idx+1..-1]}
      else
        return {}
      end
    end

    def dyn_get(path, auth_token, retries=@@dyn_retries)
      headers = { "Content-Type" => 'application/json', 'Auth-Token' => auth_token }
      url = URI.parse("#{@end_point}/REST/#{path}")
      resp, data = nil, nil
      dyn_do('dyn_get', retries) do
        http = Net::HTTP.new(url.host, url.port)
        # below line get rid of the warning message
        # warning: peer certificate won't be verified in this SSL session
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        #http.set_debug_output $stderr
        http.use_ssl = true
        begin
          logheaders = headers.clone
          logheaders["Auth-Token"]="[hidden]"
          logger.debug "DYNECT has? with path: #{url.path} and headers: #{logheaders.inspect}"
          resp = http.get(url.path, headers)
          data = resp.body
          case resp
          when Net::HTTPSuccess
           if data
             data = JSON.parse(data)
             if data['status'] == 'success'
               logger.debug "DYNECT Response data: #{data['data']}"
             else
               logger.debug "DYNECT Response status: #{data['status']}"
               raise_dns_exception(nil, resp)
             end
           end
          when Net::HTTPNotFound
            logger.error "DYNECT returned 404 for: #{url.path}"
          when Net::HTTPTemporaryRedirect
            resp, data = handle_temp_redirect(resp, auth_token, 100)
          else
            raise_dns_exception(nil, resp)
          end
        rescue OpenShift::DNSException => e
          raise e
        rescue Exception => e
          raise_dns_exception(e)
        end
      end
      return resp, data
    end

    def dyn_create_a_records(record, target, auth_token=@auth_token, retries=@@dyn_retries)
      fqdn = "#{record}.#{@domain_suffix}"
      path = "ARecord/#{@zone}/#{fqdn}/"
      # Create the A records
      [target].flatten.each { |target|
        logger.info "Configuring '#{fqdn}' A record to '#{target}'"
        record_data = { :rdata => { :address => target }, :ttl => "60" }
        dyn_post(path, record_data, auth_token, retries)
      }
    end
    alias dyn_create_a_record dyn_create_a_records

    def dyn_create_random_a_wildcard_records(target, auth_token=@auth_token, retries=@@dyn_retries)
      tstamp = Time.now.strftime("%m%d")
      rand_component = rand_str(3, :dns)
      record = "*.#{tstamp}-#{rand_component}"
      dyn_create_a_records(record, target, auth_token, retries)
    end
    alias dyn_create_random_a_wildcard_record dyn_create_random_a_wildcard_records
  end
end
