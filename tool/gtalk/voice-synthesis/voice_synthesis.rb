$KCODE = "u"

require 'iconv'
require 'tempfile'
require 'digest/md5'
begin
  require 'filter'
  require 'htree'
rescue LoadError
  $:.unshift("#{File.dirname(__FILE__)}/../../../lib")
  require 'filter'
  require 'htree'
end

class VoiceSynthesis
  CONVERT_LIST = {
    '０' => '0',
    '１' => '1',
    '２' => '2',
    '３' => '3',
    '４' => '4',
    '５' => '5',
    '６' => '6',
    '７' => '7',
    '８' => '8',
    '９' => '9',
    '（' => '(',
    '）' => ')',
    '−' => '-',
  }
  CONVERT_LIST_RE = /#{CONVERT_LIST.keys.collect{|i| Regexp.quote(i)}.join('|')}/u

  MONTH_CONVERT_LIST = {
    '01' => '一',
    '02' => '二',
    '03' => '三',
    '04' => '四',
    '05' => '五',
    '06' => '六',
    '07' => '七',
    '08' => '八',
    '09' => '九',
    '10' => '十',
    '11' => '十一',
    '12' => '十二',
  }

  MONTH_RE = /([^\d]|^)(0?[1-9]|1[0-2])月/

  def self.replace_phone_number(text, &block)
    return text.gsub(/[\d\-\(\)]+/) { |s|
      if /\A\(.+\)\z/ =~ s
        replace_phone_number(s[1..-2], &block)
      else
        if phone_number?(s)
          yield(s)
        else
          s
        end
      end
    }
  end

  def self.replace_month(text)
    text.gsub(MONTH_RE) do |str|
      pre, month = $1, $2
      month = "0#{month}" if month.length == 1
      "#{pre}#{MONTH_CONVERT_LIST[month]}月"
    end
  end

  attr_accessor :gtalk_path
  attr_accessor :gtalk_options
  attr_accessor :lame_path
  attr_accessor :lame_options
  attr_accessor :max_part_length
  attr_accessor :logger

  def initialize
    @gtalk_path =
      File.expand_path('../gtalk/gtalk', File.dirname(__FILE__))
    @gtalk_options = ['-C', 'ssm.conf', '2>', '/dev/null']
    @lame_path = `which lame`.chomp # '/usr/local/bin/lame'
    @lame_options =
      ['-r', '-s', '16', '-m', 'm', # '-x', 
       '-S', '-b', '32', '--cbr',
       '--scale', '1.5', '-', '-', '2>', '/dev/null']
    @max_part_length = 1000
    @logger = nil
  end

  # options
  # * tagged
  #   * boolean
  #   * true
  #     * text is tagged
  #   * false
  #     * text is not tagged. convert '<' and '>' to zenkaku.
  # * speed_rate
  #   * float(0.2-)
  #   * small value is fast, large value is slow.
  # * treat_phone_number
  #   * boolean
  #   * true
  #     * tagged phone number.
  def synthesize(text, output, options = {})
    raw_file = Tempfile.new("gtalk")
    raw_filename = raw_file.path
    raw_file.close
    debug_log("start: gtalk")
    exec_gtalk do |gtalk|
      gtalk.puts("set Speaker = female01")
      debug_log("start: lame")
      IO.popen(lame_command, "r+") do |lame|
        lame.sync = true
        split_text(text).each_with_index do |part, i|
          if part == :silence
            speed = 800
            if options[:speed_rate] && options[:speed_rate] != 1.0
              speed *= options[:speed_rate]
            end
            part = %Q'<SILENCE MSEC="#{speed.to_i}"/>'
          else
            part = to_euc(apply_options(part, options))
          end
          # debug_log("part #{i + 1}: |#{part}|")
          gtalk.puts("set Text = #{part}")
          while line = gtalk.gets
            if /rep Speak.stat = READY/ =~ line
              break
            end
          end
          gtalk.puts("set Save = #{raw_filename}")
          gtalk.gets
          File.open(raw_filename) do |f|
            while s = f.read(512)
              lame.write(s)
              while IO.select([lame], nil, nil, 0)
                output.write(lame.sysread(512))
              end
            end
          end
        end
        lame.close_write
        while s = lame.read(512)
          output.write(s)
        end
      end
      debug_log("end: lame")
    end
    debug_log("end: gtalk")
  end

  def synthesize_html(text, output, options = {})
    text.gsub!(%r!</(?:blockquote|dd|div|dl|dt|form|h[1-6]|hr|li|ol|p|pre|table|tbody|td|tfoot|th|thead|tr|ul)>!, "。")
    text.gsub!(/&nbsp;/, ' ')
    text.gsub!(/(<.+?>)+/, ' ')
    text = HTree::Text.new_internal(text).to_s
    text.strip!
    text.gsub!(/\s+/, '、')
    text.gsub!(/、*。+、*/, '。')
    text = '。' if text.empty?
    synthesize(text, output, options)
  end

  def html2m3u(path, uri)
    debug_log("html2m3u: #{path}, #{uri}")
    path_base = path.sub(/\.html\z/, '')
    uri_base = uri.sub(%r!/[^/]*\z!, '/')
    html = File.read("#{path_base}.html.r")
    text = html.gsub(/\r?\n/, '')
    text.sub!(/\A.*?<!-- begin_content -->/m, '')
    text.sub!(/<!-- end_content -->.*?\z/m, '')
    text.gsub!(%r!<ruby([^>]*)>(.*?)<rt>(.*?)</rt>.*?</ruby>!) do
      attr = $1
      ruby_base = $2
      ruby_text = $3
      if /class="custom"/ =~ attr
        ruby_text
      else
        ruby_base.gsub(%r!<rp>.*?</rp>!, '')
      end
    end
    ary = ['']
    text.split(%r!(<h[1-3][^>]*>.*?</h[1-3]>)!m).each do |e|
      text = e.dup
      text.gsub!(/&nbsp;/, ' ')
      text.gsub!(/(<.+?>)+/, ' ')
      text = HTree::Text.new_internal(text).to_s
      text.strip!
      text.gsub!(/\s+/, '、')
      next if text.empty?
      if /\A<h[1-3]/ =~ e
        if ary.last.empty?
          ary.last << text
        else
          ary << text
        end
      else
        ary.last << "、#{text}"
      end
    end
    m3u_path = "#{path_base}.m3u"
    mp3_files = []
    ary.each_with_index do |e, i|
      mp3_path = "#{path_base}.#{i}.mp3"
      mp3_files << mp3_path
      md5_path = "#{path_base}.#{i}.md5"
      old_md5 = File.read(md5_path, 32) rescue ''
      new_md5 = (Digest::MD5::new << e).hexdigest
      if old_md5 == new_md5
        debug_log("skip: #{mp3_path}")
        next
      end
      debug_log("create: #{mp3_path}")
      File.open(mp3_path, 'w') do |f|
        synthesize_html(e, f,
                        :tagged => false,
                        :speed_rate => 0.9,
                        :treat_phone_number => true)
      end
      File.open(md5_path, 'w'){|f| f.print new_md5}
    end
    File.open(m3u_path, 'w') do |f|
      mp3_files.each do |e|
        f.puts "#{uri_base}#{File.basename(e)}"
      end
    end
    (Dir["#{path_base}.*mp3"] - mp3_files).each do |file|
      FileUtils.rm([file, file.sub(/\.mp3\z/, '.md5')], :force => true)
    end
  end

  private

  PHONE_NUMBER_REGEXPS = [
    %r'
      \A
      (?# area code)   (0\d{1,4})-
      (?# city prefix) (\d{1,4})-
      (?# last code)   (\d{4})
      \z
    'x,
    %r'
      \A
      (?# area code)   \((0\d{1,4})\)
      (?# city prefix) (\d{1,4})-
      (?# last code)   (\d{4})
      \z
    'x,
    %r'
      \A
      (?# area code)   (0\d{1,4})
      (?# city prefix) \((\d{1,4})\)
      (?# last code)   (\d{4})
      \z
    'x,
  ]

  HANDY_PHONE_NUMBER_REGEXPS = [
    %r'
      \A
      (?# area code)   (0\d{2})-
      (?# city prefix) (\d{4})-
      (?# last code)   (\d{4})
      \z
    'x,
    %r'
      \A
      (?# area code)   \((0\d{2})\)
      (?# city prefix) (\d{4})-
      (?# last code)   (\d{4})
      \z
    'x,
    %r'
      \A
      (?# area code)   (0\d{2})
      (?# city prefix) \((\d{4})\)
      (?# last code)   (\d{4})
      \z
    'x,
  ]

  def self.phone_number?(s)
    numbers = s.gsub(/[\-\(\)]+/, '')
    if numbers.length == 10
      PHONE_NUMBER_REGEXPS.each do |re|
        if re =~ s
          return true
        end
      end
    elsif numbers.length == 11
      HANDY_PHONE_NUMBER_REGEXPS.each do |re|
        if re =~ s
          return true
        end
      end
    end
    return false
  end

  def to_euc(text)
    Filter.convert(Filter.remove_non_japanese_chars(text), 'utf-8', 'euc-jp')
  end

  def split_text(text)
    parts = []
    first_time = true
    text.split(/。|$/um).each do |part|
      part.gsub!('　', ' ')
      part.sub!(/\A[、\s]*/u, '')
      part.gsub!(/(、\s*)+/u, '、')
      part.strip!
      if !part.empty?
        if first_time
          first_time = false
        else
          parts << :silence
        end
        parts += part.scan(/.{1,#{@max_part_length}}/u)
      end
    end
    return parts
  end

  def apply_options(text, options)
    if !options[:tagged]
      text = text.gsub(/</, '＜').gsub(/>/, '＞')
    end
    if options[:treat_phone_number]
      text = text.gsub(CONVERT_LIST_RE){|c| CONVERT_LIST[c]}
      text = self.class.replace_phone_number(text) do |s|
        %Q'<CONTEXT TYPE="PHONE">#{s}</CONTEXT>'
      end
    end
    text = self.class.replace_month(text)
    if options[:speed_rate] && options[:speed_rate] != 1.0
      text = %Q'<RATE SPEED="#{options[:speed_rate]}">#{text}</RATE>'
    end
    return text
  end

  def gtalk_command
    return @gtalk_path + ' ' + @gtalk_options.join(' ')
  end

  def lame_command
    return @lame_path + ' ' + @lame_options.join(' ')
  end

  def exec_gtalk
    Dir.chdir(File.dirname(@gtalk_path)) do |dir|
      ENV['LANG'] = 'ja_JP.EUC-JP'
      IO.popen(gtalk_command, "r+") do |gtalk|
        gtalk.sync = true
        gtalk.puts("prop Text.text = NoAutoOutput")
        gtalk.puts("prop Speak.text = NoAutoOutput")
        yield(gtalk)
        gtalk.puts("set Run = EXIT")
        gtalk.gets
      end
    end
  end

  def debug_log(msg)
    if @logger
      # add datetime since Rails changes the default logger format :(
      @logger.debug(Time.now.strftime('%b %d %H:%M:%S ') + msg)
    end
  end
end

if $0 == __FILE__
  require 'logger'

  text = <<-EOS.gsub(/^ {4}/, '')
    音声合成のテストです。
    ABCDEFGやabcdefgなどのアルファベット。
    「<」や、「>」はエスケープしないと解析に失敗する。
    エスケープ後にアンエスケープはされない。
    「&」や「""」などの記号の扱いも考える必要があります。
    いろいろ課題が残りますね。
    「ぐ」は、読みがカタカナにならない言葉です。
    電話番号999-1234-5678です。
    電話番号０８５２−２８−９２８０です。
  EOS
  text += Iconv.conv('utf-8', 'ucs-2be', "\x21\x16\x21\x60\x21\x61\x21\x62\x21\x63\x21\x64\x21\x65\x21\x66\x21\x67\x21\x68\x21\x69\x21\x70\x21\x71\x21\x72\x21\x73\x21\x74\x21\x75\x21\x76\x21\x77\x21\x78\x21\x79\x33\x49\x33\x14\x33\x22\x33\x4d\x33\x18\x33\x27\x33\x03\x33\x36\x33\x51\x33\x57\x33\x0d\x33\x26\x33\x23\x33\x2b\x33\x4a\x33\x3b\x33\x9c\x33\x9d\x33\x9e\x33\x8e\x33\x8f\x33\xc4\x33\xa1\x33\x7b\x21\x16\x33\xcd\x21\x21\x32\xa4\x32\xa5\x32\xa6\x32\xa7\x32\xa8\x32\x31\x32\x32\x32\x39\x33\x7e\x33\x7d\x33\x7c\xff\x0d")
  text += "おしまい。"
  logger = Logger.new('voice_synthesis.log')
  logger.level = Logger::DEBUG
  vs = VoiceSynthesis.new
  vs.logger = logger
  vs.synthesize(text, $stdout,
                :tagged => false,
                :speed_rate => 1.0,
                :treat_phone_number => false)
end
