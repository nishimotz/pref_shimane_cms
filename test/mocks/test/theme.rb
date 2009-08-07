require 'app/models/theme'
class Theme
  def self.themes_root
    File.join(File.dirname(__FILE__), 'themes')
  end
end
