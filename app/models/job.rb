class Job < ActiveRecord::Base
  def self.list
    self.find(:all,
              :conditions => ['(datetime <= ? or datetime is null) and action != ?',
                Time.now, 'create_mp3'],
              :order => 'datetime')
  end

  def self.list_mp3
    self.find(:all,
              :conditions => ['(datetime <= ? or datetime is null) and action = ?',
                Time.now, 'create_mp3'],
              :order => 'datetime')
  end

  def self.next
    self.find(:first,
              :conditions => ['(datetime <= ? or datetime is null) and action != ?',
                Time.now, 'create_mp3'],
              :order => 'id')
  end

  def self.next_mp3
    self.find(:first,
              :conditions => ['(datetime <= ? or datetime is null) and action = ?',
                Time.now, 'create_mp3'],
              :order => 'id')
  end
end
