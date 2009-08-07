class MoveTitleToPage < ActiveRecord::Migration
  def self.up
    add_column(:pages, :title, :string)
    Page.reset_column_information
    Page.find(:all, :include => [:contents]).each do |page|
      begin
        title = page.public.title
        raise if title.blank?
      rescue
        title = page.private.title
      end
      page.title = title
      page.save
    end
    remove_column(:page_contents, :title)
  end

  def self.down
    add_column(:page_contents, :title, :string)
    PageContent.reset_column_information
    Page.find(:all, :include => [:contents]).each do |page|
      page.private.title = page.title
      page.private.save
      if page.public
        page.public.title = page.title
        page.public.save
      end
    end
    remove_column(:pages, :title)
  end
end
