#!/usr/bin/ruby -Ke

require 'kakasi'

class ChaoneFilterExitError < RuntimeError; end

class ChaoneFilter
  attr_accessor :xslt_path, :xslt_stylesheet_file, :chaone_path, :logger
  
  def initialize
    @xslt_path = '/usr/bin/xsltproc'
    @xslt_stylesheet_file = 'chaone_t_EUC-JP.xsl'
    @chaone_path = File.expand_path('../morph/chaone-1.2.0',
                                    File.dirname(__FILE__))
    @logger = nil
  end

  def filter(input, output)
    debug_log('processing ChaOne filter')
    if select([input], nil, nil, 60).nil?
      raise ChaoneFilterExitError.new
    end
    s = input.gets
    if s.nil?
      raise ChaoneFilterExitError.new
    end
    IO.popen(xslt_command, 'r+') do |xslt|
      debug_log('input:')
      first_time = true
      while s
        s.gsub!(/\255\344/e, '　')
        debug_log(s)
        if first_time
          xslt.puts('<?xml version="1.0" encoding="EUC-JP"?>')
          first_time = false
        end
        xslt.write(modify_input_line(s))
        while IO.select([xslt], nil, nil, 0)
          output.write(xslt.sysread(512))
        end
        if /<\/S>/ =~ s
          break
        end
        s = input.gets
      end
      if s.nil?
        raise ChaoneFilterExitError.new
      end
      xslt.close_write
      debug_log('output:')
      while s = xslt.read(512)
        output.write(s)
        debug_log(s)
      end
    end
    debug_log('processed')
  end

  private
  
  KANJI_REGEXP = /[亜-遙]/e

  def xslt_command
    return [@xslt_path, File.join(@chaone_path, @xslt_stylesheet_file),
            '-', "2>", "/dev/null"].join(' ')
  end

  def modify_input_line(line)
    return line.sub(/pron="([^"]+)"/) { |s|
      pronunciation = $1
      if is_katakana?(pronunciation)
        s
      else
        debug_log("'#{pronunciation}' is not katakana")
        pronunciation = to_katakana(pronunciation)
        debug_log("converted '#{pronunciation}'")
        %Q'pron="#{pronunciation}"'
      end
    }
  end

  def is_katakana?(str)
    return /[^ァ-ンー]/e !~ str
  end

  def to_katakana(str)
    return Kakasi.kakasi('-JK -HK', str).gsub(/[，．]/e, '')
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

  chaone_filter = ChaoneFilter.new
=begin
  logger = Logger.new('/tmp/chaone-filter.log')
  logger.level = Logger::DEBUG
  chaone_filter.logger = logger
=end
  $stdout.sync = true
  begin
    loop do
      chaone_filter.filter($stdin, $stdout)
    end
  rescue ChaoneFilterExitError
  end
end
