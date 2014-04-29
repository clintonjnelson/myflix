class UserRegistration
  attr_reader :user
  def initialize(user)
    @user = user
  end

  def register_new_user(stripeToken, amount, invitation_token)
    if @user.valid?
      charge = charge_user(stripeToken, amount)
      if charge.successful?
        create_user
        make_cofollowers(invitation_token) if invitation_token.present?
        @user
      else
        charge.error_messages
      end
    else
      @user.errors.full_messages
    end
  end

  def charge_user(stripeToken, amount)
    StripeWrapper::Charge.create( card: stripeToken,
                                  # :customer    => @customer.response.id,
                                  :amount      => amount,
                                  :description => "New Subscription for #{@user.email}",
                                  :currency    => 'usd')
  end

  def create_user
    @user.save
    MyflixMailer.delay.welcome_email(@user.id)
  end

  def make_cofollowers(invitation_token)
    invitation = Invitation.find_by(token: invitation_token)
    inviter = User.find_by(id: invitation.inviter_id)
    inviter.follow(@user)
    @user.follow(inviter)
    invitation.clear_invitation_token
  end
end
