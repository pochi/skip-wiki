$: << 'features/step_definitions/integration/lib'
require 'features/step_definitions/integration/lib/skip_rp'
require 'features/step_definitions/cuke_backend'

RESOURCE_TO_PATH = {
  "ノートのRSS" => "/notes.rss"
}.freeze

def id_url(name)
  "http://localhost:3200/user/#{name}"
end

Given /SKIPをOAuth Consumerとして登録する/ do
  SkipRp::Service.connection = OAuthCucumber::Connection.new(self)

  @rp_service = SkipRp::Service.register!("wiki",  "http://#{self.host}", :url => "http://skips.example.com/")
  @rp_service.backend = OAuthCucumber::Backend.new
end

Given /^SKIPユーザとして"([^\"]*)"を登録する$/ do |user|
  @rp_service.add_user(id_url(user), user, user.humanize, false)
end

Given /^"([^\"]*)"の権限で"([^\"]*)"を含む"([^\"]*)"グループを登録する$/ do |creater, users, group|
  token, secret = @rp_service.backend.tokens(id_url(creater))

  @rp_service.oauth(token, secret).add_group(
    group.object_id.to_s,
    group,
    group.humanize,
    users.split(",").map{|u| id_url(u) }
  )
end

Given /^SKIPの"([^\"]*)"のユーザ情報を同期する$/ do |names|
  users = names.split(",").map{|u|
    ["http://localhost:3200/user/#{u}", u, u.humanize, false]
  }
  @rp_service.sync_users(users)
end

Given /^SKIPの"([^\"]*)"を含む"([^\"]*)"グループ情報を同期する$/ do |users, group|
  members = users.split(",").map{|u| "http://localhost:3200/user/#{u}"}
  @rp_service.sync_groups([["#{group.object_id}", group, group.humanize, members]])
end

Given %r!^ユーザ"([^\"]*)"のOAuth AccessTokenで"([^\"]*)"を取得する$! do |user, resouce|
  path = RESOURCE_TO_PATH[resouce]

  token, secret = @rp_service.backend.tokens(id_url(user))
  @rp_service.oauth(token, secret).get_resouce(path)
end

Then /キーとシークレットが払い出されること/ do
  @rp_service.key.should_not be_blank
  @rp_service.secret.should_not be_blank
end

