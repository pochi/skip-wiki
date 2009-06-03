class Admin::LabelIndicesController < Admin::ApplicationController

  def index
    @note = requested_note
    @topics = [[_("note"), admin_notes_path],
               ["#{@note.display_name}", edit_admin_note_path(@note)],
                _("label index")]
  end

  def show
    @label_index = requested_note.label_indices.find(params[:id])

  end

  def update
  end

end
