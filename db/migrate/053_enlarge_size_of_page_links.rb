class EnlargeSizeOfPageLinks < ActiveRecord::Migration
  def self.up
    puts "It may take a while. Please wait."
    transaction do
      id_list = PageContent.find_all.collect{|e| e.id}
      add_column(:page_links, :link_new, :text)
      PageLink.reset_column_information
      count = PageLink.count
      PageLink.find_all.each_with_index do |e, index|
        if id_list.include?(e.page_content_id)
          e[:link_new] = e[:link]
          e.save
        else
          e.destroy
        end
        puts "#{index}/#{count}" if index % 100 == 0
      end
      remove_column(:page_links, :link)
      rename_column(:page_links, :link_new, :link)
    end
  end

  def self.down
    puts "It may take a while. Please wait."
    transaction do
      id_list = PageContent.find_all.collect{|e| e.id}
      add_column(:page_links, :link_new, :string)
      PageLink.reset_column_information
      count = PageLink.count
      PageLink.find_all.each_with_index do |e, index|
        if id_list.include?(e.page_content_id)
          e[:link_new] = e[:link]
          e.save
        else
          e.destroy
        end
        puts "#{index}/#{count}" if index % 100 == 0
      end
      remove_column(:page_links, :link)
      rename_column(:page_links, :link_new, :link)
    end
  end
end
