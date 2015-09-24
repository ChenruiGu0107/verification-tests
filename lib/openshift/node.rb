require 'yaml' 
require 'common' 

module CucuShift
  #@note this class represents OpenShift environment nodes
  class Node
    include Common::Helper 
    include Common::UserObjectHelper

    def initialize (name:, env:, props: {})
      if name.nil? || env.nil?
        raise "node need name and environment to be identified"
      end

      @name = name.freeze
      @env = env
      @props = props
    end

    attr_reader :name, :env, :props

    # list all nodes
    # @param user [CucuShift::User]
    # @return [Array<Node>]
    # @note raises error on issues
    def self.list(user:)
      res = user.cli_exec(:get, resource: "nodes", output: "yaml")
      if res[:success]
        list = YAML.load(res[:response])["items"]
        return list.map { |node_hash|
          self.from_api_object(user.env, node_hash)
        }
      else
        raise "error getting nodes for user: '#{user}'"
      end
    end

    # creates new node from an OpenShift API Node object
    def self.from_api_object(env, node_hash)
      self.new(name: node_hash["metadata"]["name"], env: env).update_from_api_object(node_hash)
    end

    def update_from_api_object(node_hash)
      h = node_hash["metadata"]
      props[:uid] = h["uid"]
      props[:labels] = h["labels"]
      return self
    end
  end
end
