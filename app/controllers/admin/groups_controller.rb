class Admin::GroupsController < Admin::ApplicationController
  layout "admin"

  def show 
    @group = Group.find(params[:id])  
    @note = @group.owning_note
    @topics = [[_("User|Notes"), admin_notes_path],
               ["#{@note.display_name}", edit_admin_note_path(@note)],
                _("User|Index")]    
  end
end
