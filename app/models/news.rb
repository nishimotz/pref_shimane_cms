class News < ActiveRecord::Base
  @@news_per_page = 10
  cattr_accessor :news_per_page

  def self.page_count
    count = self.count(['published_at <= ?', Time.now])
    if count == 0
      return 1
    else
      q, r = count.divmod(@@news_per_page)
      if r == 0
        return q 
      else
        return q + 1
      end
    end
  end
end
