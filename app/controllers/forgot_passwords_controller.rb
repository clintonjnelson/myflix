class ForgotPasswordsController < ApplicationController
  before_action :require_signed_out

  def new
  end

  def create
    @user = User.find_by(email: params[:email])
    if !@user.blank?
      @user.update_column(:password_reset_token, User.generate_token)
      MyflixMailer.password_reset_email(@user).deliver
      redirect_to confirm_password_reset_email_path
    else
      flash[:error] = "Incorrect Email Address."
      redirect_to forgot_password_path
    end
  end
end
