class Skip::ApplicationController < ApplicationController
  include SkipEmbedded::WebServiceUtil::Server

  skip_before_filter :authenticate
  SKIP_NAME = "SKIP"

  private
  def rendeor_validation_error(model)
    respond_to do |f|
      f.js{ render :json => model.errors.full_messages, :status => :unprocessable_entity }
    end
  end
end
