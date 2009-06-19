class Admin::ApplicationController < ApplicationController
  before_filter :require_admin
  layout 'admin'

  # TODO privateにした場合テスト時にメソッドが呼べない
  # private
  def require_admin
    unless current_user.admin?
      redirect_to root_url
      return false
    end
    return true
  end

  def requested_note
    return params[:note_id].nil? ? nil : @note = Note.find_by_name(params[:note_id])
  end

end
