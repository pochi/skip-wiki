class Page < ActiveRecord::Base
  extend NamedIdValidation
  include LogicalDestroyable

  CRLF = /\r?\n/
  FRONTPAGE_NAME = "FrontPage"

  attr_reader :new_history
  attr_writer :label_index_id
  attr_writer :order_in_label
  attr_accessor :attachment_ids

  belongs_to :note
  has_many :histories, :order => "histories.revision DESC"
  has_many :label_indexings
  has_one  :label_index, :through => :label_indexings
  has_many :attachments, :as => :attachable

  validates_named_id_of  :name
  validates_uniqueness_of :name, :scope => :note_id
  validates_associated :new_history, :if => :new_history, :on => :create
  validates_presence_of :content, :on => :create

  validates_inclusion_of :format_type, :in => %w[hiki html]

  named_scope :active, {:conditions => {:deleted => false}}
  validate_on_update :cant_rename
  before_destroy :frontpage_cant_destroy

  named_scope :recent, proc{|*args|
    {
     :order => "#{table_name}.updated_at DESC",
     :limit => args.shift || 10 # default
    }
  }

  named_scope :published, {:conditions => ["#{quoted_table_name}.published = ?", true]}

  named_scope :authored, proc{|*authors|
    hs = History.heads.find(:all, :select => "#{History.quoted_table_name}.page_id",
                                  :include  => :user,
                                  :conditions => ["#{User.quoted_table_name}.name IN (?)", authors])
    {:conditions => ["#{quoted_table_name}.id IN (?)", hs.map(&:page_id)]}
  }

  named_scope :labeled, proc{|*labels|
    {:include => :label_index, :conditions => ["#{LabelIndex.quoted_table_name}.id IN (?)", labels]}
  }

  named_scope :admin, proc{|*note_id|
    return {} if note_id[0].nil?
    {:conditions => ["#{quoted_table_name}.note_id IN (?)", note_id]}
  }

  # TODO 採用が決まったら回帰テスト書く
  named_scope :last_modified_per_notes, proc{|note_ids|
    {:conditions => [<<-SQL, false, note_ids] }
    #{quoted_table_name}.id IN (
      SELECT p0.id
      FROM   #{quoted_table_name} AS p0
      INNER JOIN (
        SELECT p2.note_id AS note_id, MAX(p2.updated_at) AS updated_at
        FROM #{quoted_table_name} AS p2
        WHERE p2.deleted = ? AND p2.note_id IN (?)
        GROUP BY p2.note_id
      ) AS p1 USING (note_id, updated_at)
    )
SQL
  }

  named_scope :fulltext, proc{|keyword|
    hids = History.find_all_by_head_content(keyword).map(&:page_id)
    if hids.empty?
      { :conditions => "1 = 2" } # force false
    else
      { :conditions => ["#{quoted_table_name}.id IN (?)", hids] }
    end
  }

  named_scope :admin_fulltext, proc{|keyword|
    return {} if keyword.blank?
    w = "%#{keyword}%"

    hids = History.find_all_by_head_content(keyword).map(&:page_id)
    if hids.empty?
      { :conditions => ["#{quoted_table_name}.display_name LIKE ?", w] } # force false
    else
      { :conditions => ["#{quoted_table_name}.id IN (?) OR #{quoted_table_name}.display_name LIKE ?", hids, w] }
    end
  }

  scope_do :chained_scope
  chainable_scope :labeled, :authored, :fulltext

  attr_protected :note_id, :deleted

  def after_save
    reset_history_caches
    update_label_index
    attach
  end

  def self.front_page(attrs = {})
    attrs = {
      :name => FRONTPAGE_NAME,
      :display_name => _("FrontPage"),
      :format_type => "html",
      :published => true,
    }.merge(attrs)
    new(attrs)
  end

  def self.front_page_content
    File.read(File.expand_path("assets/front_page.html.erb", ::Rails.root))
  end

  def order_in_label
    (idx = self.label_indexings.first) && idx.page_order
  end

  def name_editable?
    new_record? || !(published? || name == "FrontPage")
  end

  def head
    histories.first
  end

  def diff(from, to)
    revs = [from, to].map(&:to_i)
    hs = histories.find(:all, :conditions => ["histories.revision IN (?)", revs],
                              :include => :content)
    from_content, to_content = revs.map{|r| hs.detect{|h| h.revision == r }.content }

    Diff::LCS.sdiff(from_content.data.split(CRLF),
                    to_content.data.split(CRLF)).map(&:to_a)
  end

  def label_index_id
    @label_index_id || (label_index ? label_index.id : nil)
  end

  def content(revision=nil)
    if revision.nil? # HEAD
      (history =  @new_history || head) ? history.content.data : ""
    else
      histories.detect{|h| h.revision == revision.to_i }.content.data
    end
  end

  def revision
    new_record? ? 0 : (@revision ||= load_revision)
  end

  def edit(content, user)
    return if content == self.content
    self.updated_at = Time.now.utc
    @new_history = histories.build(:content => Content.new(:data => content),
                                   :user => user,
                                   :revision => revision.succ)
  end

  def to_param
    name_changed? ? name_was : name
  end

  def front_page?
    (name_was == FRONTPAGE_NAME || name == FRONTPAGE_NAME)
  end

  def last_editor
    if histories.loaded?
      head.user
    else
      User.find(:first, :joins => "INNER JOIN histories ON histories.user_id = users.id",
                        :conditions => ["histories.page_id = ?", id],
                        :order => "histories.revision DESC")
    end
  end

  private
  def reset_history_caches
    @revision = @new_history = nil
  end

  def load_revision
    histories.maximum(:revision) || 0
  end

  def update_label_index
    if(new_record? && label_index_id) || @label_index_id
      self.label_index = note.label_indices.find(label_index_id)
    end
  end

  def cant_rename
    if name_changed?
      errors.add :name, _("can't be change, create new one.")
      return false
    end
  end

  def frontpage_cant_destroy
    return true if note.nil?
    !(front_page?)
  end

  def attach
    returning attachments = Attachment.scoped(:conditions => ['id IN (?)', attachment_ids]).all do
      attachments.each do |attachment|
        attachment.attachable_id = self.id
        attachment.attachable_type = self.class.to_s
        attachment.save!
      end
    end
  end
end
