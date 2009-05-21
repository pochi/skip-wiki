require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Skip::UsersController do
  fixtures :users
  before do
    @client = ClientApplication.create(:name => "SKIP",
                                       :url => "http://skip.example.com",
                                       :callback_url => "http://skip.example.com/oauth_callback")
    @client.grant_as_family!
  end

  describe "POST :create (success)" do
    before do
      controller.should_receive(:check_secret_key).at_least(1).times.and_return true
      post :create, :format => "js",
        :user => {
          :name => "alice",
          :display_name => "アリス",
          :identity_url => "http://op.example.com/u/alice",
          :admin => "false",
        }
    end

    it("response should be success") { response.should be_success }

    describe "assigned user" do
      subject{ assigns[:user] }
      it{ should have_authorized_access_token_for(@client) }
      it{ should_not be_admin }
    end

    describe "response" do
      subject{ JSON.parse(response.body)["user"] }
      it{ subject["access_token"].should_not be_blank }
      it{ subject["access_secret"].should_not be_blank }
    end

    describe "admin flag" do
      before do
        post :create, :format => "js",
          :user => {
            :name => "bob",
            :display_name => "ぼぶさん",
            :identity_url => "http://op.example.com/u/alice",
            :admin => true
          }
      end
      it("response should be success") { response.should be_success }
      it{ assigns[:user].should be_admin }
    end
  end

  describe "PUT :update (success)" do
    before do
      alice = User.create!(:name => "alice", :display_name => "アリス"){|u|
        u.identity_url = "http://op.example.com/u/alice"
      }
      @client.publish_access_token(alice)

      controller.should_receive(:authenticate_with_oauth).and_return true
      controller.send(:current_user=, alice)

      # FIXME Userクラスにラッパつける
      @old_token = alice.tokens.find(:first, :conditions => {:client_application_id => @client, :type => "AccessToken"})

      put_user
    end

    def put_user
      put :update, :format => "js",
        :user => {
          :name => "bob",
          :display_name => "ボブさん",
          :identity_url => "http://op.example.com/u/bob",
        }
    end

    it("response should be success") { response.should be_success }

    describe "assigned user" do
      subject{ controller.send(:current_user) }
      it{ should have(1).tokens }
      it{ subject.name.should == "bob" }
      it{ subject.identity_url.should == "http://op.example.com/u/bob" }
    end

    describe "response" do
      subject{ JSON.parse(response.body)["user"] }
      it{ subject["access_token"].should == @old_token.token }
      it{ subject["access_secret"].should == @old_token.secret }
    end
  end

  describe "DELETE :destroy (success)" do
    subject{
      create_user
    }
    before do
      @client.publish_access_token(subject)

      controller.should_receive(:authenticate_with_oauth).and_return true
      controller.send(:current_user=, subject)

      delete :destroy
    end
    it{ response.should be_success }
    it{ should be_deleted }
  end

  describe "POST :sync (success)" do
    before do
      controller.should_receive(:check_secret_key).and_return true
      data = (1..10).map do |x|
        {:name => "user-#{x}", :display_name => "User.#{x}", :identity_url => "http://op.example.com/user/#{x}"}
      end

      post :sync, :format => "js", :users => data
    end

    it("response should be success") { response.should be_success }

    describe "assigned users" do
      subject{ assigns[:users] }
      it{ should have(10).items }
      it{ should be_all{|u| !!s.access_token_for(@client) }}
    end

    describe "response" do
      subject{ JSON.parse(response.body)["users"] }
      it{ subject.should be_all{|u| u["access_token"] } }
      it{ subject.should be_all{|u| u["access_secret"] } }
    end
  end

  describe "POST :sync (fail)" do
    before do
      controller.should_receive(:check_secret_key).and_return true
      data = (1..10).map do |x|
        {:display_name => "User.#{x}", :identity_url => "http://op.example.com/user/#{x}"}
      end

      post :sync, :format => "js", :users => data
    end

    it("response should not be success") { response.should_not be_success }
  end
end
