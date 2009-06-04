class Admin::GroupsController < Admin::ApplicationController

  def show
    @group = Group.find_by_name(params[:id])
    @note = @group.owning_note
    @topics = [[_("note"), admin_notes_path],
               ["#{@note.display_name}", edit_admin_note_path(@note)],
                _("group users")]
  end
end
