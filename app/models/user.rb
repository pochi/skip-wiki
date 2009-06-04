class User < ActiveRecord::Base
  include LogicalDestroyable
  extend NamedIdValidation
  attr_accessor :batch_mode
  attr_protected :identity_url, :batch_mode

  validates_named_id_of     :name
  validates_presence_of     :display_name, :identity_url
  validates_uniqueness_of   :name, :identity_url, :unless => :batch_mode
  validates_length_of       :display_name, :within => 1..60

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

  def self.sync!(skip, users_update_data)
    id2var = users_update_data.inject({}) do |r, data|
      r[data[:identity_url]] = data; r
    end
    keeps, removes = find(:all).partition{|u| id2var[u.identity_url] }

    removes.each(&:destroy)
    keeps.each{|k| k.update_attributes!(id2var.delete(k.identity_url)) }
    created = id2var.map{|_id_,var| create_with_token!(skip, var){|u|u.batch_mode=true}.first }
    [created, keeps, removes]
  end

  def self.create_with_token!(skip, user_param)
    u = create!(user_param) do |u|
      yield u if block_given?
      u.identity_url = user_param[:identity_url]
    end
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

  # TODO 回帰テストを書く
  def accessible_pages(group = nil)
    writable_or_accessible_note_ids =
      if group
        Note.writable_or_accessible(self).owned_group(group).all.map(&:id)
      else
        Note.writable_or_accessible(self).all.map(&:id)
      end
    readable_note_ids =
      if group
        Note.readable.owned_group(group).all.map(&:id)
      else
        Note.readable.all.map(&:id)
      end

    Page.active.scoped({
      :conditions => [
        "(#{Page.quoted_table_name}.note_id IN (:writable_or_accessible_note_ids)) OR (#{Page.quoted_table_name}.note_id IN (:readable_note_ids) AND #{Page.quoted_table_name}.published = :published)",
        {:writable_or_accessible_note_ids => writable_or_accessible_note_ids, :readable_note_ids => readable_note_ids, :published => true}]
    })
  end
end

