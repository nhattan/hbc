class Admin::UsersController < ApplicationController
  before_filter :authenticate_admin!
  load_and_authorize_resource
  
  def index
    @users = User.paginate(page: params[:page], per_page: 20)
  end

  def show
    @user = User.find params[:id]
  end

  def destroy
    @user = User.find params[:id]
    @user.destroy
    flash[:success] = "Deleted"
    redirect_to @admin_users_url
  end
end
