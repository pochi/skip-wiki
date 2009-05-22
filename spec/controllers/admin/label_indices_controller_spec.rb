require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::LabelIndicesController do
  fixtures :users
  before do
    controller.stub!(:current_user).and_return(@user = users(:quentin))
    controller.stub!(:authenticate).and_return(true)
    controller.stub!(:require_admin).and_return(true)
  end

  def mock_note(stubs={})
    @mock_note ||= mock_model(Note, stubs)
  end

  describe "GET /admin/label_indices/index" do
    before do
      controller.should_receive(:requested_note).and_return(mock_note)
      mock_note.should_receive(:display_name).and_return('hoge')
      get :index      
    end

    it "noteが取得できていること" do
      assigns[:note].should == mock_note
    end

    it "ぱんくずリストが設定されていること" do
      assigns[:topics].class.should == Array
      assigns[:topics].size.should == 3
    end
  end

end
