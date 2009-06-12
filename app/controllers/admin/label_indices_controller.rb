class Admin::LabelIndicesController < Admin::ApplicationController

  def index
    @note = requested_note
    @topics = [[_("note"), admin_notes_path],
                _("label index") + "(#{@note.display_name})"]
  end

  def show
    @label_index = requested_note.label_indices.find(params[:id])
  end

  def update
    note = Note.find_by_name(params[:note_id])
    @label_index = note.label_indices.find(params[:id])

    respond_to do |format|
      if @label_index.update_attributes(params[:label_index])
        format.html {
          flash[:notice] = 'LabelIndex was successfully updated.'
          redirect_to admin_note_label_indices_url(note)
        }
        format.xml  { head :ok }
        format.js  { head :ok }
      else
        format.html { render :action => "index" }
        format.xml  { render :xml => @label_index.errors, :status => :unprocessable_entity }
      end
    end
  end

end
