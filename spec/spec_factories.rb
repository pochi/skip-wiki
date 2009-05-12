module SpecFactories
  def create_user(options = {})
    record = User.new({:name => "a_user", :display_name => "A User"}.merge(options))
    record.identity_url = "http://openid.example.com/user/"+record.name
    record.save
    record
  end
end
