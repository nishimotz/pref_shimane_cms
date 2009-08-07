module WebMonitorHelper

  def fixed_error_messages_for(record)
    message = ''
    obj = self

    ::ActiveRecord::Errors.class_eval do
      method = instance_method :full_messages
      remove_method :full_messages

      def full_messages
        full_messages = []
        @errors.each_key do |attr|
          @errors[attr].each do |msg|
            next if msg.nil?
            full_messages << @base.class.human_attribute_name(attr.to_s) + msg
          end
        end
        full_messages
      end

      message = obj.instance_eval do
        error_messages_for(record)
      end

      remove_method :full_messages
      define_method :full_messages, method
    end

    message
  end
end
