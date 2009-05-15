class Skip::ApplicationController < ApplicationController
  skip_before_filter :authenticate
  before_filter :internal_call_only
  SKIP_NAME = "SKIP"

  private
  def internal_call_only
    :implement_me
  end

  def rendeor_validation_error(model)
    respond_to do |f|
      f.xml{ render :xml => model.errors.to_xml, :status => :unprocessable_entity }
    end
  end

end
