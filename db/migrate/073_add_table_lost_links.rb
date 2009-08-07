class AddTableLostLinks < ActiveRecord::Migration
  def self.up
    create_table(:lost_links) do |t|
      t.column(:page_id, :integer)
      t.column(:section_id, :integer)
      t.column(:side_type, :integer) # 0 => inside, 1 => outside
      t.column(:target, :text)
      t.column(:message, :text)
    end
  end

  def self.down
    drop_table(:lost_links)
  end
end
