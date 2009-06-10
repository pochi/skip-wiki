require 'open-uri'

class SkipGroup < ActiveRecord::Base
  validates_presence_of :name, :gid
  validates_length_of :name, :in=>2..40, :if=>lambda{|r| r.name }
  validates_length_of :gid,  :maximum=>16, :if=>lambda{|r| r.gid }

  cattr_reader :site

  has_one  :group, :as => "backend", :dependent => :destroy

  def grant(idurls_or_users)
    if self.group
      group.update_attributes(:name => name, :display_name=>display_name + "(SKIP)")
    else
      create_group(:name=>name, :display_name=>display_name + "(SKIP)")
    end

    users = idurls_or_users.all?{|x| x.is_a?(User) } ?
            idurls_or_users : User.find_all_by_identity_url(idurls_or_users)

    self.group.memberships = users.map{|u| u.memberships.build }
  end

  def self.sync!(data)
    indexed_data = data.inject({}){|r, data| r[data[:gid]] = data; r }
    removes_or_keeps = find(:all).select{|g| indexed_data[g.gid] }
    removes, keeps = removes_or_keeps.partition{|g| indexed_data[g.gid][:delete?] }

    removes.each do |r|
      r.destroy
      indexed_data.delete(r.gid)
    end

    user_cache = User.all.inject({}){|h,u|h[u.identity_url] = u; h }

    keeps.each do |k|
      data = indexed_data.delete(k.gid)
      k.update_attributes!(data.except(:members))
      k.grant(data[:members].map{|m| user_cache[m] })
    end

    created = indexed_data.map do |gid, group|
      returning create!(group.except(:members)) do |skip_group|
        skip_group.grant( data[:members].map{|k| user_cache[k] } )
      end
    end
    [created, keeps, removes]
  end
end

