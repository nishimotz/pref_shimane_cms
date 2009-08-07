class LostLink < ActiveRecord::Base
  INSIDE_TYPE = 1
  OUTSIDE_TYPE = 2
  WARN_MSG = '未公開ページです。公開処理を行ってください。'
  ERR_MSG = 'ページがありません。'

  belongs_to(:page)

  def self.get_lost_links(type, section_id)
    query = 'section_id = ? and side_type = ?'
    LostLink.find(:all,
                  :conditions => [query, section_id, type], :order => 'id desc')
  end
end
