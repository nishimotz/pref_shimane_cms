class CreateAdvertisements < ActiveRecord::Migration
  def self.up
    create_table(:advertisements) do |table|
      table.column(:name, :string)
      table.column(:advertiser, :string)
      table.column(:image, :string)
      table.column(:alt, :string)
      table.column(:url, :text)
      table.column(:begin_date, :datetime)
      table.column(:end_date, :datetime)
      table.column(:side_type, :integer)      # 1 => inside, 2 => outside
      table.column(:show_in_header, :boolean)
      table.column(:corp_ad_number, :integer)
      table.column(:pref_ad_number, :integer)
    end
  end

  def self.down
    drop_table(:advertisements)
  end
end
