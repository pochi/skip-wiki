class Admin::NotesController < Admin::ApplicationController

  # GET
  def index
    @notes = Note.fulltext(params[:keyword]).
                  paginate(paginate_option)
    @topics = [_("note")]
    @search = [admin_notes_path, _("Search Note")]
  end

  def show
    @note = Note.find_by_name(params[:id])
    @topics = [[_("note"), admin_notes_path],
                "#{@note.display_name}"]
  end

  def edit
    @note = Note.find_by_name(params[:id])
    @topics = [[_("note"), admin_notes_path],
                "#{@note.display_name}"]
  end

  # PUT /admin/notes/1
  def update
    @note = Note.find_by_name(params[:id])
    if @note.update_attributes(params[:note])
      flash[:notice] = _('Note was successfully updated.')
      redirect_to edit_admin_note_path(params[:id])
    else
      flash[:error] = _('validation error')
      redirect_to :action => 'edit'
    end
  end

  def destroy
    begin
      @note = Note.find_by_name(params[:id])
      @note.destroy
      flash[:notice] = _("Note was deleted successfully")
      redirect_to admin_notes_url
    rescue => ex
      flash[:error] = _("Note can't deleted.")
    end
  end

end
