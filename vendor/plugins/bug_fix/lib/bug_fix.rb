module ActionView
  module Helpers
    module ScriptaculousHelper
      def drop_receiving_element(element_id, options = {})
        options[:with]     ||= "'id=' + encodeURIComponent(element.id)"
        options[:onDrop]   ||= "function(element){" + remote_function(options) + "}"
        options.delete_if { |key, value| PrototypeHelper::AJAX_OPTIONS.include?(key) }
        options.delete(:confirm)
        options[:accept] = array_or_string_for_javascript(options[:accept]) if options[:accept]    
        options[:hoverclass] = "'#{options[:hoverclass]}'" if options[:hoverclass]
  
        javascript_tag("Droppables.add('#{element_id}', #{options_for_javascript(options)})")
      end
    end
  end
end
