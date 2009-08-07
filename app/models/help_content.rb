class HelpContent < ActiveRecord::Base
  has_many(:helps, :dependent => true)
end
