class Skip::GroupsController < Skip::ApplicationController
  def sync
    created, updated, deleted = SkipGroup.transaction{ SkipGroup.sync!(params[:groups]) }
    @groups = [created, updated].flatten
    respond_to do |f|
      res = {:groups => @groups.map{|g| api_response(g) }}
      f.js{ render :json => res.to_json }
    end
  rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => why
    record = why.record
    rendeor_validation_error(record)
  end

  def create
    @skip_group = SkipGroup.new(params[:group].except(:members))

    ActiveRecord::Base.transaction{ save_with_grant(@skip_group, params[:group][:members]) }
    render :json => {:group => api_response(@skip_group)}.to_json
  rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => why
    rendor_validation_error(@skip_group)
  end

  def update
    unless @skip_group = SkipGroup.find_by_gid(params[:id])
      raise ActiveRecord::RecordNotFound
    end

    @skip_group.attributes = params[:group].except(:members)

    ActiveRecord::Base.transaction{ save_with_grant(@skip_group, params[:group][:members]) }
    render :json => api_response(@skip_group).to_json
  rescue ActiveRecord::RecordNotSaved => why
    rendor_validation_error(@skip_group)
  end

  def destroy
    unless @skip_group = SkipGroup.find_by_gid(params[:id])
      raise ActiveRecord::RecordNotFound
    end
    @skip_group.destroy ?  head(:ok) : head(:bad_request)
  end

  private
  def api_response(group)
    returning group.attributes.slice(*%w[id gid name display_name]) do |hash|
      hash[:members] = group.group.users.map{|u| {:identity_url => u.identity_url } }
      hash[:url] = skip_group_url(hash["gid"])
    end
  end

  def save_with_grant(group, member_identities)
    group.grant(member_identities)
    group.save!
    group.group.save!
  end
end
