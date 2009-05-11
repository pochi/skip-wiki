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
end
