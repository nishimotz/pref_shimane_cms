class PageContent < ActiveRecord::Base
  has_one(:page_status)

  NEWS_NO = 0
  NEWS_YES = 1
  NEWS_REQUEST = 2
  NEWS_REJECT = 3

  SECTION_NEWS_NO = 0
  SECTION_NEWS_YES = 1

  EDITING = 0
  PUBLISH_REQUEST = 1
  PUBLISH_REJECT = 2
  PUBLISH = 3
  CANCEL = 4
end

class PageStatus < ActiveRecord::Base
end

class MergePageStatusesIntoPageContents < ActiveRecord::Migration
  def self.up
    transaction do
      add_column(:page_contents, :admission, :integer)
      add_column(:page_contents, :top_news, :integer)
      add_column(:page_contents, :section_news, :integer)
      remove_column(:page_contents, :status)
      PageContent.reset_column_information
      count = PageContent.count
      i = 1
      PageContent.find(:all, :include => 'page_status').each do |e|
        puts "#{i}/#{count}" if i % 100 == 0
        admission = e.page_status[:admission] || PageContent::EDITING
        top_news = e.page_status[:top_news] || PageContent::NEWS_NO
        section_news = e.page_status[:section_news] || PageContent::SECTION_NEWS_NO
        execute("UPDATE page_contents SET admission = #{admission.to_i}, top_news = #{top_news.to_i}, section_news = #{section_news.to_i} WHERE id = #{e.id};")
        i += 1
      end
      drop_table(:page_statuses)
    end
  end

  def self.down
    transaction do
      create_table(:page_statuses) do |table|
        table.column(:page_content_id, :integer)
        table.column(:admission, :integer)
        table.column(:top_news, :integer)
        table.column(:section_news, :integer)
      end
      PageContent.find(:all).each do |e|
        st = PageStatus.new
        st[:admission] = e[:admission]
        st[:top_news] = e[:top_news]
        st[:section_news] = e[:section_news]
        st[:page_content_id] = e.id
        st.save
      end
      remove_column(:page_contents, :admission)
      remove_column(:page_contents, :top_news)
      remove_column(:page_contents, :section_news)
      add_column(:page_contents, :status, :integer)
    end
  end
end
