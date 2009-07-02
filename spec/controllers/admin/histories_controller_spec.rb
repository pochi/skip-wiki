require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::HistoriesController do
  fixtures :notes, :pages
  before do
    controller.stub!(:authenticate).and_return(true)
    controller.stub!(:require_admin).and_return(true)
  end

  def mock_page(stubs={})
    @mock_page ||= mock_model(Page,stubs)
  end

  def mock_note(stubs={})
    @mock_note ||= mock_model(Note,stubs)
  end

  def mock_user(stubs={})
    @mock_user ||= mock_model(User,stubs)
  end

  def mock_history(stubs={})
    default_attribute = {:content =>"hoge", :user => mock_user, :revision => 1 }
    @mock_history ||= mock_model(History, default_attribute.merge!(stubs))
  end

  def mock_error(stubs={})
    @mock_error ||= mock_model(Exception, stubs)
  end

  describe "GET 'new'" do
    before do
      controller.stub!(:requested_note).and_return(mock_note)
      Page.should_receive(:find_by_name).with('our_note_page_1').and_return(mock_page)
      mock_page.should_receive(:display_name).and_return("hoge")
      get :new, :note_id => "our_note", :page_id => 'our_note_page_1'
    end

    it "ページが1件取得できていること" do
      assigns[:note].should == mock_note
      assigns[:page].should == mock_page
    end

    it "ぱんくずが空でないこと" do
      assigns[:topics].should_not be_empty
    end
  end

  describe "POST 'create'" do
    before do
      Page.should_receive(:find_by_name).with("our_page").and_return(mock_page)
      mock_page.should_receive(:edit).and_return(mock_history({:content=>'fuga'}))
      controller.should_receive(:current_user).and_return(mock_user)
    end

    describe "Historyの編集が成功する場合" do
      before do
        mock_history.should_receive(:save).and_return(true)
        controller.should_receive(:requested_note).and_return(mock_note)
      end

      it "管理者のレビュー画面にリダイレクトされること" do
        post :create, :note_id => 'our_note', :page_id => 'our_page', :history => {:content => "fuga"}
        response.should redirect_to(admin_note_page_url(mock_note, mock_page))
      end

      it "jsならLocationにパスが設定されること" do
        post :create, :note_id => 'our_note', :page_id => 'our_page', :history => {:content => "fuga"}, :format => "js"
        response.headers['Location'].should == admin_note_page_history_path(mock_note, mock_page, mock_history)
      end

      it "ページコンテンツが変更されていること" do
        post :create, :note_id => 'our_note', :page_id => 'our_page', :history => {:content => "fuga"}
        assigns[:history].content.should == "fuga"
      end
    end

    describe "Historyの編集が失敗する場合" do
      before do
        mock_history.should_receive(:save).and_return(false)
        mock_history.should_receive(:errors).and_return(mock_error)
        mock_error.should_receive(:full_messages).and_return("error")
      end

      it "レンダリングされること" do
        post :create, :note_id => 'our_note', :page_id => 'our_page', :history => {:content => "fuga"}, :format => 'js'

      end

      it "should json is set to errors for @history" do
      end

      it "should status is set to unprocessable_entity" do
      end
    end
  end

end
