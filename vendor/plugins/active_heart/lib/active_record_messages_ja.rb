# 
# ActiveRecordのメッセージを日本語化するには
# set_field_names :source => '本文', :name => '名前'
#
# MIT License
# gorou <hotchpotch@gmail.com>
#
ActiveRecord::Base.class_eval do
  class << self
    def set_field_names(field_names = {})
      @field_names = HashWithIndifferentAccess.new unless @field_names
      @field_names.update(field_names)
    end

    alias_method :_human_attribute_name, :human_attribute_name
    def human_attribute_name(attribute_key_name)
      if @field_names && @field_names[attribute_key_name]
        @field_names[attribute_key_name]
      else
        _human_attribute_name(attribute_key_name)
      end
    end
  end
end

ActiveRecord::Errors.class_eval do
  default_error_messages.update({
    :inclusion => "はリストに含まれてません",
    :exclusion => "はリストに含まれてます",
    :invalid => "は不正な値です",
    :confirmation => "は確認されませんでした",
    :accepted  => "は許可されていません",
    :empty => "を入力して下さい",
    :blank => "を入力して下さい",
    :too_long => "は%d文字以下で入力して下さい",
    :too_short => "は%d文字以上で入力してください",
    :wrong_length => "は%d文字でなければなりません",
    :taken => "はすでに存在します",
    :not_a_number => "は数字で入力して下さい",
  })

  alias_method :_full_messages, :full_messages
  def full_messages
    full_messages = []

    @errors.each_key do |attr|
      @errors[attr].each do |msg|
        next if msg.nil?
        if attr == "base"
          full_messages << msg
        else
          full_messages << @base.class.human_attribute_name(attr) + msg
        end
      end
    end
    full_messages
  end
end

ActionView::Helpers::ActiveRecordHelper.module_eval do
  alias_method :_error_messages_for, :error_messages_for
  def error_messages_for(object_name, options = {})
    object = instance_variable_get("@#{object_name}")
    unless object.errors.empty?
      if options.is_a? String
        # render_template
        render :partial=> options,
               :locals=> { :messages => object.errors.full_messages, :object => object }
      else
        options = options.symbolize_keys
        content_tag("div",
          content_tag(
            options[:header_tag] || "h2",
            "#{object.errors.count}個のエラーが発生しました"
          ) +
          content_tag("p", "次の項目に問題があります") +
          content_tag("ul", object.errors.full_messages.collect { |msg| content_tag("li", msg) }),
          "id" => options[:id] || "errorExplanation", "class" => options[:class] || "errorExplanation"
        )
      end
    end
  end

  def template_error_messages_for(object_name, template_name = 'layout/error_messages_for')
    error_messages_for(object_name, template_name)
  end
end
