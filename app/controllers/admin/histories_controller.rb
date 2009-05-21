class Admin::HistoriesController < Admin::ApplicationController
  layout "admin"

  def new
    @note = Note.find_by_name(params[:note_id])
    @page = Page.find_by_name(params[:page_id])
    @topics = [["ページ一覧", admin_pages_path],
               ["#{@page.display_name}", admin_note_page_path(@note, @page)],
                "編集"]    
  end
end
