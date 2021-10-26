class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :protect_user, except: [:new, :create]
  skip_before_action :authenticate_user, only: [:new, :create]

  def show
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to login_path, notice: "User was successfully created."
    else
      flash.now[:notice] = "Unable to create user: #{@user.errors.full_messages.map(&:downcase).join(", ")}"
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      redirect_to @user, success: "User was successfully updated."
    else
      flash.now[:notice] = "Unable to update user: #{@user.errors.full_messages.map(&:downcase).join(", ")}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy

    @user.destroy
    redirect_to users_url, success: "User was successfully destroyed."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :username, :email, :password, :password_confirmation)
  end

  def protect_user
    unless @user == @current_user
      redirect_to @current_user, alert: "You cannot access data for other users"
    end
  end
end
