class PageLock < ActiveRecord::Base
  LOCK_TIME = 14400 # 4時間

  belongs_to(:page)

  def expired?
    return self.time + LOCK_TIME < Time.now
  end
end
