class HelpAction < ActiveRecord::Base
  belongs_to(:help_category)
  belongs_to(:action_master)

  def category_path
    return '' unless self.help_category_id
    str = []
    str << self.help_category.name
    category_parent = self.help_category.parent
    while category_parent
      if category_parent
        str << category_parent.name
        category_parent = category_parent.parent
      end
    end
    return str.reverse.join(' / ')
  end

  def self.help_check(action, controller)
    controller_name = controller
    controller_name = 'admin' unless controller
    cms_action = CmsAction.find(:first,
                                :conditions => ['controller_name = ? and action_name = ?', 
                                controller_name, action])
    if cms_action
      master = cms_action.action_master
      if master
        action = find_by_action_master_id(master.id)
        return action.help_category_id if action
      end
    end
    return nil
  end
end
