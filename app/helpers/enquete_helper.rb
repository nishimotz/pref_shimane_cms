module EnqueteHelper
  def escape_csv(str)
    %Q!"#{str.gsub(/"/, '\\"')}"!
  end

  def unanswered_count(item, answers)
    answers.size - item.answered_count
  end
end
