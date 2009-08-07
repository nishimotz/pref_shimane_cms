class ChangeColumnConstraintsInPageContents < ActiveRecord::Migration
  def self.up
    transaction do
      change_column(:page_contents, :admission, :integer,
                    :default => PageContent::EDITING)
      change_column(:page_contents, :top_news, :integer,
                    :default => PageContent::NEWS_NO)
      change_column(:page_contents, :section_news, :integer,
                    :default => PageContent::SECTION_NEWS_NO)
    end
  end

  def self.down
    # do nothing
  end
end
