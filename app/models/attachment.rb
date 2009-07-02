class Attachment < ActiveRecord::Base
  include ::QuotaValidation
  include ::SkipEmbedded::ValidationsFile

  quota_each = QuotaValidation.lookup_setting(self,:each)

  has_attachment :storage => :file_system,
                 :size => 1..QuotaValidation.lookup_setting(self, :each),
                 :path_prefix => "assets/uploaded_data/#{::Rails.env}",
                 :processor => :none
  attachment_options.delete(:size) # エラーメッセージカスタマイズのため、自分でバリデーションをかける

  validates_inclusion_of :size, :in => 1..quota_each, :message =>
    "#{quota_each.to_i/1.megabyte}Mバイト以上のファイルはアップロードできません。"
  validates_quota_of :size, :system, :message =>
    "のシステム全体における保存領域の利用容量が最大値を越えてしまうためアップロードできません。"
  validates_quota_of :size, :per_note, :scope => :attachable_id, :message =>
     "の保存領域の利用容量が最大値を越えてしまうためアップロードできません。"

  belongs_to :attachable, :polymorphic => true
  belongs_to :user

  attr_accessible :display_name, :uploaded_data, :user_id

  validates_presence_of :display_name
  validates_as_attachment

  def filename=(new_name)
    super
    self.display_name = new_name
  end

  def full_filename(thumbnail=nil)
    base = SkipEmbedded::InitialSettings["asset_path"] ||
           File.expand_path("assets/uploaded_data/#{::Rails.env}", ::Rails.root)
    File.join(base, *partitioned_path(thumbnail_name_for(thumbnail)))
  end

  private
  def validate_on_create
    adapter = ValidationsFileAdapter.new(self)
    
    valid_extension_of_file(adapter)
    valid_content_type_of_file(adapter)
  end

  def allowed_extention?
    !disallow_extensions.include?(normalized_ext)
  end

  def allowed_content_type?
    !disallow_content_types.include?(content_type.downcase)
  end

  # SKIPのバリデーション内容とあわせる。attachment-fuが提供するテーブルは使わない
  def image_ext_for_image_content_type?
    content_types = CONTENT_TYPE_IMAGES[normalized_ext.to_sym]
    return true unless content_types # not image file.

    return content_types.split(',').include?(content_type)
  end

  def normalized_ext
    File.extname(filename).downcase.sub(/\A^\./, "")
  end
end
