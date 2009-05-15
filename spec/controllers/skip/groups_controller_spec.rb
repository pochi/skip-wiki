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
        create_user(:name => n, :display_name => n, :identity_url => "http://openid.example.com/#{n}")
      }

      post :create, :format => "xml",
        :group => {
          :name => "group_x",
          :display_name => "グループX",
          :gid => "12345",
          :members =>[alice, bob].map(&:identity_url)
        }
    end

    it("response should be success") { response.should be_success }

    describe "assigned group" do
      subject{ assigns[:skip_group].reload }

      it{ subject.name.should == "group_x" }
      it{ subject.group.should have(2).users }
    end

    describe "response [group]" do
      subject{ Hash.from_xml(response.body)["group"] }

      it{ subject["members"].should be_instance_of Array }
      it{ subject["url"].should == skip_group_url("12345") }
    end
  end

  describe "PUT :update (success)" do
    before do
      @alice, @bob, @charls = %w[alice bob charls].map{|n|
        create_user(:name => n, :display_name => n, :identity_url => "http://openid.example.com/#{n}")
      }
      @group = SkipGroup.create!( :name => "group_a", :display_name => "グループA", :gid => "12345")
      @group.grant([@alice, @bob].map(&:identity_url))

      put :update, :id => @group.gid, :format => "xml",
        :group => {
          :name => "group_a",
          :display_name => "グループA",
          :gid => "23456",
          :members =>[@alice, @charls].map(&:identity_url)
        }
    end

    it("response should be success") { response.should be_success }

    describe "response [group]" do
      subject{ Hash.from_xml(response.body)["group"] }
      it{ subject["url"].should == skip_group_url("23456") }
    end

    describe "assigned group" do
      subject{ assigns[:skip_group].reload }
      it{ subject.name.should == "group_a" }
    end

    describe "assigned group's users" do
      subject{ assigns[:skip_group].reload.group.users }

      it{ should include @alice }
      it{ should include @charls }
      it{ should_not include @bob }
    end
  end

  describe "DELETE :destroy (success)" do
    before do
      @alice, @bob = %w[alice bob].map{|n|
        create_user(:name => n, :display_name => n, :identity_url => "http://openid.example.com/#{n}")
      }
      @group = SkipGroup.create!( :name => "group_a", :display_name => "グループA", :gid => "12345")
      @group.grant([@alice, @bob].map(&:identity_url))

      delete :destroy, :id => @group.gid, :format => "xml"
    end

    it("response should be success") { response.should be_success }

    describe "assigned group's users" do
      subject{ assigns[:skip_group].group }

      it{ @alice.groups.should_not include subject }
      it{ @bob.groups.should_not include subject }
    end
  end
end
