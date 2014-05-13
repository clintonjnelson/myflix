class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :signed_in?, :signed_out?, :current_user


  def signin_user(user)
    if user.locked_account?
      notify_locked_account
    else
      session[:user_id] = user.id
      flash[:notice] ||= "Welcome, #{user.name}!"
      redirect_to root_path
    end
  end

  def current_user
    User.find(session[:user_id]) if signed_in?
  end

  def access_denied(msg)
    flash[:notice] = msg
    redirect_to root_path
  end

  def signed_in?
    !!session[:user_id]
  end

  def signed_out?
    !!session[:user_id].nil?
  end

  def require_signed_in
    unless signed_in?
      flash[:error] = "Please sign-in to do that."
      redirect_to signin_path
    end
    if signed_in? && current_user.locked_account?
      notify_locked_account
    end
  end

  def require_signed_out
    unless signed_out?
      access_denied("You're already signed in.")
    end
  end

  def notify_locked_account
    access_denied("Your account is locked due to a failed payment. Please contact customer service.")
    redirect_to root_path
  end
end
