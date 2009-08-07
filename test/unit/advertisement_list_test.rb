require File.dirname(__FILE__) + '/../test_helper'

class AdvertisementListTest < Test::Unit::TestCase
  fixtures :advertisements

  def setup
    @advertisements = [advertisements(:pref1),
                       advertisements(:pref2),
                       advertisements(:corp1),
                       advertisements(:corp2)]

    @advertisements.each do |ad|
      AdvertisementList.create(:advertisement_id => ad.id,
                               :state            => ad.state,
                               :pref_ad_number   => ad.pref_ad_number,
                               :corp_ad_number   => ad.corp_ad_number)
    end
  end

  def test_advertisements
    pref_ads = AdvertisementList.pref_advertisements
    corp_ads = AdvertisementList.corp_advertisements

    pref_ads.each do |ad|
        assert_equal Advertisement::INSIDE_TYPE, ad.advertisement.side_type
    end

    pref_ads.each_index do |i|
      if pref_ads[i+1] && pref_ads[i].advertisement.side_type == Advertisement::PUBLISHED && pref_ads[i+1].advertisement.side_type == Advertisement::PUBLISHED
        assert pref_ads[i].pref_ad_number < pref_ads[i+1].pref_ad_number
      end
    end

    corp_ads.each do |ad|
        assert_equal Advertisement::OUTSIDE_TYPE, ad.advertisement.side_type
    end

    corp_ads.each_index do |i|
      if corp_ads[i+1] && corp_ads[i].advertisement.side_type == Advertisement::PUBLISHED && corp_ads[i+1].advertisement.side_type == Advertisement::PUBLISHED
        assert corp_ads[i].corp_ad_number < corp_ads[i+1].corp_ad_number
      end
    end
  end

  def test_published_advertisements
    all_ads = AdvertisementList.published_advertisements
    pref_ads = AdvertisementList.pref_published_advertisements
    corp_ads = AdvertisementList.corp_published_advertisements

    all_ads.each do |ad|
      assert_equal Advertisement::PUBLISHED, ad.state
    end

    pref_ads.each_index do |i|
      assert_equal Advertisement::INSIDE_TYPE, pref_ads[i].advertisement.side_type
      assert_equal Advertisement::PUBLISHED, pref_ads[i].state
      if pref_ads[i+1]
        assert pref_ads[i].pref_ad_number < pref_ads[i+1].pref_ad_number
      end
    end

    corp_ads.each_index do |i|
      assert_equal Advertisement::OUTSIDE_TYPE, corp_ads[i].advertisement.side_type
      assert_equal Advertisement::PUBLISHED, corp_ads[i].state
      if corp_ads[i+1]
        assert corp_ads[i].corp_ad_number < corp_ads[i+1].corp_ad_number
      end
    end

    assert_equal all_ads.size, pref_ads.size + corp_ads.size
  end
end
