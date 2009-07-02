class Admin::HistoriesController < Admin::ApplicationController

  def new
    @note = requested_note
    @page = Page.find_by_name(params[:page_id])
    @topics = [[_("note pages"), admin_pages_path],
               ["#{@page.display_name}", admin_note_page_path(@note, @page)],
                _("Edit")]
  end

  def create
    @page = Page.find_by_name(params[:page_id])
    @history = @page.edit(params[:history][:content], current_user)
    if @history.save
      respond_to do |format|
        format.html{ redirect_to admin_note_page_url(requested_note, @page) }
        format.js{ head(:created, :location => admin_note_page_history_path(requested_note, @page, @history)) }
      end
    else
      errors = [@history, @history.content].map{|m| m.errors.full_messages }.flatten
      respond_to do |format|
        format.js{ render(:json => errors, :status=>:unprocessable_entity) }
      end
    end
  end

end
