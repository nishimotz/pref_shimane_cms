#
# 生成するURLにsession_idをつけ、formの値にhiddenでsession_idを埋めるには、適当な箇所で
# ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS[:trans_sid] = true
# を設定する
#
# MIT License
# gorou <hotchpotch@gmail.com>
#
module TransSid
  class TransSidFilter
    def before(controller)
    end

    def after(controller)
      if ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS[:trans_sid]
        session_key = ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS[:session_key] || '_session_id'
        session_id = controller.request.session.session_id
        controller.response.body.gsub!(%r{(</form>)}i, "<input type='hidden' name='#{CGI::escapeHTML session_key}' value='#{CGI::escapeHTML session_id}'>\\1")
      end
    end
  end
end

ActionController::Base.class_eval do 
  around_filter ::TransSid::TransSidFilter.new
end

ActionController::UrlRewriter.class_eval do
  private
  alias_method :_rewrite_path, :rewrite_path
  def rewrite_path(options)
    if ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS[:trans_sid]
      session_key = ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS[:session_key] || '_session_id'
      if session_id = @request.session.session_id
        options.update({session_key => @request.session.session_id })
      end
    end
    _rewrite_path options
  end
end
