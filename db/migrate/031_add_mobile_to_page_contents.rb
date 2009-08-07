class AddMobileToPageContents < ActiveRecord::Migration
  def self.up
    add_column(:page_contents, :mobile, :text)
  end

  def self.down
    remove_column(:page_contents, :mobile)
  end
end
