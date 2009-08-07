class Help < ActiveRecord::Base
  belongs_to(:help_content)
  belongs_to(:category, :class_name => 'HelpCategory')
  PER_PAGE = 10

  def publish_title
    return '非公開' if self.public && self.public.zero?
    return '公開'
  end

  def link_enable?(help)
    self.id != help.id
  end

  def next_help
    next_help_no = 0
    count = false
    self.category.helps.each_with_index do |help, i|
      if count
        next_help_no = i
        break
      end
      count = true if help.id == self.id && self.category.helps.size != (i + 1)
    end

    unless count
      category = self.category.next_category
      if category
        if !category.helps.empty?
          help = category.helps.first if category && !category.helps.empty?
          return help
        else
          next_category = category.next_category
          if !next_category.helps.empty?
            help = next_category.helps.first if next_category && !next_category.helps.empty?
            return help
          else
            next_category2 = next_category.next_category
            if !next_category2.helps.empty?
              help = next_category2.helps.first if next_category2 && !next_category2.helps.empty?
              return help
            end
          end
        end
      else
        return nil
      end
    end

    if self.category.helps.size > 0 && self.category.helps.size != next_help_no
      return self.category.helps[next_help_no]
    elsif self.category.helps.size > 0 && self.category.helps.size == next_help_no + 1
      category = self.category.next_category
      help = category.helps.first if category && !category.helps.empty?
      return help
    else
      return nil
    end
  end
end
