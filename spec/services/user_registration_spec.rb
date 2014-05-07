require 'spec_helper'

##THINGS WORK BUT NEED TO UPDATE FOR REGISTRATION USING CUSTOMER and NOT just card

describe UserRegistration, vcr: true do
  let(:jen)         { Fabricate(:user) }
  let(:joe)         { Fabricate.build(:user) }
  let(:stripeToken) { '123abc' }
  let(:amount)      { 555 }
  let(:inviteToken) { nil }

  context "with valid user & card info" do
    before do
      customer = double(response: {'id' => 'new-id-123'}, successful?: true)
      StripeWrapper::Customer.should_receive(:create).and_return(customer)
    end
    after  { ActionMailer::Base.deliveries.clear }

    it "makes a new user" do
      UserRegistration.new(joe).register_new_user(stripeToken, amount, inviteToken)
      expect(User.count).to eq(1)
    end
    it "makes a new customer and puts the id in the user stripe_customer_id column" do
      UserRegistration.new(joe).register_new_user(stripeToken, amount, inviteToken)
      expect(User.first.stripe_customer_id).to_not be_nil
    end
  end

  context "with valid user, card info, AND invitation" do
    let(:invite) { Fabricate(:invitation, inviter_id: jen.id) }
    before do
      customer = double(response: {'id' => 'new-id-123'}, successful?: true)
      StripeWrapper::Customer.should_receive(:create).and_return(customer)
    end
    after  { ActionMailer::Base.deliveries.clear }

    it "sets the inviter as following the friend" do
      UserRegistration.new(joe).register_new_user(stripeToken, amount, invite.token)
      joe = User.last
      expect(jen.leaders).to include(joe)
    end
    it "sets the friend as following the inviter" do
      UserRegistration.new(joe).register_new_user(stripeToken, amount, invite.token)
      joe = User.last
      expect(joe.leaders).to include(jen)
    end
    it "sets the invitation token to nil - thus invalidating it from use" do
      UserRegistration.new(joe).register_new_user(stripeToken, amount, invite.token)
      expect(invite.reload.token).to be_nil
    end

    context "email sending" do
      before { UserRegistration.new(joe).register_new_user(stripeToken, amount, inviteToken) }
      after do
        ActionMailer::Base.deliveries.clear
        Sidekiq::Worker.clear_all
      end

      it "sends an email upon successful creation" do
        ActionMailer::Base.deliveries.should_not be_empty
      end
      it "sends email to the registering user's email address" do
        email = ActionMailer::Base.deliveries.last
        email.to.should eq([joe.email])
      end
      it "has a welcome message in the subject" do
        email = ActionMailer::Base.deliveries.last
        email.subject.should include("Welcome to MyFLiX")
      end
      it "has a welcome message in the body" do
        email = ActionMailer::Base.deliveries.last
        expect(email.parts.first.body.raw_source).to include(joe.name)
      end
      it "successfully sends to Sidekiq's queue"# do
      #   expect(Sidekiq::Extensions::DelayedMailer.jobs.size).to eq(1)
      # end
    end
  end

  context "with valid user and invalid credit card info" do
    before do
      customer = double(error_message: 'Your card was declined.', successful?: false)
      StripeWrapper::Customer.should_receive(:create).and_return(customer)
    end
    after do
      ActionMailer::Base.deliveries.clear
      Sidekiq::Worker.clear_all
    end

    it "does not create a new user" do
      UserRegistration.new(joe).register_new_user(stripeToken, amount, inviteToken)
      expect(User.count).to eq(0)
    end
    it "does not send an email" do
      UserRegistration.new(joe).register_new_user(stripeToken, amount, inviteToken)
      ActionMailer::Base.deliveries.should be_empty
    end
    it "returns the card error" do
      response = UserRegistration.new(joe).register_new_user(stripeToken, amount, inviteToken)
      expect(response).to eq("Your card was declined.")
    end
  end

  context "with invalid user and valid credit card info" do
    let(:invalid_joe) { Fabricate.build(:user, email: "") }
    before do
      charge = double(:charge, successful?: true)
      StripeWrapper::Charge.stub(:create).and_return(charge)
    end
    after  { ActionMailer::Base.deliveries.clear }

    it "does not create a new user" do
      UserRegistration.new(invalid_joe).register_new_user(stripeToken, amount, inviteToken)
      expect(User.count).to eq(0)
    end
    it "does not send an email" do
      MyflixMailer.should_not_receive(:welcome_email)
      UserRegistration.new(invalid_joe).register_new_user(stripeToken, amount, inviteToken)
      ActionMailer::Base.deliveries.should be_empty
    end
    it "returns the user error" do
      response = UserRegistration.new(invalid_joe).register_new_user(stripeToken, amount, inviteToken)
      expect(response).to eq(["Email can't be blank"])
    end
    it "does not try to charge the credit card" do
      StripeWrapper::Charge.should_not_receive(:create)
      UserRegistration.new(invalid_joe).register_new_user(stripeToken, amount, inviteToken)
    end
  end
end
