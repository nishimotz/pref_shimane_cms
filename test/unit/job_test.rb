require File.dirname(__FILE__) + '/../test_helper'

class JobTest < Test::Unit::TestCase
  fixtures :jobs

  def test_next
    job = Job.next
    assert_equal(jobs(:create_page), job)
    job.destroy
    job = Job.next
    assert_equal(jobs(:create_page_without_datetime), job)
  end

  def test_list
    list = Job.list
    assert_equal([jobs(:create_page), jobs(:create_page_without_datetime)],
                 Job.list)
  end
end
