#!/usr/bin/env ruby -Ke

score = 2000

ARGF.each do |l|
  l.chomp!
  kanji, yomi = l.split(/\t/, 2)
  next unless kanji && yomi
  puts "(品詞 (名詞 固有名詞 一般)) ((見出し語 (%s %i)) (読み %s) (発音 %s) )" % [kanji, score, yomi, yomi]
end
