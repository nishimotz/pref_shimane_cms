ActionController::Routing::Routes.draw do |map|
  # for admin access
  map.connect '_admin/preview/:id', :controller => 'visitor', :action => 'show'
  map.connect '_admin/preview_revision/:id', :controller => 'visitor', :action => 'show_revision'
  map.connect '_admin/word/:action/:id', :controller => 'word'
  map.connect '_admin/:action/:id', :controller => 'admin'

  # for help access
  map.connect '_help/:action/:id', :controller => 'help'

  # for board access
  map.connect '_board/:action/:id', :controller => 'board'
  map.connect '_board_comment/:action/:id', :controller => 'board_comment'
  map.connect 'board/:id/:page',
    :controller => 'board_comment', :action => "view"

  # for enquete access
  map.connect '_enquete/:action/:id', :controller => 'enquete'

  # for statistics access
  map.connect '_statistics/:action/:id', :controller => 'statistics'

  # for advertisements access
  map.connect '_advertisement/:action/:id', :controller => 'advertisement'

  # for mailmagazine access
  map.connect '_mailmagazine/:action/:id', :controller => 'mailmagazine'

  # for site_componentes access
  map.connect '_site/:action', :controller => 'site', :action => 'config'

  # for web_monitor access
  map.connect '_web_monitor/:action/:id', :controller => 'web_monitor'

  # for visitor access
  map.connect '_qr/*path', :controller => 'visitor', :action => 'qrcode'
  map.connect '*path', :controller => 'visitor', :action => 'view'
end
