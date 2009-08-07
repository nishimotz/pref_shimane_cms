class AddPageLinkIndex < ActiveRecord::Migration
  def self.up
    add_index(:page_links, :link)
  end

  def self.down
    # the following will not work with rails-1.0 due to its bug.
    # remove_index(:page_links, :column => :link)
    remove_index(:page_links, :link)
  end
end
