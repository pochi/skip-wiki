class Admin::LabelIndicesController < Admin::ApplicationController
  layout "admin"

  def index
    requested_note
    @topics = [["ノート一覧", admin_notes_path],
               ["#{@note.display_name}", edit_admin_note_path(@note)],
                "ラベル一覧"]    
  end

  def show
    @label_index = requested_note.label_indices.find(params[:id])
  end

  def update
  end

end
