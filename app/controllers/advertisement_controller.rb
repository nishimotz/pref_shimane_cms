class AdvertisementController < ApplicationController
  before_filter :prepare_user
  before_filter :authorize_admin
  before_filter :job_filter, :except => [:show,:new,:create]
  before_filter :check_advertisement_list_existence, 
                :only => [:change_state, :update_sort_pref_advertisement, 
                          :update_sort_corp_advertisement, :sort,
                          :update_advertisement]
  before_filter :check_advertisement_existence, 
                :only => [:edit,:show,:change_image,:delete,:update]
  before_filter :authorize_delete, :only => [:delete]
  before_filter :initialize_list, :only => [:set_state]
  before_filter :check_expired_advertisements, :only => [:list]

 EXT_RE = /\A\.(jpe?g|png|gif)\z/i

  def index
    list
    render :action => 'list'
  end

  def new
    @action = :create
    @advertisement = Advertisement.new
    render :action => 'edit'
  end

  def list
    @pref_ads = Advertisement.pref_advertisement
    @corp_ads = Advertisement.corp_advertisement
  end

  def create
    @action = :create
    @advertisement = Advertisement.new
    image_file = params[:advertisement].delete("image_file")
    if uploaded_file_check(image_file)
      if @advertisement.update_attributes(params[:advertisement])
        save_file(@advertisement,image_file)
        flash[:advertisement_notice] = '広告を作成しました'
        redirect_to :action => 'list'
      else 
        render :action => 'edit'
      end
    else
      @advertisement.attributes = params[:advertisement]
      render :action => 'edit'
    end
  rescue => e
    logger.error("Error while creating advertisment: #{e.message}")
    render :action => 'edit'
  end

  def edit
    @action = :update
    @image_deleted = false
    @advertisement = Advertisement.find_by_id(params[:id])
  end

  def change_image
    @action  = :update
    @advertisement = Advertisement.find_by_id(params[:id])
    delete_image(@advertisement)
    render(:action => 'edit')
  end

  def update 
    @action  = :update 
    @advertisement = Advertisement.find_by_id(params[:id])
    positions = {:pref_ad_number => @advertisement.pref_ad_number, 
                 :corp_ad_number => @advertisement.corp_ad_number}
    attributes = params[:advertisement].merge(positions)
    image_file = attributes.delete("image_file")
    #
    # 画像の変更がない場合は既存のimage属性をmergeするだけでファイルの
    # 保存は行なわない。
    # 
    if !params[:advertisement]['image_file']
      attributes.merge!({:image => @advertisement.image})
      if @advertisement.update_attributes(attributes)
        flash[:advertisement_notice] = '広告を編集しました'
        redirect_to(:action => 'list')
      else
        render :action => 'edit'
      end
    #
    # 画像の変更がある場合はファイルのcheckを行い、画像ファイルを保存する。
    #
    elsif uploaded_file_check(image_file)
      if @advertisement.update_attributes(attributes)
        save_file(@advertisement,image_file)
        flash[:advertisement_notice] = '広告を編集しました'
        redirect_to(:action => 'list')
      else
        render :action => 'edit'
      end
    else
      @advertisement.attributes = attributes
      render :action => 'edit'
    end
  rescue => e
    logger.error("Error while updating advertisment: #{e.message}")
    render :action => 'edit'
  end

  def delete
    advertisement = Advertisement.find(params[:id])
    name = advertisement.name
    delete_image(advertisement)
    advertisement.destroy
    flash[:advertisement_notice] = "広告(#{name})を削除しました"
    redirect_to(:action => 'list')
  rescue => e
    logger.error("Error while deleting advertisment: #{e.message}")
    redirect_to(:action => 'list')
  end

  def show
    @advertisement = Advertisement.find_by_id(params[:id])
  end

  def preview
  end

  def update_advertisement
    if params[:preview]
      @preview = true
      @pref_ads = []
      @corp_ads = []
      pref_published_ads = AdvertisementList.pref_published_advertisements
      corp_published_ads = AdvertisementList.corp_published_advertisements
      pref_published_ads.each do |ad|
        @pref_ads << Advertisement.new(ad.advertisement.attributes.
                           merge({:state => ad.state,
                             :pref_ad_number => ad.pref_ad_number,
                             :corp_ad_number => ad.corp_ad_number}))
      end
      corp_published_ads.each do |ad|
        @corp_ads << Advertisement.new(ad.advertisement.attributes.
                           merge({:state => ad.state,
                             :pref_ad_number => ad.pref_ad_number,
                             :corp_ad_number => ad.corp_ad_number}))
      end
      render(:action => '../visitor/preview_banners')
      return
    elsif params[:save]
      Job.create(:action => 'move_banner_images',:datetime => Time.now)
      flash[:advertisement_notice] = '現在、バナー広告の設定変更を反映中です。変更が反映されるまでバナー広告の設定はできません。'
      redirect_to(:action => 'list')
    elsif params[:cancel]
      flash[:advertisement_notice] = "設定変更を破棄しました。"
      redirect_to(:action => 'list')
      AdvertisementList.destroy_all
    end
  rescue => e
    logger.error("Error while updating advertisement state:" + e.message)
    redirect_to(:action => 'sort')
  end

  def set_state
    initialize_list
    @corp_ads = Advertisement.corp_advertisement
    @pref_ads = Advertisement.pref_advertisement
  end

  def change_state
    if params[:cancel]
      flash[:advertisement_notice] = "設定変更を破棄しました。"
      redirect_to(:action => 'list')
      AdvertisementList.destroy_all
    else
      AdvertisementList.transaction do
        params[:advertisement].each do |id,state|
          advertisement =  AdvertisementList.find_by_advertisement_id(id)
          advertisement.state = state
          advertisement.save!
        end
      end
      redirect_to :action => 'sort'
    end
  rescue => e
    logger.error("Error while changing advertisement state:" + e.message)
    redirect_to :action => 'set_state'
  end

  def sort
    AdvertisementList.transaction do
      @pref_ads = AdvertisementList.pref_published_advertisements.each_with_index do |ad, i|
        ad.pref_ad_number = i
        ad.save!
      end
      @corp_ads = AdvertisementList.corp_published_advertisements.each_with_index do |ad, i|
        ad.corp_ad_number = i
        ad.save!
      end
    end
  end

  def update_sort_corp_advertisement
    @corp_ads = []
    AdvertisementList.transaction do
      params["corp_ads"].each_with_index do |id, position|
        @corp_ads << AdvertisementList.update(id, :corp_ad_number => position)
      end
    end
    @pref_ads = AdvertisementList.pref_published_advertisements
    render(:action => 'sort')
  rescue => e
    logger.error("Error while sorting corp ads." + e.message)
    sort
    render :action => 'sort'
  end

  def update_sort_pref_advertisement
    @pref_ads = []
    AdvertisementList.transaction do
      params["pref_ads"].each_with_index do |id, position|
        @pref_ads << AdvertisementList.update(id, :pref_ad_number => position)
      end
    end
    @corp_ads = AdvertisementList.corp_published_advertisements
    render(:action => 'sort')
  rescue => e
    logger.error("Error while sorting corp ads:" + e.message)
    sort
    render :action => 'sort'
  end

  private
  #
  # アップロードされたファイルの妥当性のチェックを行なう。
  # ファイルが妥当な場合はtrueを返し、妥当でない場合はfalseを返す
  #
  def uploaded_file_check(file)
    if file && file != ""
      if EXT_RE !~ File.extname(file.original_filename)
        @advertisement.errors.add(:image_file, '画像ファイル(jpg、png、gif)を選択してください')
        return false
      elsif file.size > 1024 * 50
        @advertisement.errors.add(:image_file, 'アップロードする画像ファイルのサイズが50KByteの上限を越えています')
        return false
      end
    else
      @advertisement.errors.add(:image_file, 'ファイルを選択してください')
      return false
    end
    return true
  end

  #
  # fileを保存する。既存のファイルがある場合は削除してから保存し、
  # advertisementのimage属性を設定する。
  # file名は、"id" + "ファイルの拡張子"になる。
  #
  def save_file(advertisement, file)
    extname = File.extname(file.original_filename)
    filename = "#{advertisement.id}" + extname
    check_dir
    path =  "#{Advertisement::FILE_PATH}/#{advertisement.image}" 
    if advertisement.image && File.exist?( "#{Advertisement::FILE_PATH}/#{advertisement.image}")
      File.delete( "#{Advertisement::FILE_PATH}/#{advertisement.image}")
    end
    File.open("#{Advertisement::FILE_PATH}/#{filename}",'wb') do |f|
      f.write(file.read)
    end
    advertisement.image = filename
    advertisement.save!
  end

  def check_dir
    File.exist?("#{Advertisement::FILE_PATH}") || make_image_dir
  end

  def make_image_dir
    begin
      FileUtils.mkdir_p(Advertisement::FILE_PATH)
    rescue
    end
  end
  
  def delete_image(advertisement)
    advertisement.delete_img
    advertisement.update_attributes(:image => nil)
  rescue => e
    logger.error("Error while deleteing image: #{e.message}")
  end

  def initialize_list
    AdvertisementList.transaction do 
      AdvertisementList.delete_all
      Advertisement.find(:all).each do |ad|
        advertisement_list = AdvertisementList.new
        advertisement_list.advertisement = ad
        advertisement_list.pref_ad_number = ad.pref_ad_number
        advertisement_list.corp_ad_number = ad.corp_ad_number
        advertisement_list.state = ad.state
        advertisement_list.save
      end
    end
  rescue => e
    redirect_to :action => "list" 
  end

  def job_filter
    if job_exist?
      flash[:advertisement_notice] = '現在、バナー広告の設定変更を反映中です。変更が反映されるまでバナー広告の設定はできません。'
      unless params[:action] == 'list'
        redirect_to :action => 'list' 
        return false
      end
    end
  end

  def job_exist?
    Job.find_by_action('move_banner_images')
  end

  def check_advertisement_existence
    advertisement = Advertisement.find_by_id(params[:id])
    unless advertisement
      flash[:advertisement_notice] = 'ページが存在しません'
      redirect_to :action => "list" 
      return false
    end
  end

  def authorize_delete
    advertisement = Advertisement.find_by_id(params[:id])
    if advertisement.published?
      flash[:advertisement_notice] = '公開中のページは削除できません'
      redirect_to :action => "list" 
      return false
    end
  end

  #
  # "_advertisement/sort"などと直接指定した場合にエラーにならない
  # ようにする
  #
  def check_advertisement_list_existence 
    if AdvertisementList.count == 0
      flash[:advertisement_notice] = '公開作業を最初からやり直してください'
      redirect_to :action => "list" 
      return false
    end
  end

  def check_expired_advertisements
    if Advertisement.expired_advertisement.size != 0
      flash[:expired_advertisement_exist] = '公開期限切れの広告があります。'
    end
  end
end
