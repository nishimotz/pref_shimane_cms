module AdminHelper
  include VisitorHelper
  def mode
    return @mode if @mode
    case @action
    when :genre
      @mode = :genre
    when :move, :config
      @mode = :config
    when :config_public_page, :config_edit_page
      @mode = :info
    when :home
      @mode = :home
    else
      @mode = :page
    end
    @mode
  end
end
