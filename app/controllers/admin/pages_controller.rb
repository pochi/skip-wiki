class Admin::PagesController < Admin::ApplicationController
  include PagesModule::PagesUtil

  # GET /admin/notes/a_note/pages
  def index
    @selected_note = requested_note
    @pages = Page.admin(@selected_note ? @selected_note.id : nil).
                  admin_fulltext(params[:keyword]).
                  paginate(paginate_option(Page))
    @topics = [_("page")]
    @search = [admin_pages_path, _("Search Page")]
  end

  def show
    @note = requested_note
    @page = Page.find_by_name(params[:id])
    @topics = [[_("page"), admin_pages_path],
               "#{@page.display_name}"]
  end

  def edit
    @note = requested_note
    @page = Page.find_by_name(params[:id])
    @topics = [[_("page"), admin_pages_path],
               ["#{@page.display_name}", admin_note_page_path(@note, @page)],
                _("edit property")]
  end

  def update
    @page = Page.find_by_name(params[:id])
    @page.attributes = params[:page]
    @page.deleted = params[:page][:deleted]

    if @page.save
      flash[:notice] = _("Page was successfully updated.")
      redirect_to admin_note_page_path(requested_note,@page)
    else
      flash[:error] = _("validation error")
      redirect_to edit_admin_note_page_path(requested_note,@page)
    end
  end

  def destroy
    begin
      @page = Page.find_by_name(params[:id])
      @page.destroy
      flash[:notice] = _("Page was deleted successfully")
      redirect_to admin_note_pages_path(requested_note)
    rescue => ex
      flash[:error] = _("Failed to delete a page")
    end
  end
end


