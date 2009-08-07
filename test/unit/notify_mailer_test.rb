require File.dirname(__FILE__) + '/../test_helper'
require 'notify_mailer'
require 'nkf'

class NotifyMailerTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "iso-2022-jp"

  fixtures :sections, :users, :page_contents

  include ActionMailer::Quoting

  def setup
    Time.redefine_now(Time.mktime(2006, 2, 2))
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
  end

  def test_publish_request
    section = sections(:section1_1)

#    @expected.subject = NKF.nkf('-WjM', "CMS 依頼(ジャンル1_index1)")
    @expected.subject = NKF.nkf('-EjM', NKF.nkf('-We', "CMS 依頼(ジャンル1_index1)"))
    @expected.body    = read_fixture('publish_request')
    @expected.date    = Time.now
    @expected.from    = users(:normal_user).mail
    @expected.to      = users(:section_manager).mail
    assert_equal(NKF::nkf('-jm0', @expected.encoded),
                 NotifyMailer.create_status_mail(section, 
                                             page_contents(:genre1_index).id,
                                             @expected.from,
                                             @expected.to,
                                             '依頼').encoded)
  end

  def test_enquete_answer_exist
    section = sections(:section1_1)
    subject = "CMS : アンケート受信のお知らせ"
    @expected.subject = NKF.nkf('-WjM', "CMS : アンケート受信のお知らせ")
    @expected.subject = NKF.nkf('-EjM', NKF.nkf('-We', "CMS : アンケート受信のお知らせ"))
    @expected.body    = read_fixture('enquete_answer_exist')
    @expected.date    = Time.now
    @expected.from    = CMSConfig[:super_user_mail]
    @expected.to      = users(:section_manager).mail
    assert_equal(NKF::nkf('-jm0', @expected.encoded),
                 NotifyMailer.create_enquete_answer_exist(section,
                                             page_contents(:genre1_index).id,
                                             '',
                                             @expected.to,
                                             '').encoded)
  end

  private

  def read_fixture(action)
    ERB.new(File.read("#{FIXTURES_PATH}/notify_mailer/#{action}")).result
  end

  def encode(subject)
    quoted_printable(subject, CHARSET)
  end
end
