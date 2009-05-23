class SkipController < Skip::ApplicationController
  before_filter :check_secret_key
  before_filter :reject_if_skip_app_exist

  def create
    @client_application = ClientApplication.new(params[:skip])
    @client_application.name = Skip::ApplicationController::SKIP_NAME
    @client_application.grant_as_family!

    if @client_application.save
      render_client_app
    else
      respond_to{|f| f.js{ render :json => @client_application.errors.full_messages.to_json }}
    end
  end

  private
  def render_client_app(app = @client_application)
    respond_to{|f| f.js{ render :json => {:skip=>app.attributes}.to_json }}
  end

  def reject_if_skip_app_exist
    if @client_application = ClientApplication.find_by_name(Skip::ApplicationController::SKIP_NAME)
      head(:conflict)
    end
  end
end
