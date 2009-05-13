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
          @site + "skip/users"
        end

        def groups_endpoint
          @site + "skip/groups"
        end
      end

      RequestViaPost = lambda do |uri, body|
        Net::HTTP.start(uri.host, uri.port) do |http|
          req = Net::HTTP::Post.new(uri.path)
          req.body = body
          req["Content-Type"] = "application/xml"
          http.request(req).body
        end
      end

      attr_reader :name, :site
      def initialize(name, site, mapper_klass = Mapper, &post_req)
        @name = name
        @mapper = mapper_klass.new(site)
        @post_req = block_given? ? post_req : RequestViaPost
      end

      def register!(params)
        xml = post("skip", @mapper.register_endpoint, params)

        Collaboration.backend.store(:consumer, name, xml.slice("id", "key", "secret"))
      end

      def add_user(identity_url, name, display_name)
        xml = post("user",
                   @mapper.users_endpoint,
                   :name => name, :display_name => display_name, :identity_url => identity_url)

        Collaboration.backend.store(:user, identity_url, xml.slice("access_token", "access_secret"))
      end

      def sync_users
        raise NotImplementedError
      end

      def add_group(gid, name, display_name, members)
        xml = post("group",
                   @mapper.groups_endpoint,
                   :gid => gid, :name => name, :display_name => display_name, :members => members)

        Collaboration.backend.store(:group, gid, xml)
      end

      def sync_groups
        raise NotImplementedError
      end

      def get_as(identity_url, path)
        access_tokens = Collaboration.backend.fetch(:user, identity_url)

      end

      private
      def post(xml_root, path, params)
        res = @post_req.call( path, params.to_xml(:root => xml_root) )
        Hash.from_xml(res)[xml_root]
      end
    end
  end
end

