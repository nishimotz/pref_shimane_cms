class HelpController < ApplicationController
  FILE_PATH = "#{RAILS_ROOT}/help_files/#{RAILS_ENV}"
  before_filter(:authorize, :except => [:index, :help_close, :help_open, :change_right_pain, :preview, :search, :list])
  before_filter(:prepare_user)
  before_filter(:authorize_admin, :except => [:index, :help_close, :help_open, :change_right_pain, :preview, :search, :list])

  # public
  def index
    @mode = :help
    if params[:category_id] && !params[:category_id].blank?
      @category = HelpCategory.find(params[:category_id])
      if @category.parent
        @root_help_list = [@category.parent]
        session[:help_category_id] = @category.parent.id
      else
        @root_help_list = [@category]
        session[:help_category_id] = @category.id
      end
      category_ids = [@category].collect{|i| i.id}
      unless category_ids.empty?
        @helps = Help.find(:all,
                           :conditions => ['help_category_id in (?)', category_ids],
                           :order => 'number')
        @help = @helps.first
      end
      @help = Help.find(params[:id]) if params[:id]
      @help_content = @help.help_content if @help
      @categories = @category.children
    elsif params[:id]
      @helps = Help.find(:all, :order => 'id desc')
      @help = Help.find(params[:id])
      @help_content = @help.help_content
      @categories = HelpCategory.find(:all, :conditions => ['parent_id is null'])
      if session && !session[:help_category_id].blank?
        @root = HelpCategory.find(session[:help_category_id])
        @root_help_list = [@root]
      else
        @categories = HelpCategory.find(:all, :conditions => ['parent_id is null'],
                                        :order => 'number')
        @root = @categories.first unless @categories.empty?
        @root_help_list = @categories
      end
    else
      @categories = HelpCategory.find(:all, :conditions => ['parent_id is null'],
                                      :order => 'number')
      @root = @categories.first unless @categories.empty?
      @root_help_list = @categories
      @help = @root.helps.first
      @help_content = @help.help_content
      @categories = HelpCategory.find(:all, :conditions => ['parent_id is null'])
      session[:help_category_id] = nil
    end
    session[:help] = nil
  end

  def help_close
    @root = HelpCategory.find(params[:id])
    @mode = :category
    @action_name = 'list'
    if params[:action_name] == 'index'
      @mode = :help
      @action_name = 'index'
    end
    if params[:help_id]
      @help = Help.find(params[:help_id])
    else
      @help = nil
    end
    render(:partial => 'help_close')
  end

  def help_open
    @root = HelpCategory.find(params[:id])
    @mode = :category
    @action_name = 'list'
    if params[:action_name] == 'index'
      @mode = :help
      @action_name = 'index'
      if params[:help_id]
        @help = Help.find(params[:help_id])
      else
        @help = nil
      end
    end
    render(:partial => 'help_open')
  end

  def change_right_pain
    str = session[:help] if session[:help]
    index
    session[:help] = str
    render(:partial => 'main_content')
  end

  def preview
    if params[:id]
      @help = Help.find(params[:id])
      @help_content = @help.help_content
    end
  end

  def search
    if session[:help] && !session[:help].blank?
      param_keyword = session[:help]
      param_keyword = params[:search][:keyword].split(/ |　/).select{|i| !i.blank?} if params[:search]
    else
      param_keyword = params[:search][:keyword].split(/ |　/).select{|i| !i.blank?}
    end
    session[:help] = param_keyword

    query = 'public = ?'
    str = []
    param_keyword.each do |i|
      str << "(help_contents.content like '%#{i}%' or helps.name like '%#{i}%')"
    end
    query += ' and ' + str.join(' and ') if !str.empty?

    @helps = Help.find(:all,
                       :include => 'help_content',
                       :conditions => [query,1])
    if session[:help] && !session[:help].blank? && params[:id]
      @help = Help.find(params[:id])
      @help_content = @help.help_content
    else
      @help = @helps.first
      @help_content = @help.help_content if @help
    end
    render(:action => 'index')
  end

  def list
    @mode = :category
    @categories = HelpCategory.find(:all, :conditions => ['parent_id is null'],
                                    :order => 'number')
    @root = @categories.first unless @categories.empty?
    @root_help_list = @categories
    @action_name = 'list'
    session[:help] = nil
  end

  # admin
  def admin_index
    @categories = HelpCategory.find(:all).collect {|c| [ c.name, c.id ] }
    @help_content_pages, @help_contents = paginate(:help_contents,
                                                   :order => "id",
                                                   :per_page => Help::PER_PAGE)
    b_categories = HelpCategory.find(:all,
                                     :conditions => ['parent_id is null'])
    @big_categories = b_categories.collect{|i| [i.name, i.id.to_s]}

    if session[:help_category_search] && !session[:help_category_search].blank?
      search_category
      @big_category = HelpCategory.find(session[:help_category_search].to_i).id.to_s
    end
  end

  def search_category
    if params[:big_category] && !params[:big_category].blank?
      session[:help_category_search] = params[:big_category]
    end

    @categories = HelpCategory.find(:all).collect {|c| [ c.name, c.id ] }
    b_categories = HelpCategory.find(:all,
                                     :conditions => ['parent_id is null'])
    @big_categories = b_categories.collect{|i| [i.name, i.id.to_s]}
    category = HelpCategory.find(session[:help_category_search].to_i)
    ids = category.all_categories.collect{|i| i.id}
    contents = HelpContent.find(:all,
                                :include => 'helps',
                                :conditions => ['helps.help_category_id in (?)',
                                                ids],
                                :order => 'number')
    @help_contents = contents
    @big_category = category.id.to_s
    render(:action => 'admin_index')
  end

  def destroy_help_content
    if params[:id]
      content = HelpContent.find(params[:id])
      content.destroy
    end
    redirect_to(:action => 'admin_index')
  end

  def new_help_content
    help_content = HelpContent.new
    help_content.save
    help = Help.new(:name => params[:help][:name],
                    :help_category_id => params[:category][:category_id],
                    :help_content_id => help_content.id,
                    :public => false)
    help.save
    redirect_to(:action => 'edit', :id => help_content.id, :help_id => help.id)
  end

  def edit
    @edit_mode = true
    if params[:id]
      @content = HelpContent.find(params[:id])
    else
      @content = HelpContent.new
    end
    @help = Help.new
  end

  def update_help_content
    if params.has_key?("preview")
      @help_content = HelpContent.find(params[:id])
      @help = @help_content.helps.first
      @help_content.content = params[:content][:content]
      render(:action => 'preview')
    elsif params.has_key?("cancel")
      if params[:status] == 'update'
        redirect_to(:action => 'admin_index')
      else
        help = HelpContent.find(params[:id])
        help.destroy
        redirect_to(:action => 'admin_index')
      end
    else
      help_content = HelpContent.find(params[:id])
      help_content.content = params[:content][:content]
      help_content.save
      redirect_to(:action => 'admin_index')
    end
  end

  def list_file
    @list = []
    @help_content = HelpContent.find(params[:id])
    Dir.glob("#{FILE_PATH}/#{@help_content.id}/*") do |f|
      @list << f
    end
  end

  def upload_file
    help_content = HelpContent.find(params[:id])
    dir = attach_dir(help_content)
    params[:file][:content].binmode
    file_name = ERB::Util.url_encode(File.basename(params[:file][:content].original_filename))
    tmp_file = Tempfile.new('cms_upload')
    tmp_file.write(params[:file][:content].read)
    tmp_file.close
    FileUtils.chmod(0666, tmp_file.path)
    FileUtils.mv(tmp_file.path, "#{dir}/#{file_name}")
    redirect_to(:action => 'list_file', :id => params[:id])
  end

  def new_category
    category = HelpCategory.new(:name => params[:category][:name])
    category.parent_id = params[:category][:id] if params[:category].has_key?(:id)
    category.save
    redirect_to(:action => 'list_category')
  end

  def update_category
    category = HelpCategory.find(params[:id])
    category.name = params[:category][:name]
    category.save
    redirect_to(:action => 'list_category')
  end

  def sort_helps
    @category = HelpCategory.find(params[:id])
    @helps = Help.find(:all,
                       :conditions => ['help_category_id = ?', params[:id]],
                       :order => 'number')
  end

  def update_sort_helps
    @helps = []
    Help.transaction do
      params[:list].each_with_index do |help_id, i|
        @helps << Help.update(help_id.to_i, :number => i)
      end
    end
    render(:partial => 'sort_helps')
  end

  def list_category
    @categories = HelpCategory.find(:all, :conditions => ['parent_id is null'],
                                    :order => 'number')
    @select_categories = @categories.collect{|i| [i.name, i.id] }
  end

  def destroy_category
    category = HelpCategory.find(params[:id])
    category.destroy
    redirect_to(:action => 'list_category')
  end

  def select_category
    @mode = :edit
    list_category
    @category = HelpCategory.find(params[:id])
    @select_categories = @category.children.collect{|i| [i.name, i.id]}
    if params[:update]
      @mode = 'edit'
    end
    render(:action => 'list_category')
  end

  def sort_category
    if params[:id]
      @category = HelpCategory.find(params[:id])
      @categories = @category.children
    else
      @categories = HelpCategory.find(:all, :conditions => ['parent_id is null'])
    end
  end

  def update_sort_categories
    @categories = []
    HelpCategory.transaction do
      params[:list].each_with_index do |category_id, i|
        @categories << HelpCategory.update(category_id.to_i, :number => i)
      end
    end
    render(:partial => 'sort_categories')
  end

  def edit_properties
    # initialize
    @help = Help.find(params[:id])
    @helps = @help.help_content.helps
    # categories menu
    b_categories = HelpCategory.find(:all,
                                     :conditions => ['parent_id is null'])
    @big_categories = b_categories.collect{|i| [i.name, i.id]}
    m_categories = []
    @middle_categories = []
    @middle_categories << ['指定無し', 0]
    @small_categories = []
    @small_categories << ['指定無し', 0]
    b_categories.each do |category|
      m_categories << category.children
      category.children.each do |m_category|
        @middle_categories << [m_category.name, m_category.id]
      end
    end
    m_categories.flatten.each do |category|
      category.children.each do |s_category|
        @small_categories << [s_category.name, s_category.id]
      end
    end
  end

  def update_properties
    help_orig = Help.find(params[:id])
    if params.has_key?('help_id') && !params['help_id'].blank?
      help = Help.find(params[:help_id])
    else
      help = Help.new
    end
    help.name = params[:help][:name]
    help.help_category_id = params[:small_category].to_i
    if params[:middle_category].to_i.zero?
      help.help_category_id = params[:big_category].to_i
    elsif params[:small_category].to_i.zero?
      help.help_category_id = params[:middle_category].to_i
    end
    help.help_content_id = help_orig.help_content_id
    help.public = 0
    help.save
    edit_properties
    redirect_to(:action => 'edit_properties', :id => help_orig.id)
  end

  def set_properties
    edit_properties
    @mode = :edit
    @help = Help.find(params[:help_id])
    if @help.category
      case @help.category.get_category_name
      when 'big_category'
        @big_category = @help.help_category_id
      when 'middle_category'
        @big_category = @help.category.parent.id
        @middle_category = @help.help_category_id
      when 'small_category'
        @big_category = @help.category.parent.parent.id
        @middle_category = @help.category.parent.id
        @small_category = @help.help_category_id
      end
    end
    render(:action => 'edit_properties')
  end

  def destroy_properties
    if Help.exists?(params[:id])
      help = Help.find(params[:id])
      help.destroy
    end
    redirect_to(:action => 'edit_properties', :id => params[:help_id])
  end

  def publish
    help = Help.find(params[:id])
    if help.public.zero?
      help.public = 1
    else
      help.public = 0
    end
    help.save
    redirect_to(:action => 'edit_properties', :id => params[:id])
  end

  def set_navigation
    category = HelpCategory.find(params[:id])
    if category.navigation
      category.navigation = false
    else
      category.navigation = true
    end
    category.save
    redirect_to(:action => 'list_category')
  end

  def list_action
    @help_action = HelpAction.new
    @help_actions = HelpAction.find(:all)
    @masters = ActionMaster.find(:all).collect{|i| [i.name, i.id]}
    set_category_menu
  end

  def create_action
    action = HelpAction.new(params[:help_action])
    action.save
    redirect_to(:action => 'list_action')
  end

  def destroy_action
    action = HelpAction.find(params[:id])
    action.destroy
    redirect_to(:action => 'list_action')
  end

  def edit_action_category
    help_category_id = params[:small_category].to_i
    if params[:middle_category].to_i.zero?
      help_category_id = params[:big_category].to_i
    elsif params[:small_category].to_i.zero?
      help_category_id = params[:middle_category].to_i
    end
    action = HelpAction.find(params[:id])
    action.help_category_id = help_category_id
    action.save
    redirect_to(:action => 'list_action')
  end

  # for TinyMCE
  def category_help_list
    @name = 'tinyMCELinkList'
    categories = HelpCategory.find(:all, :order => 'id')
    helps = Help.find(:all, :conditions => ['help_category_id = ?', params[:id]],
                      :order => 'number')
    @links = categories.collect {|category|
      if category.helps.empty?
        nil
      else
        [category.name, "/_help/index/?category_id=#{category.id}", category.helps.collect{|help| [help.name, "/_help/index/#{help.id}"]}]
      end
    }.compact
    render(:partial => 'category_help_list')
  end

  def image_list
    help = HelpContent.find(params[:id])
    files = Dir.glob("#{FILE_PATH}/#{help.id}/*").sort
    @name = 'tinyMCEImageList'
    @links = files.grep(/\.(gif|png|jpe?g)\z/i).collect{|i|
      file_name = File.basename(i)
      [file_name, "/help_images/#{help.id}/#{file_name}"]
    }
    render(:partial => 'link_list')
  end

  def file_list
    content = HelpContent.find(params[:id])
    files = Dir.glob("#{FILE_PATH}/#{content.id}/*").sort
    @name = 'tinyMCEFileList'
    @links = files.collect{|i|
      file_name = File.basename(i)
      [file_name, "/help_images/#{content.id}/#{file_name}"]
    }
    render(:partial => 'link_list')
  end

  def destroy_file
    help = HelpContent.find(params[:id])
    File.delete("#{FILE_PATH}/#{help.id}/#{params[:filename]}")
    redirect_to(:action => 'list_file', :id => help.id)
  end

  def clear_session
    session[:help_category_search] = nil
    redirect_to(:action => "admin_index")
  end

  private

  def attach_dir(help_content)
    dir = "#{FILE_PATH}/#{help_content.id}"
    unless File.exist?(dir)
      Dir.mkdir(dir)
    end
    dir
  end

  def set_category_menu
    # categories menu
    b_categories = HelpCategory.find(:all,
                                     :conditions => ['parent_id is null'])
    @big_categories = []
    @big_categories << ['指定無し', 0]
    b_categories.each do |i|
      @big_categories << [i.name, i.id]
    end
    m_categories = []
    @middle_categories = []
    @middle_categories << ['指定無し', 0]
    @small_categories = []
    @small_categories << ['指定無し', 0]
    b_categories.each do |category|
      m_categories << category.children
      category.children.each do |m_category|
        @middle_categories << [m_category.name, m_category.id]
      end
    end
    m_categories.flatten.each do |category|
      category.children.each do |s_category|
        @small_categories << [s_category.name, s_category.id]
      end
    end
  end
end
