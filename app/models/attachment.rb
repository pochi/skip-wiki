class Attachment < ActiveRecord::Base
  include ::QuotaValidation
  include ::ValidationsFile

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

  attr_accessible :display_name, :uploaded_data

  validates_presence_of :display_name
  validates_as_attachment

  def filename=(new_name)
    super
    self.display_name = new_name
  end

  private
  def validate_on_create
    unless(allowed_extention? && allowed_content_type? && image_ext_for_image_content_type?)
      errors.add_to_base "この形式のファイルは、アップロードできません。"
    end
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
    return true unless content_type # not image file.

    return content_types.split(',').include?(content_type)
  end

  def normalized_ext
    File.extname(filename).downcase.sub(/\A^\./, "")
  end
end
