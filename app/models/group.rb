class Group < ActiveRecord::Base
  has_many :memberships, :dependent => :destroy
  has_many :users, :through => :memberships

  has_many :accessibilities, :dependent => :destroy
  has_many :notes, :through => :accessibilities

  has_one :owning_note, :class_name => "Note",
                        :foreign_key => "owner_group_id"
  belongs_to :backend, :polymorphic => true

  named_scope :skip_group_name, proc{|name|
    { :joins => "INNER JOIN skip_groups ON groups.backend_type = 'SkipGroup' AND groups.backend_id = skip_groups.id",
      :conditions => {"skip_groups.name" => name} }
  }
end
