class Admin::UsersController < Admin::ApplicationController

  # GET /admin
  def index
    @users = User.fulltext(params[:keyword]).
                  paginate(paginate_option(User))
    @per_page = (params[:per_page] || 10).to_i
    @topics = [_("user")]
    @search = [admin_users_path, _("Search User")]
  end

  # GET /admin/user/:id/edit
  def edit
    @user = User.find(params[:id])
    @topics = [[_("user"), admin_users_path],
                "#{@user.display_name}さん"]
  end

  # PUT /admin/user/:id
  def update
    @user = User.find(params[:id])

    if @user.update_attributes(params[:user])
      flash[:notice] = _("User was successfully updated.")
      redirect_to admin_root_path
    else
      flash[:error] = _("validation error")
      redirect_to :action => 'edit'
    end
  end

end
