class AddIndexToTextInWords < ActiveRecord::Migration
  def self.up
    add_index(:words, :text)
  end

  def self.down
    # the following will not work with rails-1.0 due to its bug.
    # remove_index(:words, :column => :text)
    remove_index(:words, :text)
  end
end
