#
# ActiveHeart
# 日本語化するのに便利そうなのごちゃまぜplugin
#
# MIT License
# gorou <hotchpotch@gmail.com>
# 
require_dependency 'active_record_messages_ja'if defined? ActiveRecord::Base
require_dependency 'trans_sid'
require_dependency 'iso2022jp_mailer' if defined? ActionMailer::Base
