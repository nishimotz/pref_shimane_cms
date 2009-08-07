module MIMEHelper
  MIME_TYPES = {
    '.gif'  => 'image/gif',
    '.jpg'  => 'image/jpeg',
    '.jpeg' => 'image/jpeg',
    '.png'  => 'image/png',
    '.bmp'  => 'image/bmp',
    '.wmf'  => 'image/wmf',
    '.wmv'  => 'video/x-ms-wmv',
    '.rm'   => 'audio/x-pn-realaudio',
    '.txt'  => 'text/plain',
    '.html' => 'text/html',
    '.htm'  => 'text/html',
    '.css'  => 'text/css',
    '.js'   => 'text/javascript',
    '.rtf'  => 'text/rtf',
    '.xml'  => 'text/xml',
    '.xsl'  => 'text/xsl',
    '.rdf'  => 'application/rdf+xml',
    '.doc'  => 'application/msword',
    '.xls'  => 'application/vnd.ms-excel',
    '.ppt'  => 'application/vnd.ms-powerpoint',
    '.pdf'  => 'application/pdf',
    '.jtd'  => 'application/jxw',
    '.lzh'  => 'application/x-lzh',
    '.swf'  => 'application/x-shockwave-flash',
  }

  def content_type(filename)
    MIME_TYPES[File.extname(filename)] || 'application/octet-stream'
  end

  module_function :content_type
end
