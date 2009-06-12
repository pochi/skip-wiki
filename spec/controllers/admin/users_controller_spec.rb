require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::UsersController do
  fixtures :users
  before do
    controller.stub!(:current_user).and_return(@user = users(:quentin))
    controller.stub!(:require_admin).and_return(true)
  end

  def mock_user(stubs={})
    @mock_user ||= mock_model(User, stubs)
  end

  def mock_scope(stubs={})
    @mock_scope ||= mock_model(ActiveRecord::NamedScope::Scope, stubs)
  end

  describe "GET /admin/users/index" do
    before do
      controller.should_receive(:paginate_option).with(User).and_return("hoge")
      User.should_receive(:fulltext).with("keyword").and_return(mock_scope)
      mock_scope.should_receive(:paginate).with("hoge").and_return([mock_user])
    end

    it "Userが全件取得できていること" do
      get :index, :keyword => "keyword"
      assigns(:users).should == [mock_user]
    end

    it "パラメータにper_pageが設定されていない場合、デフォルトで10が設定されていること" do
      get :index, :keyword => "keyword"
      assigns(:per_page).should == 10
    end

    it "パラメータにper_pageが10で設定されている場合、10が設定されていること" do
      get :index, :keyword => "keyword", :per_page => 10
      assigns(:per_page).should == 10
    end

    it "パラメータにper_pageが25で設定されている場合、25が設定されていること" do
      get :index, :keyword => "keyword", :per_page => 25
      assigns(:per_page).should == 25
    end

    it "パラメータにper_pageが50で設定されている場合、50が設定されていること" do
      get :index, :keyword => "keyword", :per_page => 50
      assigns(:per_page).should == 50
    end

    # TODO: Investigate how to write gettext's text
    it "@topicsにメニューが設定されていること" do
      get :index, :keyword => "keyword"
      assigns(:topics).should_not be_nil
    end

    it "@serarchに検索パスが設定されていること" do
      get :index, :keyword => "keyword"
      assigns(:search).class.should == Array
      assigns(:search).size.should == 2
      assigns(:search).shift.should == admin_users_path
    end
  end

  describe "GET /admin/users/1/edit" do
    before do
      User.should_receive(:find).with("7").and_return(mock_user)
      mock_user.should_receive(:display_name).and_return("hoge")
      get :edit, :id => "7"
    end

    it "Userが1件取得できていること" do
      assigns(:user).should == mock_user
    end

    it "ぱんくずリストが設定されていること" do
      assigns(:topics).class.should == Array
      assigns(:topics).size.should == 2
    end
  end

  describe "PUT /admin/users/1" do
    describe "Userの更新に成功する場合" do
      it "User更新のリクエストが飛んでいること" do
        User.should_receive(:find).with("7").and_return(mock_user)
        mock_user.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id=>"7", :user=>{'these'=>'params'}
      end

      it "Userの更新ができていること" do
        User.stub!(:find).and_return(mock_user(:update_attributes=>true))
        put :update, :id=>"1"
        assigns(:user).should == mock_user
      end

      it "更新後、ユーザ一覧にリダイレクトされること" do
        User.stub!(:find).and_return(mock_user(:update_attributes=>true))
        put :update, :id=>"1"
        response.should redirect_to(admin_root_path)
      end
    end

    describe "Userの更新に失敗した場合" do
      it "updateにUser更新のリクエストが飛んでいること" do
        User.should_receive(:find).with("7").and_return(mock_user)
        mock_user.should_receive(:update_attributes).with({'these'=>'params'})
        put :update, :id=>"7", :user=>{'these'=>'params'}
      end

      it "更新処理が失敗していること" do
        User.stub!(:find).and_return(mock_user(:update_attributes => false))
        put :update, :id => "7"
        assigns(:user).should equal(mock_user)
      end

      it "編集画面にリダイレクトされること" do
        User.stub!(:find).and_return(mock_user(:update_attributes => false))
        put :update, :id => "7"
        response.should redirect_to(edit_admin_user_path("7"))
      end
    end
  end

end
