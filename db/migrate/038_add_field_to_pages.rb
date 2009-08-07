class AddFieldToPages < ActiveRecord::Migration
  def self.up
    add_column(:pages, :user_name, :string)
    add_column(:pages, :tel, :string)
    add_column(:pages, :email, :string)
  end

  def self.down
    remove_column(:pages, :user_name)
    remove_column(:pages, :tel)
    remove_column(:pages, :email)
  end
end
