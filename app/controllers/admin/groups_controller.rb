class Admin::GroupsController < Admin::ApplicationController
  layout "admin"

  def show 
    @group = Group.find(params[:id])  
    @note = @group.owning_note
    @topics = [["ノート一覧", admin_notes_path],
               ["#{@note.display_name}", edit_admin_note_path(@note)],
                "ユーザ一覧"]    
  end
end
