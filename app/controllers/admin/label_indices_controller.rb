class Admin::LabelIndicesController < Admin::ApplicationController
  layout "admin"

  def index
    requested_note
  end

  def show
    @label_index = requested_note.label_indices.find(params[:id])
  end

  def update
  end

end
