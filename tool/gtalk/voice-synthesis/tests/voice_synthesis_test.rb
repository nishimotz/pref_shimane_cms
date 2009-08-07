require 'test/unit'
require 'voice_synthesis'

class VoiceSynthesisTest < Test::Unit::TestCase
  def test_replace_phone_number__replacing
    res = VoiceSynthesis.replace_phone_number('(090)1234-5678') { |s|
      %Q'<CONTEXT TYPE="PHONE">#{s}</CONTEXT>'
    }
    assert_equal('<CONTEXT TYPE="PHONE">(090)1234-5678</CONTEXT>', res)
    res = VoiceSynthesis.replace_phone_number('[(090)1234-5678]') { |s|
      %Q'<CONTEXT TYPE="PHONE">#{s}</CONTEXT>'
    }
    assert_equal('[<CONTEXT TYPE="PHONE">(090)1234-5678</CONTEXT>]', res)
  end

  def test_replace_phone_number__matching
    test_and_expect_data =
      [
       ['09-1234-5678', '09-1234-5678'],
       ['091-234-5678', '091-234-5678'],
       ['0912-34-5678', '0912-34-5678'],
       ['09123-4-5678', '09123-4-5678'],

       ['(09)1234-5678', '(09)1234-5678'],
       ['(091)234-5678', '(091)234-5678'],
       ['(0912)34-5678', '(0912)34-5678'],
       ['(09123)4-5678', '(09123)4-5678'],

       ['09(1234)5678', '09(1234)5678'],
       ['091(234)5678', '091(234)5678'],
       ['0912(34)5678', '0912(34)5678'],
       ['09123(4)5678', '09123(4)5678'],

       ['090-1234-5678', '090-1234-5678'],
       ['(090)1234-5678', '(090)1234-5678'],
       ['090(1234)5678', '090(1234)5678'],

       ['091-234-5678', '091-234-5678'],
       ['0912-34-5678', '0912-34-5678'],
       ['09123-4-5678', '09123-4-5678'],

       ['(09123-4-5678)', '09123-4-5678'],
       ['((09123-4-5678))', '09123-4-5678'],
       ['(((09123-4-5678)))', '09123-4-5678'],
       ['((((09123-4-5678))))', '09123-4-5678'],

       ['((09123)4-5678)', '(09123)4-5678'],
       ['(09123(4)5678)', '09123(4)5678'],
      ]
    test_and_expect_data.each do |(test_data, expect_data)|
      replaced = false
      res = VoiceSynthesis.replace_phone_number(test_data) { |s|
        assert_equal(expect_data, s)
	replaced = true
        s
      }
      assert_equal(true, replaced, 
                   "could not replaced" + 
		   " test_data=[#{test_data.inspect}]" +
                   " expect_data=[#{expect_data.inspect}]")
    end
  end

  def test_replace_phone_number__not_matching
    not_phone_numbers =
      [
       '-5678',
       '5678',
       '12-',
       '12-345',
       '12-34567',
       '12345-6789',
       '0901-234-5678',
       '09012-34-5678',
       '090123-4-5678',
       '(0901)234-5678',
       '(09012)34-5678',
       '(090123)4-5678',
       '0901(234)5678',
       '09012(34)5678',
       '090123(4)5678',
       '1-090-1234-5678-2',
       '090-1234-5678-2',
       '1-090-1234-5678',
       '0-1-2',
       '012-3-4567',
       '012-34-5678',
       '012-3-4567',
       '0-1-23456789',
       '01-23456-789',
       '01-234-56789',
       '(090123))4-5678',
       '(090123----4-5678',
       '(090123-4-5678',
       '090123)4-5678',
      ]
    not_phone_numbers.each do |test_data|
      replaced = false      
      VoiceSynthesis.replace_phone_number(test_data) do |s|
        replaced = true
      end
      assert_equal(false, replaced, "replaced test_data=[#{test_data.inspect}]")
    end
  end
end
