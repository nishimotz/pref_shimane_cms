class Word < ActiveRecord::Base

  set_field_names(:base => '見出し語',
                  :text => '読み')
  
  belongs_to(:user)

  validates_presence_of(:base, :message => "見出し語を入力してください。")
  validates_presence_of(:text, :message => "を入力してください。")
  validates_uniqueness_of(:base, :message => "見出し語はすでに登録されています。もう少し長い単語で登録してください。")
  validates_format_of(:base, :with => /\A[^\s!-~　]*\z/, :message => "見出し語に不正な文字が含まれています。")
  validates_format_of(:text, :with => /\A[ぁ-ん゛ァ-ヶー]*\z/, :message => "に不正な文字が含まれています。")

  DICT_DIR = File.join(RAILS_ROOT, 'dict')
  MAKE_DA = "/usr/lib/chasen/makeda"

  def self.last_modified
    self.find(:first, :order => 'updated_at desc').updated_at rescue Time.at(0)
  end

  def before_save
    self[:text] = Filter.h2k(self[:text])
  end

  def editable_by?(user)
    user.authority == User::SUPER_USER || self.user.section_id == user.section_id
  end

  def after_save
    update_dic
  end

  def after_destroy
    update_dic
  end

  private

  def update_dic
    return if ENV['RAILS_ENV'] == 'test'
    dict_text = ''
    Dir["#{DICT_DIR}/*.dic"].each do |dict|
      dict_text << File.read(dict)
    end
    connection.execute("LOCK #{self.class.table_name};")
    self.class.find(:all).each do |word|
      dict_text << NKF.nkf('-Wem0', "(品詞 (名詞 一般)) ((見出し語 (#{word.base} 2000)) (読み #{word.text}) (発音 #{word.text}) )\n")
    end
    File.open('/var/tmp/dict.txt', 'w'){|f| f.print dict_text}
    IO.popen("#{MAKE_DA} #{DICT_DIR}/user -", 'w') do |io|
      io.print dict_text
    end
  end
end
