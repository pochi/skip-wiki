require 'open-uri'

class SkipGroup < ActiveRecord::Base
  validates_presence_of :name, :gid
  validates_length_of :name, :in=>2..40, :if=>lambda{|r| r.name }
  validates_length_of :gid,  :maximum=>16, :if=>lambda{|r| r.gid }

  cattr_reader :site

  has_one  :group, :as => "backend"
end

