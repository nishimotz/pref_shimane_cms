class MovePagesFieldToPageContents < ActiveRecord::Migration
  def self.up
    remove_column(:pages, :user_name)
    remove_column(:pages, :tel)
    remove_column(:pages, :email)
    remove_column(:pages, :comment)
    add_column(:page_contents, :user_name, :string)
    add_column(:page_contents, :tel, :string)
    add_column(:page_contents, :email, :string)
    add_column(:page_contents, :comment, :text)
  end

  def self.down
    add_column(:pages, :user_name, :string)
    add_column(:pages, :tel, :string)
    add_column(:pages, :email, :string)
    add_column(:pages, :comment, :text)
    remove_column(:page_contents, :user_name)
    remove_column(:page_contents, :tel)
    remove_column(:page_contents, :email)
    remove_column(:page_contents, :comment)
  end
end
