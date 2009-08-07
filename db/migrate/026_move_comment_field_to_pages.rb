class MoveCommentFieldToPages < ActiveRecord::Migration
  def self.up
    add_column(:pages, :comment, :text)
    remove_column(:page_contents, :comment)
  end

  def self.down
    add_column(:page_contents, :comment, :text)
    remove_column(:pages, :comment)
  end
end
