class Attachment < ActiveRecord::Base
  include ::QuotaValidation

  validates_quota_of :size, :system
  validates_quota_of :size, :per_note, :scope => :attachable_id

  has_attachment :storage => :file_system,
                 :size => 1..QuotaValidation.lookup_setting(self, :each),
                 :path_prefix => "assets/uploaded_data/#{::Rails.env}",
                 :processor => :none
  belongs_to :attachable, :polymorphic => true

  attr_accessible :display_name, :uploaded_data

  validates_presence_of :display_name
  validates_as_attachment

  def filename=(new_name)
    super
    self.display_name = new_name
  end
end
