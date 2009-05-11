class MembershipsController < ApplicationController
  before_filter :authenticate, :except=>[:index]

  # accessed only via /groups/:group_id/memberships
  #  OR raise error in find(params[:group_id])
  def create
    group = current_user.groups.find(params[:group_id])
    queries = params[:memberships].map{|_,q| q }
    valid_params = queries.select{|q| q[:enabled] && Integer(q[:group_id]) == group.id }
    begin
      ActiveRecord::Base.transaction do
        ids = (valid_params.map{|q| Integer(q[:user_id]) } << current_user.id).uniq
        group.user_ids = ids
      end
      flash[:notice] = _("Successfully update membership.")
      redirect_to(group_path(group))
    rescue ActiveRecord::RecordNotSaved
      render :template => "groups/show"
    end
  end

  private
  def requested_user
    @requested_user ||= User.find(params[:user_id])
  end
end
