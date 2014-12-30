class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!
  load_and_authorize_resource

  def index
    @users = User.paginate(page: params[:page], per_page: 20)
  end

  def show
  end

  def update
    if @user.update(user_params)
      sign_in(@user == current_user ? @user : current_user, bypass: true)
      edirect_to @user, notice: "Your profile was successfully updated."
    else
      render action: "edit"
    end
  end

  def finish_signup
    if request.patch? && params[:user]
      if @user.update(user_params)
        sign_in(@user, bypass: true)
        redirect_to @user, notice: "Your profile was successfully updated."
      else
        @show_errors = true
      end
    end
  end

  private
  def set_user
    @user = User.find params[:id]
  end

  def user_params
    accessibles = [:name, :email]
    accessibles << [:password, :password_confirmation] unless params[:user][:password].blank?
    params.require(:user).permit(accessibles)
  end
end
