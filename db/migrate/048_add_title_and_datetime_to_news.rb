class AddTitleAndDatetimeToNews < ActiveRecord::Migration
  def self.up
    transaction do
      add_column(:news, :published_at, :datetime, :null => false);
      add_column(:news, :title, :string, :null => false);
    end
  end

  def self.down
    transaction do
      remove_column(:news, :published_at)
      remove_column(:news, :title)
    end
  end
end
