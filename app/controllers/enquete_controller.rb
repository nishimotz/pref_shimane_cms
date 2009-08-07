class EnqueteController < ApplicationController
  before_filter :authorize
  before_filter :prepare_user
#  before_filter :authorize_admin
  before_filter(:set_controller_name)

  layout 'board', :except => [:csv, :xls, :xml]

  def index
    list
    render :action => 'list'
  end

  def list
    EnqueteAnswer.retrieve_form_data
    page_list = EnqueteItem.find(:all, :group => 'page_id',
                                 :select => 'page_id')
    section_page_list = []
    page_list.each do |ei|
      if Page.exists?(ei.page_id)
        page = Page.find(ei.page_id)

        if page.section.id == @session[:user].section_id
          section_page_list << ei
        end
      end
    end
    if section_page_list.empty?
      @enquete_pages, @enquetes = nil, []
    else
      @enquete_pages, @enquetes = paginate(:pages, :per_page => 10,
                                           :include => 'enquete_answers',
                                           :conditions => ['pages.id in (?)',
                                             section_page_list.collect{|i| i.page_id}])
    end
  end

  def show
    prepare_output
  end

  def csv
    prepare_output
    csv = render_to_string(:action => 'csv')
    send_data(Filter.convert(csv, 'utf-8', 'shift_jis'),
              :filename => 'enquete.csv',
              :type => 'text/csv; charset=Shift_JIS')
  end

  def summary
    prepare_output
  end

  def answer_values
    @page = Page.find(params[:id])
    @item = EnqueteItem.find(params[:enquete_item])
    @answer_values = @item.answer_values
  end

  def other_values
    @page = Page.find(params[:id])
    value = EnqueteItemValue.find(params[:other_value])
    @other_values = value.enquete_item.other_answer_values
  end

  def xls
    prepare_output
    require 'spreadsheet/excel'
    workbook = Spreadsheet::Excel.new('/var/tmp/enquete.xls')
    worksheet = workbook.add_worksheet
    worksheet.write(0, 0,
                    (@enquete_items.collect{|i| i.name} + ['投稿日時']).collect{|i| Filter.convert(i, 'utf-8', 'shift_jis')})
    @enquete_answers.each_with_index do |answer, index| worksheet.write(index + 1, 0, ((0...@enquete_items.size).collect{|i| answer.items[i].value rescue ''} + [public_term_strftime(answer.answered_at)]).collect{|i| Filter.convert(i, 'utf-8', 'shift_jis')})
    end
    workbook.close
    send_file('/var/tmp/enquete.xls',
              :filename => 'enquete.xls',
              :type => 'application/vnd.ms-excel')
  end

  def xml
    prepare_output
    response.headers['Content-Type'] = 'application/vnd.ms-excel'
    response.headers['Content-Disposition'] = 
      'attachment; filename="enquete.xml"'
  end

  def destroy
    answer = EnqueteAnswer.find(params[:id])
    page = answer.page
    answer.destroy
    redirect_to(:action => 'show', :id => page)
  end

  private

  def ssl_required?
    true
  end

  def prepare_output
    EnqueteAnswer.retrieve_form_data
    @page = Page.find(params[:id])
    @enquete_items = @page.enquete_items
    @enquete_answers = @page.enquete_answers
  end
end
