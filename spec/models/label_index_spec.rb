require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe LabelIndex do
  before(:each) do
    @valid_attributes = {
      :display_name => "Ruby",
      :note => mock_model(Note)
    }
  end

  it "should create a new instance given valid attributes" do
    LabelIndex.create!(@valid_attributes)
  end

  it "shoulud create a new instance with filled in displayname is empty" do
    empty_attributes = {:display_name => "", :note => mock_model(Note)}
    @label = LabelIndex.new(empty_attributes)
    @label.should be_valid
  end

  describe ".has_pages" do
    fixtures :notes, :pages
    before do
      @note = notes(:our_note)
      @label = @note.label_indices.create!(:display_name=>"the Label")
      another = @note.label_indices.create!(:display_name => "another")

      (@p1 = pages(:our_note_page_1)).label_index = @label
    end

    it "はページにひもづいたラベルのみを返すこと" do
      LabelIndex.has_pages.should == [@label]
    end
  end

  describe "#destroy (ページあり)" do
    fixtures :notes, :pages
    before do
      @label = LabelIndex.create!(@valid_attributes)
      (@p1 = pages(:our_note_page_1)).label_index = @label
    end

    it "削除できないこと" do
      @label.destroy.should be_false
      @label.destroy.should_not be_frozen
    end

    it "エラーが一つあること" do
      @label.destroy
      @label.should have(1).errors
    end
  end

  describe "#pages" do
    fixtures :notes, :pages
    before do
      @label = LabelIndex.create!(@valid_attributes)
      (@p1 = pages(:our_note_page_1)).label_index = @label
      (@p2 = pages(:our_note_page_2)).label_index = @label
      @label.reload
    end

    it{ @label.should have(2).pages }

    it("@p1のorder_in_labelは1であること"){ @p1.order_in_label.should == 1 }
  end
end
