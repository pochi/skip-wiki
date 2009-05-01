class Admin::AttachmentsController < Admin::ApplicationController
  layout "admin"

  def index
    @attachments = requested_note ? requested_note.attachments : Attachment.paginate(paginate_option(Attachment))
  end

  def show
    @attachment = Attachment.find(params[:id])
    opts = {:filename => @attachment.filename, :type => @attachment.content_type }
    opts[:disposition] = "inline" if params[:position] == "inline"

    send_file(@attachment.full_filename, opts)
  end

  def destroy
    begin
      @attachment = Attachment.find(params[:id])
      @attachment.destroy
      flash[:notice] = _("Attachment was deleted successfully")
      redirect_to (requested_note ? admin_note_attachments_url(requested_note) : admin_attachments_url)
    rescue => ex
      flash[:error] = "Failed to delete attachment"
    end
  end
end
