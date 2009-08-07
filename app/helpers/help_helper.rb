module HelpHelper
  def get_category_rowspan_count(category)
    count = 0
    count = category.children.size if category
    return 1 if count.zero?
    return count
  end

  def get_table_column_color(count)
    return "#CCCCCC" if (count % 2).zero?
    return "white"
  end

  def next_link_navigation(help)
    next_help = help.next_help
    if session && !session[:help_category_id].blank? && help.category.parent_id && !next_help.category.parent
      ''
    else
      if next_help
        "<hr />#{link_to("次へ(#{next_help.name})", :action => 'index', :id => next_help.id)}"
      end
    end
  end

  def enable_navigation?(category)
    if category.navigation
      image_tag('wakaba.png', :width => '16', :height => '20')
    end
  end

  def related_helps(help)
    str = "<ol>"
    help.category.helps.each do |related_help|
      str << "<li style=\"margin: -2px 0 0 20px;\">#{link_to_if(related_help.link_enable?(help), related_help.name, :action => 'index', :id => related_help.id)}</li>"
    end
    str << "</ol>"
    return str
  end

  def related_categories(help)
    return '' unless help.category.parent_id
    str = "<hr /><ul>"
    if help.category.parent
      related_categories = help.category.parent.children
    else
      related_categories = HelpCategory.find(:all, :conditions => ['parent_id is null'])
    end
    related_categories.each do |category|
      str << "<li style=\"margin: -2px 0 0 0px;background: none;\">#{image_tag('folder.png', :alt => '', :class => "folder")}#{link_to_if(!category.helps.empty?, category.name, :action => 'index', :category_id => category.id)}</li>"
    end
    str << "</ul>"
    return str
  end

  def help_open_category_link(root, params, icon_name, action_name, help_id)
    str = link_to_remote(image_tag('open.png', :border => 0, :alt=>'-'),
                         :url => {
                           :action => 'help_close', :id => root.id,
                           :help_id => help_id,
                           :category_id => params[:category_id],
                           :action_name => action_name
                         },
                         :update => "dir-#{root.id}")
    str << "<span id=\"h#{root.id}\">"
    str << image_tag(icon_name, :alt => '', :class => "folder")
    str << link_to_if(action_name == "list" && !root.helps.empty?, h(root.name),
                      :action => 'index', :category_id => root.id)
    str << "</span>"
    return str
  end

  def help_close_category_link(root, params, icon_name, action_name, help_id)
    str = ''
    str << link_to_remote(image_tag('closed.png', :border => 0, :alt=>'+'),
                          :url => {
                            :action => 'help_open', :id => root.id,
                            :help_id => help_id,
                            :category_id => params[:category_id],
                            :action_name => action_name
                          },
                          :update => "dir-#{root.id}")
    str << "<span id=\"h#{root.id}\">"
    str << image_tag(icon_name, :alt => '', :class => "folder")
    str << link_to_if(action_name == "list", h(root.name),
                      :action => 'index', :category_id => root.id)
    str << "</span>"
    return str
  end

  def help_list(mode, root, help_obj)
    str = ""
    if mode == :help && !root.helps.empty? && help_obj
      str << "<ul class=\"help_list\">"
      root.helps.each do |help|
        if help && help.public && !help.public.zero?
          str << "<li class=\"help_list\">"
          if session[:help]
            str << link_to_remote(help.name, {:url => {:action => 'change_right_display_search', :id => help, :keywoed => session[:help]}, :update => 'div-light'})
          else
            str << '<span style="background-color: pink">' if help_obj.id == help.id
#            str << link_to_remote(help.name, {:url => {:action => 'change_right_pain', :id => help, :help_id => help, :category_id => params[:category_id]}, :update => 'div-light'}, :title => help.name)
            str << link_to(help.name, :action => 'index', :id => help, :help_id => help, :category_id => params[:category_id])
            str << '</span>' if help_obj.id == help.id
          end
          str << "</li>"
        end
      end
      str << "</ul>"
    end
    return str
  end

  def search_help_list(helps, help_obj)
    str = ""
    str << "<ul class=\"help_list\">"
    helps.each do |help|
      unless help.public.zero?
        str << "<li class=\"help_list\">"
#        str << '<span style="background-color: pink;">' if help_obj.id == help.id
        str << link_to_remote(help.name, {:url => {:action => :change_right_pain, :id => help, :help_id => help}, :update => 'div-light'}, :title => help.name)
#        str << link_to(help.name, :action => 'search', :id => help, :help_id => help)
#        str << '</span>' if help_obj.id == help.id
        str << "</li>"
      end
    end
    str << "</ul>"
  end
end
