class AddFtpToSections < ActiveRecord::Migration
  def self.up
    add_column(:sections, :ftp, :string)
  end

  def self.down
    remove_column(:sections, :ftp)
  end
end
