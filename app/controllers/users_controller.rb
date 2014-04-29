class UsersController < ApplicationController
  before_action :require_signed_in,   only: [:show]
  before_action :set_user,            only: [:show]
  before_action :require_valid_invitation_token, only: [:new_with_token]

  def new
    @user = User.new
  end

  def new_with_token
    @invitation = Invitation.find_by(token: params[:token])
    @token = @invitation.token
    @user = User.new(email: @invitation.friend_email)
    render 'new'
  end

  def create
    @invitation_token = params[:token]
    @user = User.new(user_params)
    @creation = UserRegistration.new(@user).register_new_user(params[:stripeToken], 999, @invitation_token)
    if @creation.class == User
      flash[:notice] = "Welcome to myFlix!"
      signin_user(@creation) and return
    else
      flash[:error] = @creation
      render 'new'
    end
  end



  ############################### PRIVATE METHODS ##############################
  private
    def user_params
      params.require(:user).permit(:name, :email, :password, :token)
    end

    def require_valid_invitation_token
      redirect_to expired_token_path unless Invitation.find_by(token: params[:token])
    end

    def set_user
      @user = User.find(params[:id])
    end

    def require_owner
      User.find(params[:id]) == current_user if signed_in?
    end

    def set_monthly_fee
      @amount = 999
    end
end

# def sign_up_and_pay_or_render_errors
    #   ActiveRecord::Base.transaction do
    #     if @user.save
    #       @stripeToken = params[:stripeToken]
    #       # @customer = StripeWrapper::Customer.create( :email => params[:email],
    #       #                                             :card  => @stripeToken)
    #       @charge = StripeWrapper::Charge.create( card: @stripeToken,
    #                                               # :customer    => @customer.response.id,
    #                                               :amount      => @amount,
    #                                               :description => "New Subscription for #{@user.email}",
    #                                               :currency    => 'usd')
    #       if @charge.successful?
    #         users_by_invitation_are_cofollowers
    #         MyflixMailer.delay.welcome_email(@user.id)
    #         flash[:notice] = "Welcome to myFlix!"
    #         signin_user(@user) and return
    #       else
    #         flash[:error] = @charge.error_messages
    #         raise ActiveRecord::Rollback
    #       end
    #     else
    #       raise ActiveRecord::Rollback
    #     end
    #   end
    #   render 'new'
    # end
# def users_by_invitation_are_cofollowers
    #   if !@token.blank?
    #     @invitation = Invitation.find_by(token: @token)
    #     @inviter = User.find_by(id: @invitation.inviter_id)
    #     @inviter.follow(@user)
    #     @user.follow(@inviter)
    #     @invitation.clear_invitation_token
    #   end
    # end
