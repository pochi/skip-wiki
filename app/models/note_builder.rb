class NoteBuilder
  include GetText

  cattr_accessor :label_fixtures
  @@label_fixtures = SkipEmbedded::InitialSettings[:label_defaults]

  def initialize(user, attrs)
    @user = user
    @attrs = attrs.dup
    @group_backend = @attrs.delete(:group_backend)
  end

  def note
    return @note if @note
    @note = Note.new(@attrs) do |note|
              note.owner_group = find_or_initialize_group
              note.accessibilities << Accessibility.new(:group=>note.owner_group)
              note.label_indices << build_labels(label_fixtures)
            end
  end

  def front_page
    return @page if @page
    @page = returning(Page.front_page) do |page|
              page.edit(Page.front_page_content, @user)
              page.note = note
              page.published = true
              page.label_index_id = note.default_label.id
            end
  end

  def self.new_with_owner(user, note_owner_str)
    type, name  = note_owner_str.split("_",2)

    attr = {
      :name => note_owner_str,
      :display_name => "#{name}'s wiki",
      :description => "#{name}'s wiki",
      :publicity => 0,
      # TODO カテゴリどうするのか検討
      :category_id => "1"
    }
    if type == "user"
      return nil unless user.name == name
      attr.merge!(:group_backend_type => "BuiltinGroup")
    elsif type == "group"
      return nil unless group = user.groups.skip_group_name(name).first
      attr.merge!(:group_backend_type => "SkipGroup", :group_backend => group)
    else
      return nil
    end
    self.new(user, attr)
  end

  private
  def find_or_initialize_group
    case @attrs[:group_backend_type]
    when "BuiltinGroup"
      attrs = {:name => @attrs[:name],
               :display_name => _("%{name} group") % {:name=>@attrs[:display_name]},
               :backend=>@user.builtin_groups.build }
      Group.new(attrs){|g| g.memberships = [Membership.new(:group => g, :user=>@user)] }
    when "SkipGroup"
      @group_backend.users.include?(@user) ? @group_backend :
        @user.groups.find(:first, :conditions=> {:backend_type => @attrs[:group_backend_type],
                                                 :backend_id   => @attrs[:group_backend_id] })
    end
  end

  def build_labels(fixtures = [{}])
    returning( fixtures.map{|data| LabelIndex.new(data) } ) do |first, *rest|
      first.default_label = true
    end
  end
end
