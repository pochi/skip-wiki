require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Skip::UsersController do
  fixtures :users
  before do
    controller.should_receive(:internal_call_only).and_return true
    @client = ClientApplication.create(:name => "SKIP",
                                       :url => "http://skip.example.com",
                                       :callback_url => "http://skip.example.com/oauth_callback")
    @client.grant_as_family!
  end

  describe "POST :create (success)" do
    before do
      controller.should_receive(:check_secret_key).and_return true
      post :create, :format => "xml",
        :user => {
          :name => "alice",
          :display_name => "アリス",
          :identity_url => "http://op.example.com/u/alice",
        }
    end

    it("response should be success") { response.should be_success }

    describe "assigned user" do
      it{ assigns[:user].should have(2).tokens }
    end

    describe "response" do
      subject{ Hash.from_xml(response.body)["user"] }
      it{ subject["access_token"].should_not be_blank }
      it{ subject["access_secret"].should_not be_blank }
    end
  end

  describe "PUT :update (success)" do
    before do
      alice = User.create!(
          :name => "alice",
          :display_name => "アリス",
          :identity_url => "http://op.example.com/u/alice"
      )
      @client.publish_access_token(alice)

      controller.should_receive(:authenticate_with_oauth).and_return true
      controller.send(:current_user=, alice)

      # FIXME Userクラスにラッパつける
      @old_token = alice.tokens.find(:first, :conditions => {:client_application_id => @client, :type => "AccessToken"})

      put_user
    end

    def put_user
      put :update, :format => "xml",
        :user => {
          :name => "bob",
          :display_name => "ボブさん",
          :identity_url => "http://op.example.com/u/bob",
        }
    end

    it("response should be success") { response.should be_success }

    describe "assigned user" do
      subject{ controller.send(:current_user) }
      it{ should have(2).tokens }
      it{ subject.name.should == "bob" }
      it{ subject.identity_url.should == "http://op.example.com/u/bob" }
    end

    describe "response" do
      subject{ Hash.from_xml(response.body)["user"] }
      it{ subject["access_token"].should == @old_token.token }
      it{ subject["access_secret"].should == @old_token.secret }
    end
  end

  describe "DELETE :destroy (success)" do
    subject{
      User.create!(
          :name => "alice",
          :display_name => "アリス",
          :identity_url => "http://op.example.com/u/alice"
      )
    }
    before do
      @client.publish_access_token(subject)

      controller.should_receive(:authenticate_with_oauth).and_return true
      controller.send(:current_user=, subject)

      delete :destroy
    end
    it{ should be_deleted }
  end
end
