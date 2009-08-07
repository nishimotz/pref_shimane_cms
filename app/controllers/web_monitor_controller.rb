class WebMonitorController < ApplicationController
  layout 'admin'
  before_filter(:authorize)
  before_filter(:prepare_user)
  before_filter(:check_csv, :only => [:create_from_csv])

  def index
    @genre = Genre.find(params[:id])
    @edited = @genre.has_edited_monitors?
    @web_monitor_pages, @web_monitors = paginate(:web_monitors,
                                         :per_page => 15,
                                         :conditions => ['genre_id = ?', @genre.id],
                                         :order => 'login')
  end

  def new_user
    @genre = Genre.find(params[:id])
    @web_monitor = WebMonitor.new(:genre_id => @genre.id)
  end

  def save_user
    if params[:id]
      update_user
    else
      create_user
    end
  end

  def create_user
    @web_monitor = WebMonitor.new(params[:web_monitor])
    if @web_monitor.save
      flash[:monitor_notice] = 'モニタを登録しました。'
      redirect_to :action => 'index', :id => @web_monitor.genre_id
    else
      @genre = Genre.find(@web_monitor.genre_id)
      render :action => 'new_user'
    end
  rescue => e
    logger.error("#{e.message}\n#{e.backtrace}")
    flash[:monitor_error] =  'モニタの登録に失敗しました。'
    @genre = Genre.find(@web_monitor.genre_id)
    render :action => 'new_user'
  end

  def edit_user
    @genre = Genre.find(params[:genre_id])
    @web_monitor = WebMonitor.find(params[:id])
    @web_monitor.password = nil
    flash[:edit_notice] = 'ユーザIDを変更する場合はパスワードの変更も行なってください。'
    render :action => 'new_user'
  end

  def update_user
    @web_monitor = WebMonitor.find(params[:id])
    if @web_monitor.update_attributes(params[:web_monitor])
      flash[:monitor_notice] = 'モニタを更新しました。'
      redirect_to :action => 'index', :id => @web_monitor.genre_id
    else
      render :action => 'new_user'
    end
  rescue => e
    logger.error("#{error.message}\n#{error.backtrace}")
    flash[:monitor_error] =  'モニタの更新に失敗しました。'
    render :action => 'new_user'
  end

  def destroy_user
    monitor = WebMonitor.find(params[:id])
    monitor.destroy
    flash[:monitor_notice] = 'モニタを削除しました。'
    redirect_to :action => 'index', :id => params[:genre_id]
  rescue => e
    error_for_destroy(e, 'モニタの削除に失敗しました。')
  end

  def destroy_all_user
    genre = Genre.find(params[:id])
    WebMonitor.delete_all("genre_id = #{genre.id}")
    Job.create(:action => 'destroy_htpasswd', :arg1 => genre.id)
    flash[:monitor_notice] = 'モニタを全て削除しました。'
    redirect_to :action => 'index', :id => params[:id]
  rescue => e
    error_for_destroy(e, 'モニタの削除に失敗しました。')
  end

  def create_from_csv
    genre_id = params[:id]
    WebMonitor.create_from_csv(NKF.nkf('-w -m0', params[:csv].read), genre_id)
    redirect_to :action => 'index', :id => genre_id
  rescue ActiveRecord::RecordInvalid => e
    @csv_invalid_record = e.record
    flash[:csv_error] = "モニタ名「#{@csv_invalid_record.name}」の情報が不正です。"
    new_user
    render :action => 'new_user'
  rescue => e
    error_for(:csv_error, e, '一括登録に失敗しました。')
  end

  def change_genre_auth
    genre = Genre.find(params[:id])
    org_auth = genre.auth
    new_auth = params[:auth]
    genre.update_attribute(:auth, new_auth)
    genre.create_auth_job unless auth_unchanged_from_false(org_auth, new_auth)
    flash[:monitor_notice] = "フォルダのアクセス制限を「#{ genre.auth ? '有効' : '無効' }」に変更しました。"
    redirect_to :action => 'index', :id => genre.id
  rescue => e
    error_for(:genre_auth_error, e, 'アクセス制限の設定に失敗しました。')
  end 

  def update_monitor_info
    genre = Genre.find(params[:id])
    WebMonitor.transaction do
      Job.transaction do
        Job.create(:action => 'create_htpasswd', :arg1 => genre.id)
        genre.web_monitors.update_all("state = #{WebMonitor::REGISTERED}")
      end
    end
    flash[:monitor_notice] = "モニタの情報をアクセス制限に反映させました。"
    redirect_to :action => 'index', :id => genre.id
  rescue => e
    error_for(:update_user_info_error, e, 'アクセス制限の更新処理に失敗しました。')
  end 

  private
  def check_csv
    uploaded_file = params[:csv]
    f_name = uploaded_file.original_filename
    if f_name.blank?
      flash[:csv_error] = "ファイルを選択してください。"
      new_user
      render :action => 'new_user'
      return false
    end

    #FIXME: IE send CSV as application/octet-stream so, hence commented
    #out the MIME type check code below.
    # unless uploaded_file.content_type.chomp == 'text/csv'
    unless f_name =~ /\.csv\z/i
      flash[:csv_error] = "#{uploaded_file.original_filename}はCSVファイルではありません。"
      new_user
      render :action => 'new_user'
      return false
    end
  end

  def error_for(label, error, message)
    logger.error("#{error.message}\n#{error.backtrace}")
    flash[label] = message
    new_user
    render :action => 'new_user'
  end

  def error_for_destroy(error, message)
    logger.error("#{error.message}\n#{error.backtrace}")
    flash[:monitor_error] =  'モニタの削除に失敗しました。'
    redirect_to :action => 'index', :id => params[:genre_id]
  end

  def auth_unchanged_from_false(org_auth, new_auth)
    not org_auth || new_auth
  end
end
