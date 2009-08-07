class ConvertNullInPageContents < ActiveRecord::Migration
  def self.up
    transaction do
      execute("UPDATE page_contents SET section_news = #{PageContent::SECTION_NEWS_NO} WHERE section_news is null;")
      execute("UPDATE page_contents SET top_news = #{PageContent::NEWS_NO} WHERE top_news is null;")
    end
  end

  def self.down
  end
end
