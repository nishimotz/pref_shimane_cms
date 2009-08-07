module WebClient

  class Link
    attr_reader :node, :href, :text

    def initialize(node, href, text = nil)
      @node = node
      @href = href
      @text = text
    end

    # Returns an array of Link objects
    def self.extract_all_from(root_node)
      links = []
      root_node.traverse_element {|i|
	case i.qualified_name
	when 'a'
	  href = i.get_attribute('href').to_s
	  text = i.extract_text.to_s
	  links << Link.new(i, href, text)
	when 'area'
	  href = i.get_attribute('href').to_s
	  text = i.get_attribute('alt').to_s
	  links << Link.new(i, href, text)
	when 'frame'
	  href = i.get_attribute('src').to_s
	  text = i.get_attribute('title').to_s
	  links << Link.new(i, href, text)
	when 'img'
	  href = i.get_attribute('src').to_s
	  text = i.get_attribute('alt').to_s
	  links << Link.new(i, href, text)
	end
      }
      return links
    end
  end
end

