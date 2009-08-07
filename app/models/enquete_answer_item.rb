class EnqueteAnswerItem < ActiveRecord::Base
  belongs_to(:enquete_item)
  belongs_to(:enquete_answer, :foreign_key => 'answer_id')
  before_save(:normalize_newlines)

  private

  def normalize_newlines
    self.value = self.value.gsub(/\r\n/u, "\n")
  end
end
