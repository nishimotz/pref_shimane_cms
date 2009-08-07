class WordController < ApplicationController
  before_filter :authorize
  before_filter :prepare_user
  before_filter :set_title

  layout 'word'

  def index
    list
    render :action => 'list'
  end

  def list
    @word = Word.new
    prepare_pagination
  end

  def new
    @word = Word.new
  end

  def create
    @word = Word.new
    @word.base = params[:word][:base]
    @word.text = params[:word][:text]
    @word.user = @user
    if @word.save
      flash[:notice] = '追加されました。'
      redirect_to :action => 'list'
    else
      prepare_pagination
      render :action => 'list'
    end
  end

  def edit
    @word = Word.find(params[:id])
    @word.text = Filter.k2h(@word.text)
  end

  def update
    @word = Word.find(params[:id])
    unless @word.editable_by?(@user)
      flash[:notice] = '他の所属が登録している単語のため、編集できませんでした。'
      redirect_to :action => 'list'
      return
    end
    @word.base = params[:word][:base]
    @word.text = params[:word][:text]
    @word.user = @user
    if @word.save
      flash[:notice] = '更新されました。'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    Word.find(params[:id]).destroy
    flash[:notice] = '削除されました。'
    redirect_to :action => 'list'
  end

  private

  def set_title
    @page_title = '辞書編集'
  end

  def prepare_pagination
    @query = {}
    @query_text = params[:query_text]
    @query_base = params[:query_base]
    if @query_text
      @query[:query_text] = @query_text
      cond = Filter.h2k(@query_text).split.collect{|e|
        ['text LIKE ?', "#{e}%"]
      }
      conditions = [cond.collect{|i| i[0]}.join(' OR '), *cond.collect{|i| i[1]}]
      @search = true
    elsif @query_base
      @query[:query_base] = @query_base
      if params[:search]
        conditions = ['base LIKE ?', "%#{@query_base}%"]
        @query[:search] = 'search'
      else
        conditions = ['base LIKE ?', "#{@query_base}%"]
        @query[:prefix_search] = 'prefix_search'
      end
      @word = Word.new(:base => @query_base)
      @search = true
    else
      conditions = nil
      @search = false
    end
    @word_pages, @words = paginate(:words, :per_page => 10,
                                   :include => :user,
                                   :conditions => conditions,
                                   :order => "text")
  end
end
