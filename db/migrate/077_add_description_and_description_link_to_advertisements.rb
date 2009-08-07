class AddDescriptionAndDescriptionLinkToAdvertisements < ActiveRecord::Migration
  def self.up
    add_column(:advertisements, :description, :string)
    add_column(:advertisements, :description_link, :text)
  end

  def self.down
    remove_column(:advertisements, :description)
    remove_column(:advertisements, :description_link)
  end
end
