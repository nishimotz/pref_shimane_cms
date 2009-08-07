class CreateSiteComponents < ActiveRecord::Migration
  def self.up
    create_table :site_components do |t|
      t.column :name, :string
      t.column :value, :text

    end

    # Add default theme and link from top page's main photo
    SiteComponents.transaction do
      SiteComponents.create :name => 'theme', :value => 'blue'
      SiteComponents.create :name => 'top_photo_link', :value => '/index.html'
    end
  end

  def self.down
    drop_table :site_components
  end
end
