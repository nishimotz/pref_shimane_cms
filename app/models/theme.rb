require 'yaml'

class Theme

  attr_accessor :name, :path

  def self.themes_root
    File.join(RAILS_ROOT,'/themes')
  end

  def self.find(arg)
    case arg
    when :all
      find_all_themes(arg)
    else
      theme = new(arg)
      theme.path ? theme : nil
    end
  end

  def self.find_all_themes(arg)
    Dir.glob("#{themes_root}/*").sort.select {|f|
      File.readable?(File.join(f, 'config.yml'))
    }.compact.map {|dir|
      new(File.basename(dir))
    }
  end

  def self.current_theme
    new(SiteComponents[:theme])
  end

  def initialize(name)
    @name = name
    @path = File.join(self.class.themes_root, name)
  end

  def description
    conf = YAML.load_file(File.join(path, 'config.yml'))
    conf[:description]
  end

  def images_path
    File.join(path, 'images')
  end

  def stylesheets_path
    File.join(path, 'stylesheets')
  end
end
