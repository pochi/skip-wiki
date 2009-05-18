class Skip::ApplicationController < ApplicationController
  include SkipEmbedded::WebServiceUtil::Server

  skip_before_filter :authenticate
  before_filter :internal_call_only
  SKIP_NAME = "SKIP"

  private
  def internal_call_only
    :implement_me
  end

  def rendeor_validation_error(model)
    respond_to do |f|
      f.js{ render :json => model.errors.full_messages, :status => :unprocessable_entity }
    end
  end

end
