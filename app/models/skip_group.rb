require 'open-uri'

class SkipGroup < ActiveRecord::Base
  validates_presence_of :name, :gid
  validates_length_of :name, :in=>2..40, :if=>lambda{|r| r.name }
  validates_length_of :gid,  :maximum=>16, :if=>lambda{|r| r.gid }

  cattr_reader :site

  has_one  :group, :as => "backend", :dependent => :destroy

  def grant(idurls_or_users)
    if self.group.nil?
      create_group(:name=>name, :display_name=>display_name + "(SKIP)")
    end

    users = idurls_or_users.all?{|x| x.is_a?(User) } ?
            idurls_or_users : User.find_all_by_identity_url(idurls_or_users)

    self.group.memberships = users.map{|u| u.memberships.build }
  end

  def self.sync!(data)
    indexed_data = data.inject({}){|r, data| r[data[:gid]] = data; r }
    keeps, removes = find(:all).partition{|g| indexed_data[:gid] }

    removes.each(&:destroy)
    keeps.each do |keep|
      data = indexed_data.delete(keep.gid)
      keep.update_attributes!(data.except(:members))
      keep.grant(data[:members])
    end

    created = indexed_data.map do |gid, group|
      returning create!(group.except(:members)) do |skip_group|
        skip_group.grant(group[:members])
      end
    end
    [created, keeps, removes]
  end
end

