class EnqueteAnswer < ActiveRecord::Base
  has_many(:enquete_answer_items, :dependent => true,
           :foreign_key => 'answer_id')
  belongs_to(:page)

  def items
    ret = []
    no_list = []
    self.page.enquete_items.each do |item|
      no_list[item.id] = item.no
    end
    self.enquete_answer_items.each do |item|
      begin
        ret[no_list[item.enquete_item_id]] = item
      rescue
      end
    end
    ret
  end

  def item_answers(item)
    answer_items = enquete_answer_items.
                     find(:all,
                          :order => 'value ASC',
                          :conditions => ['enquete_item_id = ?', item.id])
    if answer_items.any?
      answer_items.map{|ai| "#{ai.value}#{ai.other ? ':' + ai.other : ''}"}.join(',')
    else
      ''
    end
  end

  def self.retrieve_form_data
    pages = {}
    fdr = FormDataRetriever.new(:enquete)
    fdr.retrieve do |data|
      begin
        transaction do
          page = Page.find(data[:page_id].to_i)
          answer = EnqueteAnswer.new(:page => page,
                                     :answered_at => data[:date],
                                     :remote_addr => data[:remote_addr])
          answer.save
          data[:answers].each do |name, values|
            q = page.enquete_items.find(:first,
                                        :conditions => ["name = ?", name])
            next unless q
            values.each do |val|
              if val.instance_of?(Hash)
                value, other = val.shift
                a = EnqueteAnswerItem.new(:enquete_answer => answer,
                                          :enquete_item => q,
                                          :value => value,
                                          :other => other)
              else
                a = EnqueteAnswerItem.new(:enquete_answer => answer,
                                          :enquete_item => q,
                                          :value => val)
              end
              a.save
            end
          end
          unless pages["#{page.id}"]
            pages["#{page.id}"] = page
          end
        end
      rescue ActiveRecord::RecordNotFound
      end
    end
    return pages
  end
end
