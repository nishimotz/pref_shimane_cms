#
# Iso2022Mailer -  日本語メール送信処理プラグイン
#
# from :
# http://wiki.fdiary.net/rails/?ActionMailer (moriq さん)
# http://wota.jp/ac/?date=20050731#p01 (くまくまーさん)
#
# Model で Iso2022jpMailer を継承して使用する
# (see http://d.hatena.ne.jp/drawnboy/20051114/1131977235 )
# TestMailer < Iso2022jpMailer
#  ...
# end
# 
# MIT License
#

require 'nkf'
class Iso2022jpMailer < ActionMailer::Base
  @@default_charset = 'iso-2022-jp'   
  # 本文 (body) を iso-2022-jp へ変換
  def create!(*)
    super
    @mail.body = NKF.nkf('-j', @mail.body)
    return @mail
  end
end
