class Admin::HistoriesController < Admin::ApplicationController
  layout "admin"

  def new
    @note = Note.find(params[:note_id])
    @page = Page.find(params[:page_id])
  end
end
