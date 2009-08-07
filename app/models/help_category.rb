class HelpCategory < ActiveRecord::Base
  has_many(:helps, :order => 'number')
  acts_as_tree :order => 'number'

  def get_category_tree_max_count
    count = 0
    self.children.each do |middle|
      if middle.children.empty?
        count += 1
      else
        middle.children.each do |small|
          count += 1
        end
      end
    end
    return 1 if count.zero?
    return count
  end

  def get_category_name
    if self.parent_id.nil?
      return 'big_category'
    else
      if self.parent.parent_id.nil?
        return 'middle_category'
      else
        return 'small_category'
      end
    end
  end

  def enable_navigation
    return '有効' if self.navigation
    return '無効'
  end

  def all_categories
    ret = [self]
    children.each{|i| ret += i.all_categories}
    ret    
  end

  def next_category(category = nil)
    # retry
    if category
      if self.parent
        no = nil
        self.parent.children.each_with_index do |i, j|
          no = j if i.id == category.id
        end
        if self.parent.children.size == no + 1
          categories = HelpCategory.find(:all, :conditions => ['parent_id is null'],
                                         :order => 'number asc')
          no = nil
          categories.each_with_index do |category, i|
            no = i if category.id == self.id
          end
          if categories.size == no + 1
            return categories.first
          else
            return categories[no + 1]
          end
        else
          no = nil
          self.parent.children.each_with_index do |category, i|
            no = i if category.id == self.id
          end
          return self.parent.children[no + 1]
        end
      else
        categories = HelpCategory.find(:all, :conditions => ['parent_id is null'],
                                       :order => 'number asc')
        no = nil
        categories.each_with_index do |category, i|
          no = i if category.id == self.id
        end
        if categories.size == no + 1
          return categories.first
        else
          return categories[no + 1]
        end
      end
    end

    if self.children.empty?
      # children not exists
      unless self.parent
        # not parent
        categories = HelpCategory.find(:all, :conditions => ['parent_id is null'],
                                       :order => 'number asc')
        no = nil
        categories.each_with_index do |i, count|
          no = count if i.id == self.id
        end
        return categories[no + 1] if categories.size >= no + 1
        return nil        
      end
      if !self.parent.children.empty? && self.parent.children.size != 1
        # brother exists
        no = nil
        self.parent.children.each_with_index do |i, count|
          no = count if i.id == self.id
        end

        if self.parent.children.size == no + 1
          # next parent brother or ancestor brother
          if self.parent
            category = self.parent
            self.parent.next_category(category)
          else
            categories = HelpCategory.find(:all, :conditions => ['parent_id is null'],
                                           :order => 'number asc')
            no = nil
            categories.each_with_index do |category, i|
              no = i if category.id == self.id
            end
            if categories.size == no + 1
              return categories.first
            else
              return categories[no + 1]
            end
          end
        else
          # next brother
          return self.parent.children[no + 1] if self.parent.children.size >= no + 1
          return nil
        end
      else
        # brother not exists
        categories = HelpCategory.find(:all, :conditions => ['parent_id is null'],
                                       :order => 'number asc')
        no = nil
        categories.each_with_index do |i, count|
          no = count if i.id == self.parent.id
        end
        return categories[no + 1] if categories.size >= no + 1
        return nil
      end
    else
      #  children exists
      if !self.children.first.helps.empty?
        return self.children.first
      else
        self.children.first.next_category
      end
    end
  end

  def related_category?(related_category)
    return false if self.parent_id.nil?
    if related_category.id == self.parent_id
      return true
    else
      self.parent.related_category?(related_category)
    end
  end
end
