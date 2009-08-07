class AddStateToAdvertisements < ActiveRecord::Migration
  def self.up
    add_column(:advertisements, :state, :integer, :default => 1)
  end

  def self.down
    remove_column(:advertisements, :state)
  end
end
