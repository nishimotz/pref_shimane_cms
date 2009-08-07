module PluginHelper

  TITLE_LENGTH_MAX = 35
  ELLIPSIS = '・・・'

  def PluginHelper.top_news(args)
    news_genre = nil
    # set a genre whose news to be shown.
    if !args.empty? && args.last =~ %r!(/[^/]+)+/!
      news_genre = Genre.find_by_path(args.pop)
      Page.top_news(args, news_genre)
    else
      Page.top_news(args)
    end
  end

  def PluginHelper.section_news(args)
    news_genre = nil
    # set a genre whose news to be shown.
    if !args.empty? && args.last =~ %r!(/[^/]+)+/!
      news_genre = Genre.find_by_path(args.pop)
      Page.top_news(args, news_genre)
    else
      Page.section_news(args)
    end
  end

  def PluginHelper.max_count(args)
    if args.first.to_i.zero?
      max = 9
    else
      max = args.first.to_i - 1
    end
  end

  def PluginHelper.truncate(title)
    if title
      title_char_ary = title.scan(/./)
      if title_char_ary.size < TITLE_LENGTH_MAX
        title
      else
        ellipsis_count = ELLIPSIS.scan(/./).size
        title_char_ary.slice(0...(TITLE_LENGTH_MAX - ellipsis_count)).join + ELLIPSIS
      end
    else
      ''
    end
  end

  def PluginHelper.show_genre_news_title?(args)
    if args.include?("off")
      args.reject!{ |i| i == "off" }
      return false
    end
    return true
  end

  def PluginHelper.show_section_news_title?(args)
    if args.include?("on")
      args.reject!{ |i| i == "on" }
      return true
    end
    return false
  end

  def emergency_exist?
    genre = Genre.find_by_path(CMSConfig[:emergency_path])
    @emergency_exist =  genre.news_page_contents.any?
  end

  def split_genre(genres)
    left,right = genres.partition{|g| genres.rindex(g) < genres.size/2}
    if genre_weight_sum(left) < genre_weight_sum(right)
      left.push(right.shift) 
    end
    return left, right
  end

  def genre_weight_sum(genres)
    genres.inject(0){|s, g| s + genre_weight(g)}
  end

  def genre_weight(genre)
    raw = genre.children.size
    raw.zero? ? 1 : (1 + raw/4.0)
  end
end
