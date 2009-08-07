class EnqueteItem < ActiveRecord::Base
  belongs_to(:page)
  has_many(:enquete_answer_items, :dependent => true)
  has_many(:enquete_item_values, :dependent => true)
  Rank = Struct.new(:item_value, :count)
  
  def answer_values
    enquete_answer_items.map{|ai| ai.value}.reject{|v| v.blank?}
  end

  def checkbox_or_radio?
    enquete_item_values.any?
  end

  def answer_ranking
    enquete_item_values.map do |item_value|
      Rank[item_value, count_answer_by_value(item_value.value)]
    end.sort_by{|rank| -rank.count }
  end

  def answered_count
    enquete_answer_items.map{ |ai| ai.enquete_answer }.uniq.size
  end

  def count_answer_by_value(value)
    enquete_answer_items.count(['value = ?', value])
  end

  def other_answer_values
    other_answers = enquete_answer_items.find(:all,
                                              :select => "other",
                                              :conditions => ["other IS NOT NULL"])
    other_answers.map{ |item| item.other }.reject{|v| v.blank?}
  end
end
