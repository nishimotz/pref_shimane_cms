class ApplicationController < ActionController::Base
  include ApplicationHelper
  include SslRequirement

  model(:user)

  private

  def set_controller_name
    @controller_name = self.class.to_s.split(/Controller/).first.downcase
  end

  def authorize
    unless performed? || @session[:user]
      flash.now['notice'] = "ログインしてください"
      @login = @params[:user_login]
      redirect_to :controller => 'admin', :action => 'login',
        :id => params[:id], 'controller_name' => params[:controller],
        'action_name' => params[:action]
    end
  end

  def authorize_admin
    authorize
    unless performed? || admin?
      flash[:notice] = '操作を行う権限がありません'
      redirect_to(:controller => 'admin', :action => 'index')
    end
  end

  def authorize_section_manager
    authorize
    unless performed? || admin? || @user.authority == User::SECTION_MANAGER
      flash[:notice] = '操作を行う権限がありません'
      redirect_to(:controller => 'admin', :action => 'index')
    end
  end

  def prepare_user
    @user = @session[:user]
  end

  def rubi_filter
    return if @headers['Content-Type'] || !@cookies['ruby'] || @cookies['ruby'].first != 'on'
    @response.body = RubiAdder.add(@response.body)
  end

  def setup_divisions
    @divisions = Division.find(:all,
                               :order => 'number').collect{|i| [i.name, i.id]}
  end

  def setup_sections(division_id)
    @sections = Section.find(:all,
                             :conditions => ['division_id = ?', division_id],
                             :order => 'number').collect { |i| [i.name, i.id] }
  end
end
