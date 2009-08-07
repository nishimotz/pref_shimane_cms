require File.dirname(__FILE__) + '/../test_helper'
require 'enquete_controller'

# Re-raise errors caught by the controller.
class EnqueteController; def rescue_action(e) raise e end; end

class EnqueteControllerTest < Test::Unit::TestCase
  fixtures :enquete_items, :enquete_answers, :enquete_answer_items, :enquete_item_values

  def setup
    @controller = EnqueteController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.env['HTTPS'] = "on"
    create_session
  end

  def test_index
    get(:index)
    assert_response(:success)
    assert_template('list')
  end

  def test_list
    get(:list)
    assert_response(:success)
    assert_template('list')
    assert_equal(1, assigns(:enquetes).size)
    assert_equal(29, assigns(:enquetes).first.id)
  end

  def test_show
    get(:show, :id => 1)
    assert_response(:success)
    assert_template('show')
    assert_equal(1, assigns(:page).id)
    assert_equal(3, assigns(:enquete_items).size)
    assert_equal(1, assigns(:enquete_answers).size)
  end

  def test_answer_values
    get(:answer_values, :id => 1, :enquete_item => enquete_items(:item3).id)
    assert_response(:success)
    assert_template('answer_values')
    assert_equal(1, assigns(:page).id)
    assert_equal(1, assigns(:answer_values).size)
    assert_equal('value3', assigns(:answer_values)[0])
  end

  def test_other_values
    get(:other_values, :id => 1, :other_value => enquete_item_values(:another).id)
    assert_response(:success)
    assert_template('other_values')
    assert_equal(1, assigns(:page).id)
    assert_equal(1, assigns(:other_values).size)
    assert_equal('value2 other value', assigns(:other_values)[0])
  end

  def test_csv
    get(:csv, :id => 1)
    assert_response(:success)
    assert_template('csv')
    assert_equal('text/csv; charset=Shift_JIS',
                 @response.headers['Content-Type'])
    assert_equal('attachment; filename="enquete.csv"',
                 @response.headers['Content-Disposition'])
    assert_equal(%Q!"item1","item2","item3","投稿日時"\n"value1,value1_2,value1_3:other value","value2:value2 other value","value3","2006年01月02日 00時00分"\n!, NKF.nkf('-Sw', @response.body))
    assert_equal(NKF::SJIS, NKF::guess(@response.body))
    assert_equal(1, assigns(:page).id)
    assert_equal(3, assigns(:enquete_items).size)
    assert_equal(1, assigns(:enquete_answers).size)
  end

  def test_xls
    get(:xls, :id => 1)
    assert_response(:success)
    assert_template(nil)
    assert_equal('application/vnd.ms-excel', @response.headers['Content-Type'])
    assert_equal('attachment; filename="enquete.xls"',
                 @response.headers['Content-Disposition'])
    assert_equal(1, assigns(:page).id)
    assert_equal(3, assigns(:enquete_items).size)
    assert_equal(1, assigns(:enquete_answers).size)
  end

  def test_xml
    get(:xml, :id => 1)
    assert_response(:success)
    assert_template('xml')
    assert_equal('application/vnd.ms-excel', @response.headers['Content-Type'])
    assert_equal('attachment; filename="enquete.xml"',
                 @response.headers['Content-Disposition'])
    assert_equal(NKF::UTF8, NKF::guess(@response.body))
    assert_equal(1, assigns(:page).id)
    assert_equal(3, assigns(:enquete_items).size)
    assert_equal(1, assigns(:enquete_answers).size)
  end

  def test_destroy
    post(:destroy, :id => 1)
    assert_response(:redirect)
    assert_redirected_to(:action => 'show', :id => 1)
  end
end
