class SiteController < ApplicationController
  layout 'advertisement'

  before_filter :prepare_user
  before_filter :authorize_admin
  before_filter :validate_date, :only => [:change_theme]

  def config
    @themes = Theme.find(:all)
    @current_theme = Theme.current_theme
    @top_photo_link = SiteComponents[:top_photo_link]
    check_theme_change_job
  end

  def change_theme
    name = params[:theme]
    create_job(name, @params_time)
    theme = Theme.new(name)
    flash[:notice_theme] = "テーマを(#{theme.description})に更新しました。"
    redirect_to :action => 'config'
  rescue
    flash[:error] = 'テーマの更新に失敗しました。'
    render_config
  end

  def change_top_photo_link
    url = params[:top_photo_link]
    SiteComponents[:top_photo_link] = url
    flash[:notice_top_photo_link] = "トップページの写真のリンク先URLを(#{url})に更新しました。リンクの変更を反映するためには、トップページの内容を編集し公開処理を行ってください。"
    redirect_to :action => 'config'
  rescue
    flash[:error] = 'トップページの写真のリンク先URLを更新に失敗しました。'
    render_config
  end

  private
  def render_config
    logger.error("#{action_name} #{$!.inspect}")
    config
    render :action => 'config'
  end

  def validate_date
    year, month, day, hour, minute = [:year,:month,:day,:hour,:minute].map{|d| params[:date][d]}
    @params_time = Time.local(year,month,day,hour,minute)
    if @params_time < Time.now
      flash[:error] = '更新日時が過去の日時です。'
      render_config
      return false
    end
  end

  def create_job(arg1,time)
    destroy_old_change
    Job.create(:action => action_name,
               :arg1 => arg1,
               :datetime => time)
  end

  def destroy_old_change
    old_jobs = Job.find_all_by_action('change_theme')
    old_jobs.each do |job|
      job.destroy
    end
  end

  def check_theme_change_job
    job = Job.find_by_action('change_theme')
    if job
      theme = Theme.find(job.arg1)
      time = job.datetime
      flash[:notice_theme] ||= "テーマの変更予定があります。(変更日時: #{time.strftime('%Y年%_m月%_d日 %k時%M分')}, テーマ: #{theme.description})"
    end
  end

end
