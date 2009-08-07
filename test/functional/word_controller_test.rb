require File.dirname(__FILE__) + '/../test_helper'
require 'word_controller'

# Re-raise errors caught by the controller.
class WordController; def rescue_action(e) raise e end; end

class WordControllerTest < Test::Unit::TestCase
  fixtures :words

  def setup
    @controller = WordController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
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

    assert_equal(2, assigns(:words).size)
  end

  def test_list_with_query
    get(:list, :query_text => 'か')

    assert_response(:success)
    assert_template('list')

    assert_equal(1, assigns(:words).size)
  end

  def test_create
    num_words = Word.count

    post(:create, :word => {:base => '片　仮　名', :text => 'かたかな'})
    assert_response(:success)
    assert_template('list')
    assert_equal('見出し語に不正な文字が含まれています。',
                 assigns(:word).errors.on(:base))
    assert_equal(num_words, Word.count)

    post(:create, :word => {:base => '片仮名', :text => 'かたかな'})
    assert_response(:redirect)
    assert_redirected_to(:action => 'list')
    assert_equal(num_words + 1, Word.count)
  end

  def test_edit
    get(:edit, :id => 1)

    assert_response(:success)
    assert_template('edit')

    assert_not_nil(assigns(:word))
    assert assigns(:word).valid?
  end

  def test_update
    post(:update, :id => 1, :word => {:base => '幹事', :text => 'かんじ'})
    assert_response(:redirect)
    assert_redirected_to(:action => 'list')
  end

  def test_destroy
    assert_not_nil(Word.find(1))

    post(:destroy, :id => 1)
    assert_response(:redirect)
    assert_redirected_to(:action => 'list')

    assert_raise(ActiveRecord::RecordNotFound) {
      Word.find(1)
    }
  end
end
