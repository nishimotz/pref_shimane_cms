require 'rubi_adder'

class VisitorController < ApplicationController
  include MIMEHelper

  MOBILE_AGENT = %r[(DoCoMo|J-PHONE|Vodafone|MOT-|UP\.Browser|DDIPOCKET|ASTEL|PDXGW|Palmscape|Xiino|sharp pda browser|Windows CE|L-mode)]i

  before_filter(:mobile_check)
  after_filter(:rubi_filter, :only => [:view, :show_revision, :show])
  after_filter(:mobile_filter, :only => [:view])

  session :off, :only => [:view, :send_attach_file, :qrcode]

  def view
    path = request.path
    begin
      if path == '/' || path == '/index.html'
        page = Page.find(:first, :include => [:contents],
                         :conditions => ['genre_id = ? and name = ?',
                                         1, 'index'])
        set_advertisement
        if !page || !page.current
          if @mobile
            render(:action => 'mobile_top')
          else
            render(:action => 'top')
          end
          return
        else
          unless page.current
            if @mobile
              render(:action => 'mobile_top')
            else
              render(:action => 'top')
            end
            return
          end
        end
      elsif %r!\A/(news\.(\d+))\.html! =~ path
        @page = Page.new(:name => $1, :title => '過去の新着情報')
        @page_num = $2.to_i
        @genre = Genre.find_by_path('/')
        @page.genre = @genre
        @layout = :news_layout
        params[:page] = @page_num
        @news_pages, @news =
          paginate(:news,
                   :order => 'published_at desc',
                   :conditions => ['published_at <= ?', Time.now],
                   :per_page => News.news_per_page)
        if @mobile
          render(:action => 'mobile_page')
        else
          render(:action => @page.template)
        end
        return
      end
      @attach_file = nil
      path.gsub(%r|/+|, '/')
      if %r!(.+\.data)/([^/]+)\z! =~ path
        path = $1
        @attach_file = $2
      else 
        @attach_file = nil
      end
      if path =~ %r!(.*)/\z!
        dir = $1
        file = 'index'
      else
        dir = File.dirname(path)
        file = File.basename(path)
        if @attach_file
          file.sub!(%r!(.+)\.data\z!, '\1')
          if /\Aadvertisement\z/ =~ file
            send_advertisement_img_file(@attach_file)
            return
          end
        elsif /(.+)\.png\z/ =~ path
          qrcode("#{$1}.html")
          return
        else
          file.sub!(%r!(.+)\.html(?:\.i)?\z!, '\1')
        end
        raise unless file
      end
      if path.split(/\//).size == 2 && path.index(/html/) # section.html
        @genre = Genre.find(:first, :conditions => ['path = ?', '/'])
      elsif path.split(/\//).size == 0 # TOP page
        @genre = Genre.find(:first, :conditions => ['path = ?', '/'])
      else
        @genre = Genre.find_by_name(dir) || raise
      end
      @page = Page.find(:first,
                        :conditions => ['genre_id = ? and name = ?',
                                        @genre.id, file])
      if (file == 'index' && !@attach_file && (!@page || !@page.current))
        @page = Page.index_page(@genre)
        @layout = :genre_top_layout
#        genre_ids = Section.find(:all).collect{|i| i.top_genre_id}
#        @layout = :section_top_layout if @genre.path =~ /^\S+/ && genre_ids.index(@genre.id)
        @layout = :section_top_layout if Section.find(:first, :conditions => ['top_genre_id = ?', @genre.id])
        if @genre.uri.blank?
          case @layout
          when :genre_top_layout
#            @content = "<h1>#{@page.genre.title}</h1><%= plugin('genre_news_list') %><%= plugin('genre_down_list') %>"
            @content = 'genre_top_layout'
          when :section_top_layout
            @content = "<h1>#{@genre.section.name}ホームページ</h1><h2>新着ページ一覧</h2><%= plugin('section_news') %><h2>事業内容</h2><%= plugin('section_top_list') %>"
          end
        else
          @content = %Q!<h1>#{@page.genre.title}</h1><a href="<%= h(@genre.uri) %>"><%= h(@genre.uri) %></a>をご覧ください。!
        end
        if @mobile
          render(:action => 'mobile_page')
        else
          render(:action => @page.template)
        end
      else
        raise unless @page
        if @attach_file
          send_attach_file(@page, @attach_file)
        else
          raise '公開ページがありません' unless @page.current
          @layout = layout
          @layout = :section_top_layout if file == 'index' && Section.find(:first, :conditions => ['top_genre_id = ?', @genre.id])
          if @mobile
            @content = @page.current.mobile_content
            render(:action => 'mobile_page')
          else
            @content = @page.current.content
            render(:action => @page.template)
          end
        end
      end
    rescue
      logger.error(%Q!visitor error (#{$!}) : #{$@.join("\n")}!)
      render(:action => 'not_found', :status => 404, :layout => false)
    end
  end

  def send_attach_file(page, file)
    send_file("#{AdminController::FILE_PATH}/#{page.id}/#{file}",
              :type => content_type(file),
              :stream => false, :disposition => 'inline')
  end

  def send_advertisement_img_file(file)
    send_file("#{Advertisement::FILE_PATH}/#{file}",
              :type => content_type(file),
              :stream => false, :disposition => 'inline')
  end
  # for edit page preview
  def show
    @page = Page.find(params[:id])
    page_content = @page.private
    page_content.validate_content
    @content = page_content.content
    @genre = @page.genre
    @layout = layout
    set_advertisement if @layout == :top_layout
    @preview = true
    render(:action => @page.template)
  end

  def show_revision
    page_content = PageContent.find(params[:id])
    page_content.validate_content
    @page = page_content.page
    @content = page_content.content
    @genre = @page.genre
    @layout = layout
    set_advertisement if @layout == :top_layout
    @preview = true
    render(:action => @page.template)
  end

  private

  def qrcode(path)
    require 'qrcode_img'
    path.sub!(%r|/index\.html\z|, '/')
    if Page.find_by_path(path)
      uri = "http://#{MY_DOMAIN}#{path}"
      qr = Qrcode_image.new
      qr.set_module_size(2)
      send_data(qr.mkimage(qr.make_qrcode(uri)).pngStr,
                :filename => 'qrcode.png',
                :type => 'image/png',
                :disposition => 'inline')
    else
      raise
    end
  end

  def layout
    case @page.name
    when 'index'
      if @genre.path == '/'
        :top_layout
      elsif Section.find(:first, :conditions => ['top_genre_id = ?', @page.genre_id])
        :section_top_layout
      elsif !@genre.section_except_admin
        :genre_top_layout
      else
        :normal_layout
      end
    else
      :normal_layout
    end
  end

  def set_advertisement
    @pref_ads = Advertisement.pref_published_advertisement
    @corp_ads = Advertisement.corp_published_advertisement
  end

  def mobile_check
    @mobile = mobile?
  end

  def mobile?
    @request.env['HTTP_USER_AGENT'] =~ MOBILE_AGENT || %r!\.html\.i(?:#[^/]*)?(?:\?[^/]*)?\z! =~ @request.path
  end

  def rubi_filter
    super unless @attach_file
  end

  def mobile_filter
    @response.body = Filter.convert(@response.body, 'utf-8', 'cp932') if @mobile
  end
end
