class Genre < ActiveRecord::Base
  has_and_belongs_to_many(:sections)
end

class RemoveGenresSections < ActiveRecord::Migration
  def self.up
    transaction do
      add_index(:genres, :section_id)
    end
  end

  def self.down
    transaction do
      remove_index(:genres, :section_id)
    end
  end
end
