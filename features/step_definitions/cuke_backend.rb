module OAuthCucumber
  class Connection
    def initialize(session)
      @session = session
    end

    def post_via_webservice_util(url, data)
      url = url.is_a?(URI) ? url : URI(url)
      header = {
        "X-SECRET-KEY", ::SkipEmbedded::InitialSettings['skip_collaboration']['secret_key'],
        "Content-Type", "application/json"
      }
      @session.post url.path, data.to_json, header

      JSON.parse(@session.response.body)
    end

    def get_resource_via_oauth(url, token, headers = {})
      url = url.is_a?(URI) ? url : URI(url)

      headers.each{|k,v| @session.header k,v }
      @session.header "Authorization", Net::HTTP::Get.new(url.path).tap{|req| token.sign!(req) }["Authorization"]

      @session.visit url.path
    end

    def post_via_oauth(url, data, token)
      request_api_via_oauth(:post, url, data, token)
    end
    def put_via_oauth(url, data, token)
      request_api_via_oauth(:put, url, data, token)
    end
    def delete_via_oauth(url, token)
      request_api_via_oauth(:delete, url, nil, token)
    end

    private
    def request_api_via_oauth(method, url, data, token)
      url = url.is_a?(URI) ? url : URI(url)
      klass = {:post => Net::HTTP::Post,
               :put  => Net::HTTP::Put,
               :delete  => Net::HTTP::Delete }[method]

      @session.header "Authorization", klass.new(url.path).tap{|req| token.sign!(req) }["Authorization"]
      @session.header "Content-Type", "application/json"
      @session.visit url.path, method, data.merge("_method" => method).to_json

      JSON.parse(@session.response.body)
    end
  end

  class Backend
    def initialize
      @storage = {}
    end

    def add_access_token(identity_url, token, secret)
      @storage[identity_url] = [token, secret]
    end

    def update_user(identity_url, data)
      :noop
    end

    def update_group(gid, data)
      :noop
    end

    ## testing utitility
    def tokens(identity_url)
      @storage[identity_url]
    end
  end
end
