class AddColumnFormTypeToEnqueteItems < ActiveRecord::Migration
  def self.up
    add_column(:enquete_items, :form_type, :string)
  end

  def self.down
    remove_column(:enquete_items, :form_type)
  end
end
