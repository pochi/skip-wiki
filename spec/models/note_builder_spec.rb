require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe NoteBuilder do
  fixtures :users
  before do
    attrs = {
        :name => "value for name",
        :display_name => "value for display_name",
        :description => "value for note description",
        :publicity => 0,
        :category_id => "1",
        :group_backend_type => "BuiltinGroup",
        :group_backend_id => ""
    }
    @builder = NoteBuilder.new(users(:quentin), attrs)
    @note = @builder.note
  end

  it "the note should be_new_record" do
    @note.should be_new_record
  end

  it "the note.group_backend_type.should == 'BuiltinGroup'" do
    @note.group_backend_type.should == 'BuiltinGroup'
  end

  it "the note.group_backend_type.should == 'value for display_name group'" do
    @note.owner_group.display_name.should == "value for display_name group"
  end

  it "owner_group should be new_record" do
    @note.owner_group.should be_new_record
  end

  it "owner_group should have 10 label_indices" do
    @note.should have(10).label_indices
  end


  describe "保存前のfront_page" do
    it "はnew_recordであること" do
      @builder.front_page.should be_new_record
    end

    it "のnoteは@noteであること" do
      @builder.front_page.note.should == @note
    end

    it "のラベルnoteは@noteのデフォルトラベルであること" do
      @builder.front_page.label_index_id.should == @note.default_label.id
    end
  end

  describe "validation failed" do
    before do
      @note.name = ""
      @note.save #=> false
    end
    it "owner_group.should be_new_record" do
      @note.owner_group.should be_new_record
    end
  end

  describe "#save!" do
    before do
      @note.save!
      @user = users(:quentin)
      @note.reload
    end

    it "should have accessibility to @note.owner_group" do
      @note.accessibilities.find_by_group_id(@note.owner_group)
    end

    it "'s owner should have membershipsp within @note.owner_group" do
      @user.reload.memberships.find_by_group_id(@note.owner_group_id).should_not be_nil
    end

    it "should accessible the note" do
      @note.owner_group.backend.should_not be_new_record
      @user.free_or_accessible_notes.should include(@note)
    end

    it "the note.owner_group.backend.owner.should == @user" do
      @note.owner_group.backend.owner.should == @user
    end

    it "should have(10) label_indices" do
      @note.should have(10).label_indices
    end

    it "front_pageはまだnew_recordであること" do
      @builder.front_page.should be_new_record
    end

    describe "保存後のfront_page" do
      before do
        @builder.front_page.save!
        @builder.front_page.reload
      end

      it "noteとの関連も保存されること" do
        @builder.front_page.note.should == @note
      end

      it "デフォルトラベルに紐づいていること" do
        @builder.front_page.label_index.should == @note.default_label
      end

      it "公開済みであること" do
        @builder.front_page.should be_published
      end
    end
  end
end

describe NoteBuilder, "new_with_owner" do
  fixtures :users
  before do
    @quentin = users(:quentin)
  end
  describe "ユーザのWikiの場合" do
    it "NoteBuilder.newに正しいパラメータで渡ること" do
      valid_attr = {
        :name => "user_quentin",
        :display_name => "quentin's wiki",
        :description => "quentin's wiki",
        :publicity => 0,
        # TODO カテゴリどうするのか検討
        :category_id => "1",
        :group_backend_type => "BuiltinGroup",
      }
      NoteBuilder.should_receive(:new).with(@quentin, valid_attr)
      NoteBuilder.new_with_owner(@quentin, "user_quentin")
    end
    it "note作成できるnotebuilderが返ってくること" do
      builder = NoteBuilder.new_with_owner(@quentin, "user_quentin")
      builder.note.save.should be_true
      builder.note.should be_is_a(Note)
    end
  end
  describe "不正なユーザによるユーザのWikiの場合" do
    it "nilが返ること" do
      builder = NoteBuilder.new_with_owner(@quentin, "user_mat_aki")
      builder.should be_nil
    end
  end
  describe "グループのWiki作成の場合" do
    it "NoteBuilder.newに正しいパラメータで渡ること" do
      group = mock_model(Group)
      @quentin.stub_chain(:groups, :skip_group_name).and_return([group])

      valid_attr = {
        :name => "group_rails",
        :display_name => "rails's wiki",
        :description => "rails's wiki",
        :publicity => 0,
        # TODO カテゴリどうするのか検討
        :category_id => "1",
        :group_backend_type => "SkipGroup",
        :group_backend => group
      }
      NoteBuilder.should_receive(:new).with(@quentin, valid_attr)
      NoteBuilder.new_with_owner(@quentin, "group_rails")
    end
  end
  describe "不正なユーザによるグループのWiki作成の場合" do
    it "nilが返ること" do
      @quentin.stub_chain(:groups, :skip_group_name).and_return([])

      builder = NoteBuilder.new_with_owner(@quentin, "group_mat_aki")
      builder.should be_nil
    end
  end
  describe "wikipediaの場合" do
    before do
      @quentin.stub(:admin?).and_return(true)
    end

    it "NoteBuilder.newに正しいパラメータで渡ること" do
      valid_attr = {
        :name => "wikipedia",
        :display_name => "wikipedia",
        :description => "wikipedia",
        :publicity => 1,
        # TODO カテゴリどうするのか検討
        :category_id => "1",
        :group_backend_type => "BuiltinGroup",
      }
      NoteBuilder.should_receive(:new).with(@quentin, valid_attr)
      NoteBuilder.new_with_owner(@quentin, "wikipedia")
    end
    it "note作成できるnotebuilderが返ってくること" do
      builder = NoteBuilder.new_with_owner(@quentin, "wikipedia")
      builder.note.save.should be_true
      builder.note.should be_is_a(Note)
    end
  end
  describe "不正なユーザによるwikipediaの作成の場合" do
    it "nilが返ること" do
      builder = NoteBuilder.new_with_owner(@quentin, "wikipedia")
      builder.should be_nil
    end
  end
end
