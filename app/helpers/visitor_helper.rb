module VisitorHelper
  include AdvertisementHelper
  include PluginHelper

  def genre_auto_content(name)
    str = []
    str << "<h1>#{name}</h1>"
    str << plugin('page_list')
    unless  @genre.children.empty?
      str << plugin('sub_genre_list')
    end
    str.join("\n")
  end

  def section_main
    <<-"HTML"
<div id="section_main">
<div class="section_content">
<!-- begin_content -->
#{render(:partial => '/visitor/content')}
<!-- end_content -->
</div>
</div>
    HTML
  end

  def section_subject
    html = []
    html << <<-HTML
<div id="section-subject">
<div class="section-content">
<h2><a class="division_title" href="../section.html">組織別情報</a></h2>
    HTML
    @divisions = Division.find(:all, :conditions => ['enable = true'], :order => 'number')
    @divisions.each_with_index do |division, count|
    html << <<-"HTML"
<h2><a class="division_name" href="../section.html#s#{count}">#{h(division.name)}</a></h2>
    HTML
      if @genre.section && division.id == @genre.section.division_id
        # Find sub genre if this section top page's genre matches
        # the section.
        sections = Section.find(:all, 
                                :conditions => ['division_id = ?', division.id],
                                :order => 'number')
        html << "<ul>"
        sections.each do |section|
          html << "<li>"
          if section.top_genre_id && !section.top_genre_id.zero?
            genre = section.genre
          else
            genre = nil
          end
          if section.link.blank?
            if genre
              html << "<a href=\"#{genre.link_path}\">#{section.name}</a>"
            else
              html << h(section.name)
            end
          else
            html << "<a href=\"#{section.link}\">#{section.name}</a>"
          end
          html << "</li>"
        end
        html << "</ul>"
      end
    end
    html << "</div>"
    html << "</div>"
    html.join("\n")
  end

  def pref_symbol_img
    alt = "島根県公式ウェブサイト(ゆったり・清らかなしまね 島根県)" 
    if emergency_exist?
      image_tag "/images/symbol/pref_symbol_sub.gif", :alt => alt, :class => "sub_symbol"
    else
      image_tag "/images/symbol/pref_symbol.gif", :alt => alt
    end
  end

  def top_emergency
    <<-HTML
<div id="emergency-container">
  <div id="top-emergency">
    <div id='emergency' class="round_corner">
      <div class='overflow'>
        <div class='emergency-header'>
          <div class='header-title'>
            <h2>緊急情報</h2>
          </div>
          <div class='header-note'>
            <p>県が発表している緊急情報を掲載しています。</p>
          </div>
          <div style='clear: both'></div>
        </div>
        #{plugin('emergency')}
      </div>
    </div>
  </div>
</div>
    HTML
  end

  def top_photo_link
    SiteComponents[:top_photo_link] || CMSConfig[:base_uri]
  end
end
