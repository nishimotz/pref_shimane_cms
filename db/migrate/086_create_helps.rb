class CreateHelps < ActiveRecord::Migration
  def self.up
    create_table :helps do |t|
      t.column(:name, :string)
      t.column(:public, :integer)
      t.column(:level, :integer)
      t.column(:help_category_id, :integer)
      t.column(:help_content_id, :integer)
    end
  end

  def self.down
    drop_table :helps
  end
end
