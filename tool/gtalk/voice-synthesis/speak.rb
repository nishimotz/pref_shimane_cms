#!/usr/bin/ruby -Ke

require "tempfile"
require "logger"

TEXT = <<EOS
LDFLAGSに-lchasenではうまく動作しない。
「<」小なりや、「>」大なりはエスケープしないと解析に失敗する。
エスケープ後にアンエスケープはされない。
いろいろ課題が残りますね。
EOS

BASE_DIR = "/home/kouji/work/pref-shimane-cms/gtalk"

CHASEN_COMMAND = "/usr/bin/chasen"
CHASEN_CONFIG_FILE = File.join(BASE_DIR, "gtalk/chasenrc")

XSLT_COMMAND = "/usr/bin/xsltproc"
XSLT_STYLESHEET_FILE =
  File.join(BASE_DIR, "morph/chaone-1.2.0/chaone_t_EUC-JP.xsl")

GTALK_COMMAND = "./gtalk -C ssm.conf > /dev/null"
CONVERT_MP3_COMMAND = "/usr/bin/lame -r -s 16 -m m -x -S --silent -b 32 --cbr - -"

LOG_FILE = "/tmp/speak.log"
LOG_LEVEL = Logger::DEBUG

# 文の区切り
PUNCTUATION_MARK = <<EOS
  <AP orth="。" pron="。" aType="0" silence="SILE">
    <W2 orth="。" pron="。" pos="その他-句点" aType="0" aConType="">
      <W1 orth="。" pron="。" pos="その他-句点"/>
    </W2>
  </AP>
EOS

$logger = Logger.new(LOG_FILE)
$logger.level = LOG_LEVEL

# text -> chasen -> modify -> chaone
# modify: added xml declaration, hiragana -> katakana
def text_analysis(text)
  chasen_result = ""
  cmd = [CHASEN_COMMAND, "-r", CHASEN_CONFIG_FILE].join(" ")
  IO.popen(cmd, "r+") do |chasen|
    chasen.write(escape_text(text))
    chasen.close_write
    chasen_result = chasen.read
  end
  result = []
  chasen_result.scan(/<S>.*?<\/S>/m) do |s|
    cmd = [XSLT_COMMAND, XSLT_STYLESHEET_FILE, "-"].join(" ")
    IO.popen(cmd, "r+") do |xslt|
      xslt.puts('<?xml version="1.0" encoding="EUC-JP"?>')
      xslt.write(modify_chasen_result(s))
      xslt.close_write
      result.push(xslt.read.gsub(/<\/S>/, PUNCTUATION_MARK + "</S>"))
    end
  end
  return result
end

def escape_text(text)
  return text.gsub(/&/n, '&amp;').gsub(/\"/n, '&quot;').gsub(/>/n, '&gt;').
    gsub(/</n, '&lt;')
end

def modify_chasen_result(text)
  return text
end

def voice_synthesis(part, raw_filename)
  Dir.chdir(File.join(BASE_DIR, "gtalk")) do |dir|
    parsed_text_file = Tempfile.new("parsed-text-filename")
    parsed_text_filename = parsed_text_file.path
    parsed_text_file.write(part)
    parsed_text_file.close
    ENV['LANG'] = 'ja_JP.EUC-JP'
    IO.popen(GTALK_COMMAND, "w") do |gtalk|
      gtalk.puts("set ParsedText = #{parsed_text_filename}")
      gtalk.puts("set Save = #{raw_filename}")
      gtalk.puts("set Run = EXIT")
    end
    parsed_text_file.close(true)
  end
end

def main
  $logger.debug("start: speak.rb")
  $logger.debug("start: text_analysis")
  parts = text_analysis(TEXT)  
  $logger.debug("end: text_analysis")
  $logger.debug(parts.join)

  $logger.debug("start: convert mp3")
  IO.popen(CONVERT_MP3_COMMAND, "w") do |mp3|
    parts.each do |part|
      raw_file = Tempfile.new("voice-synthesis")
      raw_filename = raw_file.path
      raw_file.close
      $logger.debug("start: voice_synthesis")
      voice_synthesis(part, raw_filename)
      $logger.debug("end: voice_synthesis")
      mp3.write(File.read(raw_filename))
      raw_file.close(true)
    end
  end
  $logger.debug("end: convert mp3")
end

main
