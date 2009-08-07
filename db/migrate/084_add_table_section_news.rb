class AddTableSectionNews < ActiveRecord::Migration
  def self.up
    create_table(:section_news) do |t|
      t.column(:page_id, :integer)
      t.column(:begin_date, :datetime)
      t.column(:path, :string)
      t.column(:title, :string)
      t.column(:genre_id, :integer)
    end
  end

  def self.down
    drop_table(:section_news)
  end
end
