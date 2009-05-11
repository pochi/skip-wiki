class SkipController < Skip::ApplicationController
  def create
    @client_application = ClientApplication.new(params[:skip])
    if @client_application.save
      @client_application.grant_as_family!
      respond_to{|f| f.xml{ render :xml => @client_application.to_xml(:root => "skip") } }
    else
      respond_to{|f| f.xml{ render :xml => @client_application.errors.to_xml } }
    end
  end
end
