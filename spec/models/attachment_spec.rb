require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Attachment do
  fixtures :notes
  before(:each) do
    @uploaded_data = StringIO.new(File.read("spec/fixtures/data/at_small.png"))
    def @uploaded_data.original_filename; "at_small.png" end
    def @uploaded_data.content_type; "image/png" end

    @valid_attributes = {
      :uploaded_data => @uploaded_data,
    }
  end

  it "should create a new instance given valid attributes" do
    notes(:our_note).attachments.create!(@valid_attributes)
  end

  describe "initialize()" do
    before do
      @attachment = notes(:our_note).attachments.build(@valid_attributes)
    end
    it "should assign display name" do
      @attachment.display_name.should == "at_small.png"
    end

    it "should be valid" do
      @attachment.should be_valid
    end
  end

  describe "bad content_type" do
    subject{
      notes(:our_note).attachments.build(@valid_attributes)
    }
    it{
      subject.content_type = "image/gif"
      should_not be_valid
    }

    it{
      subject.filename, subject.content_type = "foo.html", "text/html"
      should_not be_valid
    }
  end

  describe "quota validation" do
    before do
      Attachment.should_receive(:sum).
        exactly(2).times.
        with(:size, kind_of(Hash)).
        and_return(20.gigabytes, 500.megabytes)
    end

    subject{
      notes(:our_note).attachments.build(@valid_attributes)
    }
    it{ should have(2).errors_on(:size) }
  end

  describe "full_filename" do
    subject{ notes(:our_note).attachments.build(@valid_attributes).full_filename }
    it{ should match(Regexp.new("\\A#{SkipEmbedded::InitialSettings["asset_path"]}")) }
  end

  describe "each" do
    before do
      File.should_receive(:size).with(kind_of(String)).and_return 10.megabytes + 1
    end

    subject do
      uploaded_data = StringIO.new(File.read("spec/fixtures/data/at_small.png"))
      def uploaded_data.original_filename; "at_small.png" end
      def uploaded_data.content_type; "image/png" end

      notes(:our_note).attachments.build(:uploaded_data => uploaded_data)
    end

    it{ should have(1).errors_on(:size) }
  end
end

