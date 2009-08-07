class AddUserIdToWords < ActiveRecord::Migration
  def self.up
    transaction do
      add_column(:words, :user_id, :integer)
    end
  end

  def self.down
    remove_column(:words, :user_id)
  end
end
