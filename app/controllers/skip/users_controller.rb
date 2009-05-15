class Skip::UsersController < Skip::ApplicationController
  before_filter :check_secret_key, :only => %w[create]
  before_filter :authenticate_with_oauth, :only => %w[update destroy]

  def create
    @user, token = ActiveRecord::Base.transaction{ create_user_and_token!(params[:user]) }
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
          token = current_user.tokens.find(:first, :conditions => {:client_application_id => skip,
                                                                   :type => "AccessToken"})
          render :xml => api_response(current_user, token).to_xml(:root => "user")
        end
      end
    else
      rendeor_validation_error(current_user)
    end
  end

  def destroy
    current_user.logical_destroy
    respond_to do |f|
      f.xml{ render :xml => api_response(current_user).to_xml(:root => "user") }
    end
  end

  private
  def skip
    @client ||= ClientApplication.families.find(:first, :conditions => {:name => Skip::ApplicationController::SKIP_NAME})
  end

  def create_user_and_token!(user_param)
    user = User.new(user_param){|u| u.identity_url = user_param[:identity_url] }
    user.save!
    return [user, skip.publish_access_token(user)]
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
