class SkipController < Skip::ApplicationController
  def create
    @client_application = ClientApplication.new(params[:skip])
    @client_application.name = Skip::ApplicationController::SKIP_NAME
    if @client_application.save
      @client_application.grant_as_family!
      respond_to{|f| f.js{ render :json => {:skip=>@client_application.attributes}.to_json }}
    else
      respond_to{|f| f.js{ render :json => @client_application.errors.to_json }}
    end
  end
end
