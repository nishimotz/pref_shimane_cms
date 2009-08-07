class PageLink < ActiveRecord::Base
  belongs_to(:content, :class_name => 'PageContent')

  def replace_link_regexp(pattern, replacement)
    self.link = link.sub(pattern, replacement)
    save!
  end
end
