class User < ActiveRecord::Base
  include LogicalDestroyable

  validates_presence_of     :name
  validates_length_of       :name, :within => 3..40
  validates_uniqueness_of   :name
  validates_format_of       :name, :with => /[A-Za-z0-9_\-]+/, :message => "use alphabet, '_', and '-' only."
  validates_presence_of     :display_name
  validates_length_of       :display_name, :within => 3..256

  has_many :memberships, :dependent => :destroy do
    def replace_by_type(klass, *groups)
      remains = find(:all, :include=>:group).select{|m| m.group.backend_type != klass.name }
      news = groups.map{|g| proxy_reflection.klass.new(:group=>g,:user=>proxy_owner) }
      replace(remains + news)
    end
  end
  has_many :groups, :through => :memberships
  has_many :builtin_groups, :foreign_key => "owner_id"

  has_many :client_applications
  has_many :tokens, :class_name=>"OauthToken",:order=>"authorized_at DESC",:include=>[:client_application]

  scope_do :named_acl
  named_acl :notes

  named_scope :fulltext, proc{|word|
    return {} if word.blank?
    # TODO
    # quoted_table_nameの概要を諸橋さんに聞く
    # [ActiveRecord]
    # def self.quoted_table_name
    #   self.connection.quote_table_name(self.table_name)
    # end
    w = "%#{word}%"
    {:conditions => ["name LIKE ? OR display_name LIKE ?", w, w]}
  }

  def self.create_with_token!(skip, user_param)
    u = create!(user_param){|u| u.identity_url = user_param[:identity_url] }
    return [u, skip.publish_access_token(u)]
  end

  def name=(value)
    write_attribute :name, (value ? value.downcase : nil)
  end

  def page_editable?(note)
    note.public_writable? || accessible?(note)
  end

  def build_note(note_params)
    NoteBuilder.new(self, note_params).note
  end

  def access_token_for(app)
    tokens.detect{|t| t.is_a?(AccessToken) && t.client_application_id == app.id }
  end
end

