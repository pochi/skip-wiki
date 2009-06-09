# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

# Be sure to include AuthenticatedTestHelper in spec/spec_helper.rb instead.
# Then, you can remove it from this and the functional test.
#
ActiveRecord::Base.colorize_logging = false
describe User do
  fixtures :users

  describe 'being created' do
    before do
      @user = nil
      @creating_user = lambda do
        @user = create_user
        violated "#{@user.errors.full_messages.to_sentence}" if @user.new_record?
      end
    end

    it 'increments User#count' do
      @creating_user.should change(User, :count).by(1)
    end
  end

  context "論理削除" do
    before do
      @alice = create_user
      @alice.logical_destroy
    end

    it{ User.active.should_not be_include(@alice) }
    describe "から復帰した場合" do
      before do
        @alice.recover
      end
      it{ User.active.should be_include(@alice) }
    end
  end

  describe "アプリケーションごとのアクセストークンを取得" do
    before do
      @client = ClientApplication.create(:name => "SKIP",
                                         :url => "http://skip.example.com",
                                         :callback_url => "http://skip.example.com/oauth_callback")
      @client.grant_as_family!
      @alice = create_user
      @client.publish_access_token(@alice)
    end

    it{ @alice.access_token_for(@client).should_not be_blank }
  end

  describe "User validation" do
    subject{ User.new(:name => "", :display_name => "") }
    it{ should have_at_least(1).errors_on(:name) }
    it{ should have_at_least(1).errors_on(:display_name) }
    it{ should have_at_least(1).errors_on(:identity_url) }

    describe "uniq制約" do
      subject do
        User.create!(:name=>"abc", :display_name=>"ABC") do |u|
          u.identity_url = "http://example.com/abc"
        end

        User.new(:name=>"abc", :display_name=>"ABC") do |u|
          u.identity_url = "http://example.com/abc"
        end
      end
      it{ should have_at_least(1).errors_on(:name) }
      it{ should have_at_least(1).errors_on(:identity_url) }
    end
  end

  describe "#build_note" do
    before do
      Page.stub!(:front_page_content).and_return("---FrontPage---")
      @user = create_user
      @note = @user.build_note(
        :name => "value for name",
        :display_name => "value for display_name",
        :description => "value for note description",
        :publicity => 0,
        :category_id => "1",
        :group_backend_type => "BuiltinGroup",
        :group_backend_id => ""
      )
    end

    describe "(with SQL injection group)" do
      before do
        @note = @user.build_note(
          :name => "value for name",
          :display_name => "value for display_name",
          :publicity => 0,
          :category_id => "1",
          :group_backend_type => "; DELETE * FROM users"
        )
      end

      it "the note should not be valid" do
        @note.should_not be_valid
      end
    end

    describe "#memberships.replace_by_type" do
      fixtures :users
      before do
        @user = create_user(:name=>"alice")
        [
          @skip1 = SkipGroup.create!(:name=>"skip1",:gid=>"skip1"),
          @skip2 = SkipGroup.create!(:name=>"skip2",:gid=>"skip2"),
          @builtin = BuiltinGroup.create!,
        ].each do |backend|
          group = Group.new(:name=>"#{backend.class}_#{backend.id}", :backend=>backend)
          @user.memberships.build(:group => group)
        end

        @user.save!
      end

      describe "BuiltinGroup" do
        before do
          @another = BuiltinGroup.create!
          @user.memberships.replace_by_type(BuiltinGroup, Group.new(:name=>"another", :backend=>@another))
        end
        it "との関連を変更できること" do
          @user.memberships.map{|m| m.group.backend }.should == [@skip1, @skip2, @another]
        end
      end

      describe "SkipGroup" do
        before do
          @another = SkipGroup.create!(:name=>"name", :display_name=>"display_name", :gid=>"hoge")
          @user.memberships.replace_by_type(SkipGroup, Group.new(:name=>"another", :backend=>@another))
        end
        it "との関連を変更できること" do
          @user.memberships.map{|m| m.group.backend }.should == [@builtin, @another]
        end
      end
    end
  end

  describe "#admin?" do
    describe "管理者ではない場合" do
      before { @user = create_user(:admin=>"0") }
      it "falseが返却されること" do
        @user.admin?.should be_false
      end
    end
    describe "管理者の場合" do
      before { @user = create_user(:admin=>"1") }
      it "trueが返却されること" do
        @user.admin?.should be_true
      end
    end
  end

  describe ".fulltext" do
    it "'quen'で検索すると1件該当すること" do
      User.fulltext("quen").should have(1).items
    end

    it "'--none--'で検索すると0件該当すること" do
      User.fulltext("--none--").should have(0).items
    end

    it "(nil)で検索すると3件該当すること" do
      User.fulltext(nil).should have(3).items
    end
  end

  context "SKIP連携の一括作成メソッド" do
    before do
      @client = ClientApplication.create(:name => "SKIP", :url => "http://skip.example.com")
      @client.grant_as_family!
    end

    describe ".create_with_token!" do
      before do
        @user, @token = User.create_with_token!(@client, {:name => "alice",
                                                          :display_name => "アリス",
                                                          :identity_url => "http://op.example.com/user/alice"})
        @user.reload; @token.reload
      end

      describe "で作られたユーザ" do
        subject{ @user }
        it{ should_not be_new_record }
      end

      describe "で作られたアクセストークン" do
        subject{ @user.access_token_for(@client) }

        it{ should_not be_blank }
        it{ should == @token }
      end
    end

    describe ".sync!" do
      before do
        @removes = User.find(:all) # fixture users
        data = (1..5).map do |x|
          {:name => "user-#{x}", :display_name => "User.#{x}", :identity_url => "http://op.example.com/user/#{x}"}
        end
        User.sync!(@client, data)
      end
      it{ User.should have(5).records }

      it "同期に含まれないユーザは消されていること" do
        User.should satisfy{
          @removes.all?{|r| User.find_by_id(r.id).nil? }
        }
      end

      it "同期されたすべてのユーザのアクセストークンが生成されていること" do
        User.should satisfy{
          User.find(:all).all?{|u| u.access_token_for(@client) }
        }
      end

      describe "nameの命名規則を変更し、一部レコードを保持したまま再更新" do
        before do
          data = (3..9).map do |x|
            {:name => "user-no-#{x}", :display_name => "User.#{x}", :identity_url => "http://op.example.com/user/#{x}"}
          end
          @remained_token_attr = User.find_by_name("user-3").access_token_for(@client).attributes
          @created, @updated, @deleted = User.sync!(@client, data)
        end

        it{ User.should have(7).records }

        it "既存ユーザの名前が更新されていること" do
          User.should satisfy{
            User.find(:all).all?{|u| u.name =~ /\Auser-no-\d\Z/ }
          }
        end

        it "保持されているユーザのAccessTokenは変わらないこと" do
          remained_users_token = User.find_by_name("user-no-3").access_token_for(@client)
          remained_users_token.attributes.should == @remained_token_attr
        end

        it "4人のユーザが作成されていること" do
          @created.should have(4).items
        end

        it "3人のユーザが更新されていること" do
          @updated.should have(3).items
        end

        it "2人のユーザが削除されていること" do
          @deleted.should have(2).items
        end
      end

      describe 'アクセストークンを持たないユーザを含む場合の再更新' do
        before do
          data = (3..9).map do |x|
            {:name => "user-no-#{x}", :display_name => "User.#{x}", :identity_url => "http://op.example.com/user/#{x}"}
          end
          id = User.last.id += 1
          user_without_access_token  = {:name => "user-no-#{id}", :display_name => "User.#{id}", :identity_url => "http://op.example.com/user/#{id}"}
          data << user_without_access_token
          @user_without_access_token = User.create!(user_without_access_token) do |u|
            u.identity_url = user_without_access_token[:identity_url]
          end
          @remained_token_attr = User.find_by_name("user-3").access_token_for(@client).attributes
          @created, @updated, @deleted = User.sync!(@client, data)
        end

        it{ User.should have(8).records }

        it '保持されているユーザのAccessTokenが存在しない場合は新たに作成されること' do
          User.should satisfy{
            @user_without_access_token.access_token_for(@client)
          }
        end

        it '保存されているユーザのAccessTokenが存在する場合はAccessTokenが変わらないこと' do
          remained_users_token = User.find_by_name("user-no-3").access_token_for(@client)
          remained_users_token.attributes.should == @remained_token_attr
        end

        it "4人のユーザが作成されていること" do
          @created.should have(4).items
        end

        it "4人のユーザが更新されていること" do
          @updated.should have(4).items
        end

        it "2人のユーザが削除されていること" do
          @deleted.should have(2).items
        end
      end
    end

    describe ".sync! のベンチ(100件)" do
      before do
        @data = (1..100).map do |x|
          {:name => "user-#{x}", :display_name => "User.#{x}", :identity_url => "http://op.example.com/user/#{x}"}
        end
      end

      it do
        lambda{ User.transaction{ User.sync!(@client, @data) } }.should be_completed_within(3.second)
      end
    end
  end
end
