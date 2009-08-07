require File.dirname(__FILE__) + '/../test_helper'
require 'nkf'

class AdvertisementTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "iso-2022-jp"

  fixtures :advertisements, :users

  include ActionMailer::Quoting

  def setup
    Time.redefine_now(Time.mktime(2006, 2, 2))
    @emails     = ActionMailer::Base.deliveries
    @emails.clear

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
  end

  def teardown
    Time.revert_now
  end

  def test_pref_advertisement
    advertisement = Advertisement.pref_advertisement
    advertisement.each do |ad|
      assert_equal ad.side_type, Advertisement::INSIDE_TYPE
    end
  end

  def test_corp_advertisement
    advertisement = Advertisement.corp_advertisement
    advertisement.each do |ad|
      assert_equal Advertisement::OUTSIDE_TYPE, ad.side_type
    end
  end

  def test_pref_published_advertisement
    advertisement = Advertisement.pref_published_advertisement
    advertisement.each_with_index do |ad, i|
      assert_equal Advertisement::INSIDE_TYPE, ad.side_type
      if advertisement[i+1]
        advertisement[i].pref_ad_number < advertisement[i+1].pref_ad_number
      end
    end
  end

  def test_corp_published_advertisement
    advertisement = Advertisement.corp_published_advertisement
    advertisement.each_with_index do |ad, i|
      assert_equal Advertisement::OUTSIDE_TYPE, ad.side_type
      if advertisement[i+1]
        advertisement[i].corp_ad_number < advertisement[i+1].corp_ad_number
      end
    end
  end

  def test_create
    path = "#{Advertisement::FILE_PATH}/test.png"
    advertisement = Advertisement.create({
      :name => "test",
      :advertiser => "test", :image => "test.png",
      :alt => "test file",
      :url => "http://www.example.com",
      :begin_date => Time.local(2006,2,1),
      :end_date => Time.local(2006,2,20), 
      :side_type => 1,
      :show_in_header => true})
      assert advertisement.valid?
  end

  def test_errors
    advertisement = Advertisement.new
    assert !advertisement.valid?
    assert_equal '広告の種類を選択してください', advertisement.errors.on(:side_type)
    assert_equal '広告名を入力してください', advertisement.errors.on(:name)

    assert_equal  '画像の説明を入力してください', advertisement.errors.on(:alt)
  end

  def test_name_uniqueness
    advertisement = Advertisement.create(:name => advertisements(:pref1).name)
    assert_equal 'その広告名はすでに使われています', advertisement.errors.on(:name)
  end

  def test_date
    advertisement = Advertisement.create({
      :begin_date => Time.local(2006,2,9),
      :end_date => Time.local(2006,1,9)})
      assert_equal '開始日時が終了日時よりも後になっています', advertisement.errors.on(:begin_date)
  end

  def test_expired
    advertisement = Advertisement.update(advertisements(:pref1).id,
                                         :end_date => Time.local(2006,2,1))
    assert advertisement.valid?
    assert advertisement.expired?
  end

  def test_published
    advertisement = advertisements(:pref1)
    advertisement.update_attributes(:state => Advertisement::PUBLISHED)
    assert advertisement.published?
    advertisement.update_attributes(:state => Advertisement::NOT_PUBLISHED)
    assert advertisement.valid?
    assert !advertisement.published?
  end

  def test_state_to_s
    advertisement = advertisements(:pref1)
    advertisement.update_attributes(:state => Advertisement::PUBLISHED)
    assert_equal "公開中", advertisement.state_to_s
    advertisement.update_attributes(:state => Advertisement::NOT_PUBLISHED)
    assert advertisement.valid?
    assert_equal "非公開", advertisement.state_to_s
  end

  def test_side_type
    advertisement = advertisements(:pref1)
    advertisement.update_attributes(:side_type => Advertisement::INSIDE_TYPE)
    assert advertisement.inside?
    advertisement.update_attributes(:side_type => Advertisement::OUTSIDE_TYPE)
    assert advertisement.valid?
    assert !advertisement.inside?
  end

  def test_side_type_to_s
    advertisement = advertisements(:pref1)
    advertisement.update_attributes(:side_type => Advertisement::INSIDE_TYPE)
    assert_equal "県の広告", advertisement.side_type_to_s
    advertisement.update_attributes(:side_type => Advertisement::OUTSIDE_TYPE)
    assert advertisement.valid?
    assert_equal "企業広告", advertisement.side_type_to_s
  end

  def test_show_in_header_to_s
    advertisement = advertisements(:pref1)
    advertisement.update_attributes(:show_in_header => true)
    assert_equal "表示する", advertisement.show_in_header_to_s
    advertisement.update_attributes(:show_in_header => false)
    assert advertisement.valid?
    assert_equal "表示しない", advertisement.show_in_header_to_s
  end

  def test_delete_img
    advertisement = advertisements(:pref1)
    image = advertisement.image
    FileUtils.copy_file("#{RAILS_ROOT}/tmp/test.png", "#{Advertisement::FILE_PATH}/#{image}")
    advertisement.delete_img
    assert !File.exist?("#{Advertisement::FILE_PATH}/#{image}")
  end

  def test_expired_advertisement_exist
    advertisement = Advertisement.find(advertisements(:pref1).id)
    advertisement.update_attributes(:end_date => Time.local(2006,2,1),
                                    :state => Advertisement::PUBLISHED)
    advertisements =  Advertisement.expired_advertisement
    assert_equal 1, advertisements.size
    assert_equal advertisements.shift.id, advertisements(:pref1).id
  end

  def test_expired_advertisement_not_exist
    advertisement = Advertisement.find(advertisements(:pref1).id)
    advertisement.update_attributes(:end_date => Time.local(2006,2,1),
                                    :state => Advertisement::NOT_PUBLISHED)
    advertisements =  Advertisement.expired_advertisement
    assert_equal 0, advertisements.size
  end

  def test_notify_expired_ads_exist_mail
    advertisements(:pref1).send_advertisement_expired_mail
    assert_equal(1, @emails.size)
    email = @emails.first
    # hack for ruby 1.8.5 whose nkf does not properly convert  utf to jis.
    @expected.subject = NKF.nkf('-EjM', NKF.nkf('-We', "CMSバナー広告掲載処理" ))
    @expected.body    = read_fixture('expired_ads_exist')
    @expected.date    = Time.now
    @expected.from    = User::SUPER_USER_MAIL
    @expected.to      = User::SUPER_USER_MAIL
    assert_equal(NKF::nkf('-jm0', @expected.encoded), email.encoded)
  end

  private

  def read_fixture(action)
    ERB.new(File.read("#{FIXTURES_PATH}/notify_mailer/#{action}")).result
  end

  def encode(subject)
    quoted_printable(subject, CHARSET)
  end
end
