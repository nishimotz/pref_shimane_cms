class SectionNews < ActiveRecord::Base
  belongs_to(:page)
  belongs_to(:genre)

  def self.update_section_news(path)
    page = Page.find_by_path(path)
    unless page
      return
    end
    content = page.current
    section_news = SectionNews.find_by_page_id(page.id)
    if content
      if content.section_news == PageContent::SECTION_NEWS_NO
        news = SectionNews.find_by_page_id(page.id)
        if news
          news.destroy
        else
          return
        end
      end
      if section_news
        section_news.begin_date = content.date
        section_news.path = path
        section_news.title = page.news_title
        section_news.genre_id = page.genre_id
        section_news.save
      else
        section_news = self.new(:page_id => page.id,
                                :begin_date => content.date,
                                :path => path,
                                :title => page.news_title,
                                :genre_id => page.genre_id)
        section_news.save
      end
    else
      section_news.destroy if section_news
    end
  end

  def self.destroy_all_by_genre_remove(path)
    news = self.find(:all, :conditions => ["path = ?", path + '%'])
    news.each do |n|
      news.destroy
    end
  end

  def self.genre_news(arg, max, max_date)
    condition = []
    news = []

    if arg == 'all'
      if max_date.zero?
        news = SectionNews.find(:all,
                                :conditions => ['path not like ?',
                                                "#{CMSConfig[:bid_info_path]}%"],
                                :order => 'begin_date desc')
      else
        date = Date.today - max_date
        start_date = Time.local(date.year, date.month, date.day, 0, 0, 0)
        end_date = Time.local(Date.today.year, Date.today.month,
                              Date.today.day,23, 59, 59)
        condition << 'begin_date >= ?'
        condition << 'begin_date <= ?'
        cond = condition.join(' and ') + ' and path not like ?'
        news = SectionNews.find(:all, :conditions => [cond,
                                                      start_date, end_date,
                                                      "#{CMSConfig[:bid_info_path]}%"],
                                :order => 'begin_date desc')
      end
    elsif arg == 'other'
      genres = CMSConfig[:news_pages].keys
      genres << CMSConfig[:bid_genre]
      genre_cond = []
      genre_data = []
      genres.each do |name|
        genre = Genre.find_by_path("/#{name}/")
        if genre
          genre_cond << "path not like ?"
          genre_data << "/#{name}/%"
        end
      end
      condition = genre_cond.join(' and ')
      # emergency genre
      e_genre = Genre.find_by_path(CMSConfig[:emergency_path])
      if e_genre
        condition += ' and path not like ?'
        genre_data << "#{CMSConfig[:emergency_path]}%"
      end
      # bid genre
      b_genre = Genre.find_by_path(CMSConfig[:bid_info_path])
      if b_genre
        condition += ' and path not like ?'
        genre_data << "#{CMSConfig[:bid_info_path]}%"
      end
      cond = []
      cond << condition
      if max_date.zero?
        genre_data.each do |g|
          cond << g
        end
        news = SectionNews.find(:all,
                                :conditions => cond,
                                :order => 'begin_date desc')
      else
        date = Date.today - max_date
        start_date = Time.local(date.year, date.month, date.day, 0, 0, 0)
        end_date = Time.local(Date.today.year, Date.today.month,
                              Date.today.day,23, 59, 59)
        condition += ' and begin_date >= ?'
        condition += ' and begin_date <= ?'
        cond = [condition]
        genre_data.each do |g|
          cond << g
        end
        cond << start_date
        cond << end_date
        news = SectionNews.find(:all, :conditions => cond,
                                :order => 'begin_date desc')
      end
    else
      genre = Genre.find_by_path(arg)
      condition = []
      if genre
        if max_date.zero?
          condition = "path like ?"
          news = SectionNews.find(:all, :conditions => [condition, "#{arg}%"],
                                  :order => 'begin_date desc')
        else
          date = Date.today - max_date
          start_date = Time.local(date.year, date.month, date.day, 0, 0, 0)
          end_date = Time.local(Date.today.year, Date.today.month,
                                Date.today.day,23, 59, 59)
          condition << "path like ?"
          condition << 'begin_date >= ?'
          condition << 'begin_date <= ?'
          news = SectionNews.find(:all, :conditions => [condition.join(' and '),
                                                        "#{arg}%", start_date,
                                                        end_date],
                                  :order => 'begin_date desc')
        end
      end
    end

    return news[0..max] unless news.empty?
    return nil
  end
end
