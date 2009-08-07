#!/usr/bin/ruby -Ku

require 'cgi'
require 'voice_synthesis'
require 'logger'

cgi = CGI.new
$stdout.sync = true
$stdout.print(cgi.header('type' => 'audio/mpeg',
                         'Content-Disposition' => 'inline; filename="voice_synthesis.mp3";'))

logger = Logger.new('/tmp/voice_synthesis.cgi.log')
logger.level = Logger::DEBUG
vs = VoiceSynthesis.new
vs.logger = logger
text = cgi['text'].to_s
vs.synthesize(text, $stdout)
