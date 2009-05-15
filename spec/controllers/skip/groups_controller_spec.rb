require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Skip::GroupsController do
  before do
    controller.should_receive(:internal_call_only).and_return true
    @client = ClientApplication.create(:name => "SKIP",
                                       :url => "http://skip.example.com",
                                       :callback_url => "http://skip.example.com/oauth_callback")
    @client.grant_as_family!
  end

  describe "POST :create (success)" do
    before do
      alice, bob = %w[alice bob].map{|n|
        User.create!(:name => n, :display_name => n, :identity_url => "http://openid.example.com/#{n}")
      }

      post :create, :format => "xml",
        :group => {
          :name => "group_a",
          :display_name => "グループA",
          :gid => "gid:12345",
          :members =>[alice, bob].map(&:identity_url)
        }
    end

    it("response should be success") { response.should be_success }

    describe "assigned group" do
      subject{ assigns[:skip_group].reload }

      it{ subject.group.should have(2).users }
    end

    describe "response [group]" do
      subject{ Hash.from_xml(response.body)["group"] }

      it{ subject["members"].should be_instance_of Array }
    end
  end
end
