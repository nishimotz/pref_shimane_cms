class CreateEnqueteItemValues < ActiveRecord::Migration
  def self.up
    create_table(:enquete_item_values) do |t|
      t.column(:value, :text)
      t.column(:enquete_item_id, :integer)
    end
  end

  def self.down
    drop_table(:enquete_item_values)
  end
end
