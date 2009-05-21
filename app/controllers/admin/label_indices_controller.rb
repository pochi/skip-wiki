class Admin::LabelIndicesController < Admin::ApplicationController
  layout "admin"

  def index
    requested_note
    @topics = [[_("User|Notes"), admin_notes_path],
               ["#{@note.display_name}", edit_admin_note_path(@note)],
                _("Label|Index")]    
  end

  def show
    @label_index = requested_note.label_indices.find(params[:id])
  end

  def update
  end

end
