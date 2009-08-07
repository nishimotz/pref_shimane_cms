class AddColumnOtherToEnqueteAnswerItems < ActiveRecord::Migration
  def self.up
    add_column(:enquete_answer_items, :other, :text)
  end

  def self.down
    remove_column(:enquete_answer_items, :other)
  end
end
