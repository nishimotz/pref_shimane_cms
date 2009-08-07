class Division < ActiveRecord::Base
  has_many(:sections, :order => 'number')

  set_field_names(:name => '部局名')
  def validate
    if self.name.blank?
      errors.add(:name, 'が入力されていません')
    end
  end
end
