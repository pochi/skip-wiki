class Skip::GroupsController < Skip::ApplicationController
  def create
    @skip_group = SkipGroup.new(params[:group].except(:members))
    ActiveRecord::Base.transaction do
      @skip_group.grant(params[:group][:members])
      @skip_group.save!
      @skip_group.group.save!
    end
    render :xml => api_response(@skip_group).to_xml(:root => "group")
  rescue ActiveRecord::RecordNotSaved => why
    render :xml => @skip_group.errors, :status => :unprocessable_entity
  end

  private
  def api_response(group)
    returning group.attributes.slice(*%w[id gid name display_name]) do |hash|
      hash[:members] = group.group.users.map{|u| {:identity_url => u.identity_url } }
    end
  end
end
