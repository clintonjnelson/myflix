class UserRegistration
  attr_accessor :user
  def initialize(user)
    @user = user
  end

  def register_new_user(stripeToken, amount, invitation_token)
    #It's logical, but seems like there should be a better method of doing this.
    if @user.valid?
      customer = create_customer_subscription(stripeToken)
      if customer.successful?
        create_user(customer.response['id'])
        make_cofollowers(invitation_token) if invitation_token.present?
        @user
      else
        customer.error_message
      end
    else
      @user.errors.full_messages
    end
  end

  def charge_user(options={})
    StripeWrapper::Charge.create( :card        => options[:stripeToken],
                                  :customer    => options[:customer_id],
                                  :amount      => options[:amount],
                                  :description => "New Subscription for #{@user.email}",
                                  :currency    => 'usd')
  end

  def create_user(customer_id)
    @user.stripe_customer_id = customer_id
    @user.save
    MyflixMailer.delay.welcome_email(@user.id)
  end

  def create_customer_subscription(stripeToken)
    customer = StripeWrapper::Customer.create(user: @user, plan: 'myflix_premium', card: stripeToken)
  end

  def make_cofollowers(invitation_token)
    invitation = Invitation.find_by(token: invitation_token)
    inviter = User.find_by(id: invitation.inviter_id)
    inviter.follow(@user)
    @user.follow(inviter)
    invitation.clear_invitation_token
  end
end
