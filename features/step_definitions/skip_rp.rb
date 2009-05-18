require 'rubygems'
gem "activesupport", "2.1.2"
require 'active_support'
require 'net/http'

module SkipEmbedded
  module Collaboration
    mattr_accessor :backend

    class SkipRp
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

      RequestViaPost = lambda do |uri, body|
        Net::HTTP.start(uri.host, uri.port) do |http|
          req = Net::HTTP::Post.new(uri.path)
          req.body = body
          req["Content-Type"] = "application/json"
          http.request(req).body
        end
      end

      RequestViaWebServiceUtil = lambda do |uri, body|
        Net::HTTP.start(uri.host, uri.port) do |http|
          req = Net::HTTP::Post.new(uri.path)
          req.body = body
          req["Content-Type"] = "application/json"
          req["X-SECRET-KEY"] = ::SkipEmbedded::InitialSettings['skip_collaboration']['secret_key']
          http.request(req).body
        end
      end

      attr_reader :name, :site
      def initialize(name, site, mapper_klass = Mapper, &post_req)
        @name = name
        @mapper = mapper_klass.new(site)
        @post_req = block_given? ? post_req : RequestViaWebServiceUtil
      end

      def register!(params)
        json = post("skip", @mapper.register_endpoint, params)["client_application"]

        Collaboration.backend.store(:consumer, name, json.slice("id", "key", "secret"))
      end

      def add_user(identity_url, name, display_name)
        xml = post("user",
                   @mapper.users_endpoint,
                   :name => name, :display_name => display_name, :identity_url => identity_url)

        Collaboration.backend.store(:user, identity_url, xml.slice("access_token", "access_secret"))
      end

      def sync_users(users)
        data = users.map do |ident, name, display_name, admin|
                 {:identity_url => ident, :name => name, :display_name => display_name, :admin => admin}
               end

        json = post("users", @mapper.users_sync_endpoint, data)
        json.each do |created|
          Collaboration.backend.store(:user, created["identity_url"], created.slice("access_token", "access_secret"))
        end
      end

      def add_group(gid, name, display_name, members)
        xml = post("group",
                   @mapper.groups_endpoint,
                   :gid => gid, :name => name, :display_name => display_name, :members => members)

        Collaboration.backend.store(:group, gid, xml)
      end

      def sync_groups(groups)
        data = groups.map{|args| groups_data(*args) }

        json = post("groups", @mapper.groups_sync_endpoint, data)

        json.each do |created|
          Collaboration.backend.store(:group, created["gid"], created)
        end
      end

      def get_as(identity_url, path)
        access_tokens = Collaboration.backend.fetch(:user, identity_url)
      end

      private
      def post(key, path, params)
        res = @post_req.call( path, {key => params}.to_json )
        JSON.parse(res)
      end

      def groups_data(gid, name, display_name, members)
        {:gid => gid, :name => name, :display_name => display_name, :members => members}
      end
    end
  end
end

