require 'open-uri'

class SkipGroup < ActiveRecord::Base
  validates_presence_of :name, :gid
  validates_length_of :name, :in=>2..40, :if=>lambda{|r| r.name }
  validates_length_of :gid,  :maximum=>16, :if=>lambda{|r| r.gid }

  cattr_reader :site

  has_one  :group, :as => "backend"

  def grant(user_params)
    if self.group.nil?
      create_group(:name=>name, :display_name=>display_name + "(SKIP)")
    end

    users = User.find_all_by_identity_url(user_params.map{|h| h[:identity_url] })
    self.group.memberships = users.map{|u| u.memberships.build } # FIXME add admin flag here
  end
end

