#!/usr/bin/ruby -Ku

require 'cgi'
require 'rubi_adder'
require 'htree'
require 'nkf'
require 'net/http'
require 'uri'

cgi = CGI.new
uri = cgi['uri'].to_s
if uri.empty?
  print(cgi.header('type' => 'text/html', 'charset' => 'UTF-8'))
  print(<<EOS)
<html>
<body>
<form action="rubi-adder.cgi">
<input type="text" name="uri" size="80" value="http://www.pref.shimane.jp/">
<input type="submit" value="ルビふり">
</form>
</body>
</html>
EOS
else
  print(cgi.header('type' => 'text/html', 'charset' => 'UTF-8'))
  uri = URI.parse(uri)
  req = Net::HTTP::Get.new(uri.path)
  res = Net::HTTP.start(uri.host, uri.port) { |http|
    http.request(req)
  }
  html = NKF.nkf('-w', res.body)
  xml = ''
  HTree.parse(html).display_xml(xml)
  begin
    added_rubi = RubiAdder.add(NKF.nkf('-w', xml))
    print(added_rubi)
  rescue
    puts('<html><body><pre>')
    print(CGI.escapeHTML($!.to_s))
    $!.backtrace.each do |line|
      print(CGI.escapeHTML(line))
      puts('<br>')
    end
    puts("</pre></body></html>")
  end
end
