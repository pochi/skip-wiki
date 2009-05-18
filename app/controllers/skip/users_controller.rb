class Skip::UsersController < Skip::ApplicationController
  before_filter :check_secret_key, :only => %w[create sync]
  before_filter :authenticate_with_oauth, :only => %w[update destroy]

  def sync
    created, updated, deleted = User.transaction{ User.sync!(skip, params[:users]) }
    @users = [created, updated].flatten
    respond_to do |f|
      res = @users.map{|u| api_response(u, u.access_token_for(skip)) }
      f.xml{ render :xml => res.to_xml(:root => "users", :child => {:root => "user"}) }
    end
  rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid => why
    record = why.record
    rendeor_validation_error(record)
  end

  def create
    @user, token = User.transaction{ User.create_with_token!(skip, params[:user]) }
    respond_to do |f|
      f.xml{ render :xml => api_response(@user, token).to_xml(:root => "user") }
    end
  rescue ActiveRecord::RecordNotFound => why
    rendeor_validation_error(current_user)
  end

  def update
    current_user.attributes = params[:user]
    current_user.identity_url = params[:user][:identity_url]

    if current_user.save
      respond_to do |f|
        f.xml do
          res = api_response(current_user, current_user.access_token_for(skip))
          render :xml => res.to_xml(:root => "user")
        end
      end
    else
      rendeor_validation_error(current_user)
    end
  end

  def destroy
    current_user.logical_destroy ?  head(:ok) : head(:bad_request)
  end

  private
  def skip
    @client ||= ClientApplication.families.find(:first, :conditions => {:name => Skip::ApplicationController::SKIP_NAME})
  end

  def api_response(user, token = nil)
    returning( user.attributes.slice(:identity_url) ) do |res|
      if token
        res["access_token"] = token.token
        res["access_secret"] = token.secret
      end
    end
  end
end
