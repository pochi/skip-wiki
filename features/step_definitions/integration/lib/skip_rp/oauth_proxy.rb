require 'oauth'

module SkipRp
  class OauthProxy
    def initialize(service, token, secret)
      @service = service
      consumer = OAuth::Consumer.new(@service.key, @service.secret, :site => @service.url)
      @access_token = OAuth::AccessToken.new(consumer , token, secret)
    end

    def get_resouce(path, headers = {})
      @service.connection.get_resouce_via_oauth(path, @access_token, headers)
    end

    def update_user(params)
      res = @service.connection.put_via_oauth(@service.user_url, {"user" => params}, @access_token)["user"]
      @service.backend.update_user(res["identity_url"], res)
    end

    def destroy_user
      @service.connection.delete_via_oauth(@service.user_url, @access_token)
    end

    def add_group(*args)
      req = {"group" => Util.group_data(*args)}
      res = @service.connection.post_via_oauth(@service.groups_url, req, @access_token)["group"]
      @service.backend.update_group(res["gid"], res)
    end

    def update_group(gid, params)
      req = {"group" => params.except(:gid)}
      res = @service.connection.put_via_oauth(@service.group_url(gid), req, @access_token)["group"]
      @service.backend.update_group(res["gid"], res)
    end

    def destroy_group(gid)
      @service.connection.delete_via_oauth(@service.group_url(gid), @access_token)
    end
  end
end

