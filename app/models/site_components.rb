class SiteComponents < ActiveRecord::Base
  validates_uniqueness_of :name

  def self.[](name)
    find_by_name(name.to_s).value rescue nil
  end

  def self.[]=(name, value)
    component = find_by_name(name.to_s)
    component.update_attribute(:value, value)
  end
end
