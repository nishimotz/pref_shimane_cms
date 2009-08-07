class AddTableGenreCategories < ActiveRecord::Migration
  def self.up
    create_table(:genre_categories) do |table|
      table.column(:name, :string)
    end
  end

  def self.down
    drop_table(:genre_categories)
  end
end
