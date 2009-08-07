class AddIndexToPagesAndPageContentsAndGenres < ActiveRecord::Migration
  def self.up
    transaction do
      add_index(:pages, :genre_id)
      add_index(:page_contents, :page_id)
      add_index(:genres, :parent_id)
    end
  end

  def self.down
    transaction do
      remove_index(:genres, :parent_id)
      remove_index(:page_contents, :page_id)
      remove_index(:pages, :genre_id)
    end
  end
end
