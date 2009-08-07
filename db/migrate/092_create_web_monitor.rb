class CreateWebMonitor < ActiveRecord::Migration
  def self.up
    create_table :web_monitors do |t|
      t.column :name, :string
      t.column :login, :string
      t.column :password, :string
      t.column :genre_id, :integer
    end

    add_column(:genres, :auth, :boolean, :default => false)
    Genre.update_all("auth = 'false'")
  end

  def self.down
    remove_column(:genres, :auth)
    drop_table :web_monitors
  end
end
