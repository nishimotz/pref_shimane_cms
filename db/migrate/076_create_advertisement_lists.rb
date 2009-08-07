class CreateAdvertisementLists < ActiveRecord::Migration
  def self.up
    create_table :advertisement_lists do |t|
      t.column(:advertisement_id, :integer)
      t.column(:state, :integer)
      t.column(:pref_ad_number, :integer)
      t.column(:corp_ad_number, :integer)
    end
  end

  def self.down
    drop_table(:advertisement_lists)
  end
end
