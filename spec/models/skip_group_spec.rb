require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SkipGroup do
  before(:each) do
    @valid_attributes = {
      :name => "value for name",
      :display_name => "value for display_name",
      :gid => "value for gid"
    }
  end

  it "should create a new instance given valid attributes" do
    SkipGroup.create!(@valid_attributes)
  end

  describe ".new( <empty> )" do
    before do
      @group = SkipGroup.new
      @group.valid? #=> false
    end

    it "should have errors on :name" do
      @group.should have(1).errors_on(:name)
    end
  end

  describe "#grant(identity_urls)" do
    subject{ SkipGroup.create!(@valid_attributes) }
    before do
      @alice = create_user(:name => "alice")
      @bob = create_user(:name => "bob")

      subject.grant([@alice.identity_url, @bob.identity_url])
      subject.save!
    end

    it{ subject.group.users.should == [@alice, @bob] }

    context "更新する場合" do
      before do
        @charls = create_user(:name => "charls")

        subject.grant([@alice.identity_url, @charls.identity_url])
      end

      it{ subject.group.users.should == [@alice, @charls]}
    end
  end
end
