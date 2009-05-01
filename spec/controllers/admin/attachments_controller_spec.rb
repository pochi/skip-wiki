require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::AttachmentsController do
  fixtures :users, :notes

  before do
    controller.stub!(:current_user).and_return(@user = users(:quentin))
    controller.stub!(:require_admin).and_return(true)
  end

  def mock_note(stubs={})
    @mock_note ||= mock_model(Note, stubs)
  end

  def mock_attachment(stubs={})
    @mock_attachment ||= mock_model(Attachment, stubs)
  end

  def mock_attachments(stubs={})
    @mock_attachments ||= (1..3).map {|i| mock_model(Attachment, stubs)}
  end

  describe "GET /admin/attachments/index" do
    describe "requested_noteが取得できている場合" do
      before do
        # TODO should_receiveにすると２回呼ばれていると怒られる
        # mock_note.should_receive(:attachments).and_return(mock_attachments)
        mock_note.stub!(:attachments).and_return(mock_attachments)
        controller.stub!(:requested_note).and_return(mock_note)
      end

      it "requested_noteにひもづく添付ファイルが取得できていること" do
        get :index
        assigns(:attachments).should == mock_note.attachments
      end
    end

    describe "requested_noteが取得できていいない場合" do
      before do
        controller.stub!(:requested_note).and_return(nil)
      end
      it "添付ファイルが全て取得できていること" do
        get :index
        assigns(:attachments).should == Attachment.find(:all)
      end
    end
  end


  describe "DELETE /admin/notes/our_note/attachments/our_attachment" do
    it "添付ファイルにリクエストが飛んでいること" do
      Attachment.should_receive(:find).with("our_attachment").and_return(mock_attachment)
      delete :destroy, :note_id=>"our_note", :id=>"our_attachment"
    end

    it "添付ファイル画面にリダイレクトされること" do
      Attachment.should_receive(:find).with("our_attachment").and_return(mock_attachment(:destroy=>true))
      delete :destroy, :note_id=>"our_note", :id=>"our_attachment"
      response.should redirect_to(admin_note_attachments_url)
    end
  end
 
end
