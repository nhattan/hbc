class UsersController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource
  
  def index
    @users = User.paginate(page: params[:page], per_page: 20)
  end
  
  def show
    @user = User.find params[:id]
  end
end