class CreateEnqueteTables < ActiveRecord::Migration
  def self.up
    create_table(:enquete_items) do |t|
      t.column(:page_id, :integer, :null => false)
      t.column(:no, :integer)
      t.column(:name, :string)
    end
    create_table(:enquete_answers) do |t|
      t.column(:page_id, :integer, :null => false)
      t.column(:answered_at, :datetime, :null => false)
      t.column(:remote_addr, :string, :null => false)
    end
    create_table(:enquete_answer_items) do |t|
      t.column(:answer_id, :integer, :null => false)
      t.column(:enquete_item_id, :integer, :null => false)
      t.column(:value, :text)
    end
  end

  def self.down
    drop_table(:enquete_items)
    drop_table(:enquete_answers)
    drop_table(:enquete_answer_items)
  end
end
