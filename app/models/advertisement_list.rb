class AdvertisementList < ActiveRecord::Base
  belongs_to :advertisement
  validates_uniqueness_of :advertisement_id

  def AdvertisementList.published_advertisements
    AdvertisementList.find(:all, 
                           :conditions => ["state = ?",
                                           Advertisement::PUBLISHED])
  end

  def AdvertisementList.pref_published_advertisements
    query = "advertisement_lists.state = ? AND advertisements.side_type = ?"
    order = "advertisement_lists.pref_ad_number"
    AdvertisementList.find(:all, 
                           :include => :advertisement,
                           :conditions => [query, Advertisement::PUBLISHED,
                                           Advertisement::INSIDE_TYPE],
                           :order => order)
  end

  def AdvertisementList.corp_published_advertisements
    query = "advertisement_lists.state = ? AND advertisements.side_type = ?"
    order = "advertisement_lists.corp_ad_number"
    AdvertisementList.find(:all, 
                           :include => :advertisement,
                           :conditions => [query, Advertisement::PUBLISHED,
                                           Advertisement::OUTSIDE_TYPE],
                           :order => order)
  end

  def AdvertisementList.pref_advertisements
    query = "advertisements.side_type = ?"
    order = "advertisement_lists.state DESC, advertisement_lists.pref_ad_number"
    AdvertisementList.find(:all, 
                           :include => :advertisement,
                           :conditions => [query, Advertisement::INSIDE_TYPE],
                           :order => order)
  end

  def AdvertisementList.corp_advertisements
    query = "advertisements.side_type = ?"
    order = "advertisement_lists.state DESC, advertisement_lists.corp_ad_number"
    AdvertisementList.find(:all, 
                           :include => :advertisement,
                           :conditions => [query, 
                                           Advertisement::OUTSIDE_TYPE],
                           :order => order)
  end
end
