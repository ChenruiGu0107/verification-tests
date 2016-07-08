require 'socket'

require 'base_helper'

module CucuShift
  module Common
    module Net
      extend BaseHelper

      # @return single DNS entry for a hostname
      def self.dns_lookup(hostname, af: Socket::AF_INET, multi: false)
        res = Socket.getaddrinfo(hostname, 0, af, Socket::SOCK_STREAM, nil, Socket::AI_CANONNAME)

        if res.size < 1
          raise "cannot resolve hostname: #{hostname}"
        end

        return multi ? res.map{|r| r[3]} : res[0][3]
      end

      def self.reverse_lookup(ip)
        res = Socket.getaddrinfo(ip, 0, Socket::AF_UNSPEC, Socket::SOCK_STREAM, nil, Socket::AI_CANONNAME, true)

        if res.size != 1
          raise "not sure how to handle multiple entries, please report to author"
        end

        return res[0][2] # btw this might be same IP if reverse entry missing
      end

      # wait until TCP connection to host/port pair can be established
      # @return [Exception, nil] returns last exception if connection never
      #   established
      def self.wait_for_tcp(host:, port:, timeout:, socket_connect_timeout: 5)
        result = {
          instruction: "wait #{timeout} seconds for TCP server to start accepting connecitons on #{host}:#{port}",
          exitstatus: -1,
          response: "",
          props: {stats: {}}
        }

        result[:success] = wait_for(timeout, stats: result[:props][:stats]) do
          begin
            Socket.tcp(host, port, connect_timeout: socket_connect_timeout) {}
            true
          rescue => e
            result[:error] = e
            false
          end
        end

        return result
      end
    end
  end
end
