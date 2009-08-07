#!/usr/bin/env ruby -Ke

score = 2000

ARGF.each do |l|
  l.chomp!
  kanji, yomi = l.split(/\t/, 2)
  next unless kanji && yomi
  puts "(�ʻ� (̾�� ��ͭ̾�� ����)) ((���Ф��� (%s %i)) (�ɤ� %s) (ȯ�� %s) )" % [kanji, score, yomi, yomi]
end
