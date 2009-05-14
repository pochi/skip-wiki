class Skip::ApplicationController < ApplicationController
  skip_before_filter :authenticate
  before_filter :internal_call_only
  SKIP_NAME = "SKIP"

  private
  def internal_call_only
    :implement_me
  end
end
