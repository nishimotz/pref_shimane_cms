module LoginHelper
  def login
    @info_pages, @infos = paginate(:infos, :per_page => 10,
                                   :order => 'last_modified desc')
    case @request.method
      when :post
      if @session[:user] = User.authenticate(@params[:user_login],
                                             @params[:user_password])
        flash['notice']  = "ログインしました"
        controller = params[:redirect] ? params[:redirect][:controller] : ''
        action = params[:redirect] ? params[:redirect][:action] : ''
        id = params[:redirect] ? params[:redirect][:id] : ''
        if controller == '' || action == ''
          unless @session[:user].authority == User::SUPER_USER
            dirs = Section.find(:first, :conditions => ['id = ?', @session[:user].section_id], :order => 'name').genres
            ids = dirs.collect{|i| i.id}
            root_dir = []
            dirs.each do |dir|
              root_dir << dir unless ids.index(dir.parent_id)
            end
            id = root_dir[0].id unless root_dir.empty?
          end
          redirect_to(:action => 'index')
        else
          redirect_to(:controller => controller, :action => action, :id => id)
        end
      else
        flash.now['notice']  = "ログインに失敗しました"
        @login = @params[:user_login]
      end
    end
  end

  def logout
    @session[:user] = nil
    redirect_to(:action => 'login')
  end
end
