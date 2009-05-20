require 'rubygems'
gem "activesupport", "2.1.2"
require 'active_support'
require 'json'
require 'skip_rp/oauth_proxy'

module SkipRp
  module Util
    def user_data(identity_url, name, display_name, admin = false)
      {:identity_url => identity_url, :name => name,
        :display_name => display_name, :admin => admin}.reject{|k,v| v.nil? }
    end

    def group_data(gid, name, display_name, members)
      {:gid => gid, :name => name, :display_name => display_name,
        :members => members}.reject{|k,v| v.nil? }
    end
    module_function :user_data, :group_data
  end
  class Service
    cattr_accessor :connection
    cattr_accessor :backend

    class Mapper
      def initialize(site)
        @site = site.is_a?(URI) ? site : URI(site)
      end

      def register_endpoint
        @site + "skip"
      end

      def users_endpoint
        @site + "skip/user"
      end

      def users_sync_endpoint
        @site + "skip/user/sync"
      end

      def groups_endpoint
        @site + "skip/groups"
      end

      def groups_sync_endpoint
        @site + "skip/groups/sync"
      end
    end

    attr_reader :name, :url, :mapper, :key, :secret
    def self.register!(name, service, params)
      mapper = Mapper.new(service)
      response = connection.post_via_webservice_util(mapper.register_endpoint.to_s, "skip"=>params)["skip"]
      new(name, service, response)
    end

    def initialize(name, url, params)
      params = params.with_indifferent_access
      @key = params[:consumer_key] || params[:key]
      @secret = params[:consumer_secret] || params[:secret]
      raise ArgumentError.new("key and secret required in #{params.inspect}") unless @key && @secret

      @name = name
      @url  = url
      @mapper  = Mapper.new(url)
    end

    def groups_url
      @mapper.groups_endpoint.to_s
    end

    def group_url(gid)
      "#{@mapper.groups_endpoint}/#{gid}"
    end

    def user_url
      @mapper.users_endpoint.to_s
    end

    def user_sync_url
      @mapper.users_sync_endpoint.to_s
    end

    def group_sync_url
      @mapper.groups_sync_endpoint.to_s
    end

    def oauth(token, secret)
      OauthProxy.new(self, token, secret)
    end

    def add_user(*values)
      data = Util.user_data(*values)

      response = connection.post_via_webservice_util(user_url, "user" => data)["user"]
      backend.add_access_token(values.first, response["access_token"], response["access_secret"])
    end

    def sync_users(users)
      data = users.map{|values| Util.user_data(*values) }

      response = connection.post_via_webservice_util(user_sync_url, "users"=> data)["users"]
      response.each do |created|
        backend.add_access_token(created["identity_url"], created["access_token"], created["access_secret"])
      end
    end

    def sync_groups(groups)
      data = groups.map{|args| Util.group_data(*args) }

      response = connection.post_via_webservice_util(group_sync_url, "groups" => data)
      response["groups"].each do |created|
        backend.update_group(created["gid"], created)
      end
    end
  end
end

