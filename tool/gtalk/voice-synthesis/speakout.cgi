#!/usr/bin/ruby -Ke

require 'cgi'

text = 'こんにちは、赤ちゃん。'

Dir.chdir('/home/kouji/work/pref-shimane-cms/gtalk/gtalk') do
  ENV['LANG'] = 'ja_JP.EUC-JP'
  IO.popen("./gtalk -C ssm.conf > /var/tmp/log", "w") do |f|
    f.puts("set Text = #{text}")
    f.puts("set Save = /var/tmp/#{$$}.raw")
    f.puts("set Run = EXIT")
  end
end
system("lame -r -s 16 -m m -x -S --silent -b 32 --cbr /var/tmp/#{$$}.raw /var/tmp/#{$$}.mp3")

cgi = CGI.new
print cgi.header('type' => 'audio/mpeg')
print File.read("/var/tmp/#{$$}.mp3")
