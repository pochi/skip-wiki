class Admin::AttachmentsController < Admin::ApplicationController
  layout "admin"

  def index
    @attachments = Attachment.find(collect_ids).paginate(paginate_option(Attachment))
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

public
  def collect_ids
    return :all if requested_note.nil?
    returning([]) do |atcs|
      requested_note.attachments.each do |attachment|
        atcs << attachment.id
      end
    end
  end

end
