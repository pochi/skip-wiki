require 'features/step_definitions/skip_rp'

SkipEmbedded::Collaboration.backend = Class.new do
  def initialize; @storage = {} ; end
  def fetch(type, key); @storage[type][key] ; end
  def store(type, key, value)
    @storage[type] ||= {}
    @storage[type].update(key => value)
  end
end.new

RESOURCE_TO_PATH = {
  "ノートのRSS" => "/notes.rss"
}.freeze

Given /SKIPをOAuth Consumerとして登録する/ do
  @skip_rp = SkipEmbedded::Collaboration::SkipRp.new("wiki", "http://#{self.host}") do |uri, body|
    header = {
      "Content-Type" => "application/json",
      "X-Secret-Key" => ::SkipEmbedded::InitialSettings['skip_collaboration']['secret_key']
    }

    post uri.path + ".js", body, header
    response.body
  end

  @skip_rp.register!(:name => "SKIP", :url => "http://skip.example.com/")
  SkipEmbedded::Collaboration.backend.fetch(:consumer, "wiki").should_not be_blank
end

Given /^SKIPユーザとして"([^\"]*)"を登録する$/ do |user|
  @skip_rp.add_user("http://localhost:3200/user/#{user}", user, user.humanize)
end

Given /^SKIPグループとして"([^\"]*)"を含む"([^\"]*)"グループを登録する$/ do |users, group|
  members = users.split(",").map{|u| {:identity_url => "http://localhost:3200/user/#{u}"}}
  @skip_rp.add_group("gid:#{group}", group, group.humanize, members)
end

Given /^SKIPの"([^\"]*)"のユーザ情報を同期する$/ do |names|
  users = names.split(",").map{|u|
    ["http://localhost:3200/user/#{u}", u, u.humanize, false]
  }
  @skip_rp.sync_users(users)
end

Given /^SKIPの"([^\"]*)"を含む"([^\"]*)"グループ情報を同期する$/ do |users, group|
  members = users.split(",").map{|u| "http://localhost:3200/user/#{u}"}
  @skip_rp.sync_groups([["#{group.object_id}", group, group.humanize, members]])
end

Given %r!^ユーザ"([^\"]*)"のOAuth AccessTokenで"([^\"]*)"を取得する$! do |user, resouce|
  path = RESOURCE_TO_PATH[resouce]
  identity_url = "http://localhost:3200/user/#{user}"

  consumer = SkipEmbedded::Collaboration.backend.fetch(:consumer, "wiki")
  oauth_consumer = OAuth::Consumer.new(consumer["key"], consumer["secret"], :site => "http://#{self.host}")

  user = SkipEmbedded::Collaboration.backend.fetch(:user, identity_url)
  oauth_acc_token = OAuth::AccessToken.new(oauth_consumer, user["access_token"], user["access_secret"])

  header "Authorization", Net::HTTP::Post.new(path).tap{|req| oauth_acc_token.sign!(req) }["Authorization"]
  visit path
end

Then /SKIPが"([^\"]*)"にアクセスするためのキーとシークレットが払い出されること/ do |app|
  consumer = SkipEmbedded::Collaboration.backend.fetch(:consumer, app)
  consumer["key"].should_not be_blank
  consumer["secret"].should_not be_blank
end

