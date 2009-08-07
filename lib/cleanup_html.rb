require 'rexml/document'

# 
# quote attribute by double quote insted of default single quote.
#
REXML::Attribute.class_eval( %q^
def to_string
%Q[#@expanded_name="#{to_s().gsub(/"/, '&quot;')}"]
end
^ )

class REXML::Element
  def wrap_element(element)
    #
    # wrap self with a given element.
    #
    self.parent.insert_before(self, element)
    element.add_element(self)
  end

  def wrap_align_table_with_div
    #
    # wrap tables which have align attribute set with 
    # div element which have corresponding attirbute set,
    # and remove align attirbute from the table element.
    #
    unless self.nil?
      if self.name == "table" && self.attribute("align")
        position = self.attribute("align")
        self.delete_attribute("align")
        self.add_attribute("class", "table_#{position}")
        div = REXML::Element.new("div")
        div.add_attribute("class", "table_div_#{position}")
        self.wrap_element(div)
      end
      self.elements.each do |e|
        e.wrap_align_table_with_div
      end
    end
  end
end
