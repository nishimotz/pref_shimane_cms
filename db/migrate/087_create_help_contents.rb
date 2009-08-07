class CreateHelpContents < ActiveRecord::Migration
  def self.up
    create_table :help_contents do |t|
      t.column(:content, :text)
    end
  end

  def self.down
    drop_table :help_contents
  end
end
