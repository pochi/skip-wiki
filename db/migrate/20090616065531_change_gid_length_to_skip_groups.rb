class ChangeGidLengthToSkipGroups < ActiveRecord::Migration
  def self.up
    change_column :skip_groups, :gid, :string, :limit => 100, :null => false
  end

  def self.down
    change_column :skip_groups, :gid, :string, :limit => 16, :null => false
  end
end
