require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::ApplicationController, "#require_admin" do

  def mock_note(stubs={ })
    @mock_note ||= mock_model(Note, stubs)
  end

  describe "#require_admin" do
    describe "管理者ではない場合" do
      before do
        controller.stub!(:authenticate).and_return(true)
        @user = mock_model(User)
        @user.should_receive(:admin?).and_return(false)
        controller.should_receive(:current_user).and_return(@user)
        controller.stub!(:root_url).and_return('http://localhost:3000/')
        controller.stub!(:redirect_to).with('http://localhost:3000/')
      end

      it "map.rootにリダイレクトされること" do
        controller.should_receive(:redirect_to).and_return('http://localhost:3000/')
        controller.require_admin
      end

      it "falseが返されること" do
        controller.require_admin.should be_false
      end
    end

    describe "管理者の場合" do
      before do
        controller.stub!(:authenticate).and_return(true)
        @user = mock_model(User)
        @user.should_receive(:admin?).and_return(true)
        controller.should_receive(:current_user).and_return(@user)
      end

      it "trueが返されること" do
        controller.require_admin.should be_true
      end
    end
  end

  describe "#requested_note" do
    describe "note_idがnilの場合" do
      before do
        controller.stub!(:authenticate).and_return(true)
        controller.should_receive(:params).and_return({:note_id => nil})
      end

      it "nilが返されること" do
        controller.requested_note.should be_nil
      end
    end

    describe "note_idにノートの名前が設定されている場合" do
      before do
        controller.stub!(:authenticate).and_return(true)
        controller.stub!(:params).and_return({:note_id => 'hoge'})
        Note.should_receive(:find_by_name).with('hoge').and_return(mock_note)
      end

      it "should be mock_note" do
        controller.requested_note.should == mock_note
      end
    end
  end
end

