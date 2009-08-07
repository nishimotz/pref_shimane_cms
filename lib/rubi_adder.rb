require 'chasen'
require 'nkf'
require 'kakasi'

class RubiAdder
  def self.add(html)
    before_body = html.slice!(/\A.*?<body.*?>\n?/m)
    after_body = html.slice!(/\n?<\/body.*?>.*?\z/m)
    body = html.split(ADDED_RUBI_REGEXP).collect { |s|
      if ADDED_RUBI_REGEXP =~ s
        s
      else
        exclude_regexp = %r'(<.*?>|\s+)'m
        s.split(exclude_regexp).collect { |s2|
          if s2.empty? || exclude_regexp =~ s2
            s2
          else
            add_rubi(s2)
          end
        }
      end
    }.join
    return [before_body, body, after_body].join
  end
  
  private

  ADDED_RUBI_REGEXP = %r'(<ruby[^>]*>.*?</ruby\s*>)'m
  KANJI_PATTERN = '[' + NKF.nkf('-We', '亜-遙') + ']'
  OKURIGANA_PATTERN = '[ぁ-んァ-ンー]'

  def self.add_rubi(text)
    result = ""
    Chasen.sparse(NKF.nkf('-We', text)).to_a.each do |elem|
      orig, rubi, = *NKF.nkf('-Ew', elem).split(/\t/)
      orig.strip!
      if orig == 'EOS'
        result << "\n"
        next
      end
      if rubi.empty?
        rubi = NKF.nkf('-Ew', Kakasi.kakasi('-JH', NKF.nkf('-We', orig)))
      end
      rubi = to_hiragana(rubi)
      if /#{KANJI_PATTERN}/e =~ NKF.nkf('-We', orig)
        split_okurigana(orig, rubi).each do |(orig, rubi)|
          if rubi
            result << "<ruby>#{orig}<rp>(</rp><rt>#{rubi}</rt><rp>)</rp></ruby>"
          else
            result << orig
          end
        end
      else
        result << orig
      end
    end
    return result.chomp
  end

  def self.to_hiragana(text)
    return NKF.nkf('-Ew', Kakasi.kakasi('-KH', NKF.nkf('-We', text)))
  end

  def self.split_okurigana(text, rubi)
    text_parts = text.split(/(#{OKURIGANA_PATTERN}+)/u)
    if text_parts.first.empty?
      text_parts.shift
    end
    result = [[text, rubi]]
    if text_parts.length == 1
      return result
    end
    hiragana_text_parts = text_parts.collect { |i|
      to_hiragana(i)
    }
    if /^#{hiragana_text_parts.first}/ =~ rubi
      result.unshift([text_parts.first, nil])
      result[1] = [result[1][0].sub(/^#{text_parts.first}/, ''),
                   result[1][1].sub(/^#{hiragana_text_parts.first}/, '')]
    end
    if /#{hiragana_text_parts.last}$/ =~ rubi
      result.push([text_parts.last, nil])
      result[-2] = [result[-2][0].sub(/#{text_parts.last}$/, ''),
                    result[-2][1].sub(/#{hiragana_text_parts.last}$/, '')]
    end
    return result
  end
end
